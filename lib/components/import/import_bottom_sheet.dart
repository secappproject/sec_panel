import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secpanel/components/import/import_review_screen.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/theme/colors.dart';

class ImportBottomSheet extends StatefulWidget {
  final VoidCallback onImportSuccess;

  const ImportBottomSheet({super.key, required this.onImportSuccess});

  @override
  State<ImportBottomSheet> createState() => _ImportBottomSheetState();
}

class _ImportBottomSheetState extends State<ImportBottomSheet> {
  bool _isProcessing = false;
  String _statusText = "Ketuk untuk memilih file";

  String _selectedTemplateType = 'panels_and_relations';
  String _selectedTemplateFormat = 'xlsx';
  bool _isDownloading = false;
  String _importMode = 'new'; // Nilai: 'new', 'replace', 'wiring_replace'
  String? _selectedFileName;
  bool _isFileSelected = false;
  String _selectedMode = "panel_import";

  // ========================= DOWNLOAD TEMPLATE =========================

  Future<void> _downloadTemplate() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final templateFile = await DatabaseHelper.instance.generateImportTemplate(
        dataType: _selectedTemplateType,
        format: _selectedTemplateFormat,
      );

      final String? selectedDirectory = await FilePicker.platform
          .getDirectoryPath(
            dialogTitle: 'Pilih folder untuk menyimpan template',
          );

      if (selectedDirectory != null) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final fileName =
            'template_import_${_selectedTemplateType}_$timestamp.${templateFile.extension}';
        final filePath = '$selectedDirectory/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(templateFile.bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template berhasil disimpan.'),
              backgroundColor: AppColors.schneiderGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengunduh template: $e"),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // ========================= PICK FILE =========================

  Future<void> _pickAndProcessFile() async {
    if (_isProcessing) return;
    if (mounted) {
      setState(() {
        _isProcessing = true;
        _statusText = "Membuka direktori...";
      });
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'xlsx'],
      );

      if (result != null) {
        final pickedFile = result.files.single;
        if (mounted) {
          setState(() {
            _selectedFileName = pickedFile.name;
            _isFileSelected = true;
            _statusText = "Memproses: ${pickedFile.name}";
          });
        }
        await Future.delayed(const Duration(milliseconds: 200));

        final bytes = kIsWeb
            ? pickedFile.bytes!
            : await File(pickedFile.path!).readAsBytes();

        Map<String, List<Map<String, dynamic>>> data;

        // ========================= MODE ROUTING =========================
        if (_importMode == "wiring_import") {
          data = _parseExcelWiring(bytes);
        } else if (_importMode == "panel_transfer") {
          data = _parseExcelPanelTransfer(bytes);
        } else {
          data = _parseExcel(bytes);
        }
        if (mounted) {
          Navigator.pop(context);

          final importFinished = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => ImportReviewScreen(
                initialData: data,
                isCustomTemplate: true,
                mode: _importMode, // Mengirim mode yang dipilih
              ),
            ),
          );

          if (importFinished == true) {
            widget.onImportSuccess();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _isFileSelected = false;
            _selectedFileName = null;
            _statusText = "Ketuk untuk memilih file";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memproses file: $e"),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _isProcessing = false;
          _isFileSelected = false;
          _selectedFileName = null;
          _statusText = "Ketuk untuk memilih file";
        });
      }
    }
  }

  // ========================= PARSE JSON =========================

  Map<String, List<Map<String, dynamic>>> _parseJson(Uint8List bytes) {
    final content = utf8.decode(bytes);
    final jsonData = json.decode(content) as Map<String, dynamic>;
    final result = <String, List<Map<String, dynamic>>>{};

    jsonData.forEach((key, value) {
      if (value is List) {
        result[key.toLowerCase()] = value.cast<Map<String, dynamic>>();
      }
    });

    return result;
  }

  // ========================= PARSE EXCEL =========================

  Map<String, List<Map<String, dynamic>>> _parseExcel(Uint8List bytes) {
    final excel = ex.Excel.decodeBytes(bytes);
    final result = <String, List<Map<String, dynamic>>>{};

    for (var tableName in excel.tables.keys) {
      final lowerName = tableName.toLowerCase().replaceAll(' ', '_');
      final sheet = excel.tables[tableName]!;

      if (sheet.maxRows <= 1) {
        result[lowerName] = [];
        continue;
      }

      // NORMALISASI HEADER
      final header = sheet.rows.first.map((cell) {
        final val = cell?.value?.toString().trim().toLowerCase() ?? '';
        return val
            .replaceAll(' ', '_')
            .replaceAll('(', '')
            .replaceAll(')', '')
            .replaceAll('-', '_');
      }).toList();

      final rows = <Map<String, dynamic>>[];

      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        final rowData = <String, dynamic>{};
        bool hasData = false;

        for (int j = 0; j < header.length; j++) {
          String key = header[j];
          if (key.isEmpty) continue;

          String finalKey = key;

          // SMART COLUMN MAPPING
          if (key.contains('pp')) {
            finalKey = 'no_pp';
          } else if (key == 'panel_no' ||
              key == 'panelno' ||
              key.contains('panel_no')) {
            finalKey = 'no_panel';
          } else if (key.contains('wbs')) {
            finalKey = 'no_wbs';
          } else if (key.contains('project')) {
            finalKey = 'project';
          } else if (key.contains('type') && key.contains('panel')) {
            finalKey = 'panel_type';
          } else if (key.contains('target') || key.contains('delivery')) {
            finalKey = 'target_delivery';
          } else if (key.contains('progress')) {
            finalKey = 'percent_progress';
          } else if (key.contains('panel') && key.contains('vendor')) {
            finalKey = 'vendor_id';
          } else if (key.contains('busbar') && key.contains('vendor')) {
            finalKey = 'busbar_vendor_id';
          } else if (key.contains('status') && key.contains('busbar')) {
            finalKey = 'status_busbar_pcc';
          } else if (key.contains('ao') && key.contains('busbar')) {
            finalKey = 'ao_busbar_pcc';
          }

          // AMBIL NILAI CELL
          var cellValue = (j < row.length) ? row[j]?.value : null;
          String cleanValue = "";

          if (cellValue != null) {
            cleanValue = cellValue.toString().trim();

            // hilangkan .0 dari angka excel
            if (cleanValue.endsWith('.0')) {
              cleanValue = cleanValue.substring(0, cleanValue.length - 2);
            }

            if (cleanValue.toLowerCase() == "null") {
              cleanValue = "";
            }
          }

          // RULE KHUSUS PP PANEL
          if (finalKey == 'no_pp' && cleanValue.isEmpty) {
            cleanValue = "Belum Diatur";
          }

          // MENCEGAH OVERWRITE KOLOM
          if (!rowData.containsKey(finalKey)) {
            rowData[finalKey] = cleanValue;
          }

          if (cleanValue.isNotEmpty) {
            hasData = true;
          }
        }

        if (hasData) {
          rows.add(rowData);
        }
      }

      result[lowerName] = rows;
    }

    return result;
  }

  // ========================= PARSE EXCEL WIRINGS =========================
  Map<String, List<Map<String, dynamic>>> _parseExcelWiring(Uint8List bytes) {
    final excel = ex.Excel.decodeBytes(bytes);
    final rows = <Map<String, dynamic>>[];
    String currentPP = "";
    String currentWBS = "";

    for (var tableName in excel.tables.keys) {
      final sheet = excel.tables[tableName]!;

      if (sheet.maxRows <= 1) continue;

      final header = sheet.rows.first.map((cell) {
        final val = cell?.value?.toString().trim().toLowerCase() ?? '';
        if (val == 'pp panel') return 'panel_no_pp';
        if (val == 'panel no') return 'no_panel';
        if (val == 'wbs') return 'no_wbs';
        if (val.contains('progress')) return 'progress';
        if (val.contains('target')) return 'target_delivery_wiring';
        if (val == 'supplier') return 'supplier';
        return '';
      }).toList();

      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        final dataMap = <String, dynamic>{};

        // 1. Inisialisasi variabel di setiap baris baru
        String currentPP = "";
        String currentWBS = "";

        for (int j = 0; j < header.length; j++) {
          final key = header[j];
          if (key.isEmpty) continue;

          final cellValue = (j < row.length) ? row[j]?.value : null;
          final val = cellValue?.toString().trim() ?? "";

          // 2. KRUSIAL: Isi nilai ke variabel pembanding agar filter bekerja
          if (key == 'panel_no_pp') {
            currentPP = val;
          }
          if (key == 'no_wbs') {
            currentWBS = val;
          }

          if (key == 'progress') {
            final numericVal =
                int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            dataMap[key] = numericVal;
          } else {
            dataMap[key] = val;
          }
        }

        // 3. FILTER: Hanya masukkan jika Panel No PP tidak kosong
        // Ini akan menghapus baris "hantu" yang membuat tombol simpan mati
        if (currentPP.isNotEmpty) {
          dataMap['is_wiring'] = true;
          dataMap['project'] = "WIRING UPDATE";
          rows.add(dataMap);
        }
      }
    }

    // final result = {'panel': rows, 'data': rows};
    final result = {'data': rows};
    return result;
  }

  Map<String, List<Map<String, dynamic>>> _parseExcelPanelTransfer(
    Uint8List bytes,
  ) {
    final excel = ex.Excel.decodeBytes(bytes);
    final rows = <Map<String, dynamic>>[];

    for (var tableName in excel.tables.keys) {
      final sheet = excel.tables[tableName]!;

      if (sheet.maxRows <= 1) continue;

      final header = sheet.rows.first.map((cell) {
        final val = cell?.value?.toString().trim().toLowerCase() ?? '';

        if (val == 'pp panel') return 'no_pp';
        if (val == 'panel no') return 'no_panel';
        if (val == 'wbs') return 'no_wbs';
        if (val.contains('target')) return 'target_delivery_wiring';
        if (val.contains('vendor')) return 'vendor';

        return '';
      }).toList();

      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];

        String noPP = "";
        String noPanel = "";
        String noWBS = "";
        String targetWiring = "";
        String vendor = "";

        for (int j = 0; j < header.length; j++) {
          final key = header[j];
          if (key.isEmpty) continue;

          final cellValue = (j < row.length) ? row[j]?.value : null;
          final val = cellValue?.toString().trim() ?? "";

          if (key == 'no_pp') noPP = val;
          if (key == 'no_panel') noPanel = val;
          if (key == 'no_wbs') noWBS = val;
          if (key == 'target_delivery_wiring') targetWiring = val;
          if (key == 'vendor') vendor = val;
        }

        // ================= FILTER FINAL =================
        if (noPP.isNotEmpty &&
            noPanel.isNotEmpty &&
            noWBS.isNotEmpty &&
            vendor.isNotEmpty) {
          rows.add({
            'no_pp': noPP,
            'no_panel': noPanel,
            'no_wbs': noWBS,
            'target_delivery_wiring': targetWiring,
            'vendor': vendor,
          });
        }
      }
    }

    return {'data': rows};
  }

  // ========================= UI COMPONENTS =========================

  Widget _buildImportModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Mode Upload",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildModeButton(
              title: "Mass Update / New Panel",
              value: "panel_import",
              icon: Icons.add_circle_outline,
            ),
            const SizedBox(width: 8),
            _buildModeButton(
              title: "Mass Update Wiring",
              value: "wiring_import",
              icon: Icons.electric_bolt,
            ),
            const SizedBox(width: 8),
            _buildModeButton(
              title: "Mass Transfer Panel",
              value: "panel_transfer",
              icon: Icons.sync_alt,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final bool isSelected = _importMode == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _importMode = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.schneiderGreen.withOpacity(0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.schneiderGreen
                  : AppColors.grayLight,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.schneiderGreen : AppColors.gray,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.schneiderGreen
                      : AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.grayLight,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity, // Memenuhi lebar layar
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.schneiderGreen, // Blok latar hijau
                borderRadius: BorderRadius.circular(
                  8,
                ), // Sudut melengkung halus
              ),
              child: const Text(
                "Upload Data",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Tulisan jadi putih agar kontras
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildImportModeSelector(),
            const SizedBox(height: 24),
            InkWell(
              onTap: _pickAndProcessFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: _isFileSelected
                      ? AppColors.schneiderGreen.withOpacity(0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isFileSelected
                        ? AppColors.schneiderGreen
                        : AppColors.grayLight,
                    width: 1.5,
                  ),
                ),
                child: _isProcessing
                    ? Column(
                        children: const [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.schneiderGreen,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text("Memproses file..."),
                        ],
                      )
                    : Column(
                        children: [
                          Icon(
                            _isFileSelected
                                ? Icons.check_circle
                                : Icons.upload_file,
                            size: 36,
                            color: _isFileSelected
                                ? AppColors.schneiderGreen
                                : AppColors.gray,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isFileSelected
                                ? "File siap diimpor"
                                : "Ketuk untuk memilih file",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (_selectedFileName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _selectedFileName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.gray,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Batal"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
