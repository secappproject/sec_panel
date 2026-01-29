import 'dart:convert';
import 'dart:io';
// Menggunakan hide TextSpan untuk menghindari konflik dengan Flutter Material
import 'package:excel/excel.dart' hide TextSpan;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:secpanel/components/import/import_review_screen.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/theme/colors.dart';

class ImportBottomSheet extends StatefulWidget {
  final VoidCallback onImportSuccess;

  const ImportBottomSheet({super.key, required this.onImportSuccess});

  @override
  State<ImportBottomSheet> createState() => _ImportBottomSheetState();
}

enum ImportMode { defaultMode, wbsMode }

class _ImportBottomSheetState extends State<ImportBottomSheet> {
  bool _isProcessing = false;
  String _statusText = "Ketuk untuk memilih file";
  ImportMode _selectedMode = ImportMode.defaultMode;

  Future<void> _pickAndProcessFile() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _statusText = "Membuka direktori...";
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'xlsx'],
      );
      if (result != null) {
        final pickedFile = result.files.single;
        setState(() => _statusText = "Memproses: ${pickedFile.name}");
        
        await Future.delayed(const Duration(milliseconds: 200));
        
        final bytes = kIsWeb
            ? pickedFile.bytes!
            : await File(pickedFile.path!).readAsBytes();

        final Map<String, List<Map<String, dynamic>>> data =
            pickedFile.extension == 'json'
            ? _parseJson(bytes)
            : _parseExcel(bytes);

        // --- LOGIKA AUTO GENERATE PP PANEL (no_pp) UNTUK WBS MODE ---
        if (_selectedMode == ImportMode.wbsMode && data.containsKey('panel')) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          for (int i = 0; i < data['panel']!.length; i++) {
            var row = data['panel']![i];
            
            // Cek apakah kolom PP Panel atau no_pp sudah ada
            bool hasNoPp = row.keys.any((k) {
              final clean = k.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
              return clean == 'pppanel' || clean == 'nopp';
            });

            // Jika tidak ada, FE membantu generate agar valid saat Review & di BE
            if (!hasNoPp) {
              row['PP Panel'] = 'TEMP_PP_${timestamp}_$i';
            }
          }
        }
        // ----------------------------------------------------------

        if (mounted) {
          Navigator.pop(context);
          final bool isCustom = _selectedMode == ImportMode.wbsMode;
          
          final importFinished = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ImportReviewScreen(initialData: data, isCustomTemplate: isCustom),
            ),
          );
          if (importFinished == true) {
            widget.onImportSuccess();
          }
        }
      } else {
        setState(() {
          _isProcessing = false;
          _statusText = "Ketuk untuk memilih file";
        });
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
          _statusText = "Ketuk untuk memilih file";
        });
      }
    }
  }

  // Parsing JSON & Excel tetap sama
  Map<String, List<Map<String, dynamic>>> _parseJson(Uint8List bytes) {
    final content = utf8.decode(bytes);
    final jsonData = json.decode(content) as Map<String, dynamic>;
    final Map<String, List<Map<String, dynamic>>> result = {};
    jsonData.forEach((key, value) {
      if (value is List) {
        result[key.toLowerCase()] = value.cast<Map<String, dynamic>>();
      }
    });
    return result;
  }

  // Cari method _parseExcel dan ganti bagian pengambilan header-nya
Map<String, List<Map<String, dynamic>>> _parseExcel(Uint8List bytes) {
  final excel = Excel.decodeBytes(bytes);
  final Map<String, List<Map<String, dynamic>>> result = {};

  // Fungsi Helper untuk menstandarkan nama kolom agar dibaca Backend Go
  String standardizeKey(String key) {
    final k = key.toLowerCase().trim().replaceAll(' ', '').replaceAll('_', '');
    if (k == 'nopanel' || k == 'panelno') return 'Panel No'; // Samakan dengan BE
    if (k == 'wbs' || k == 'nowbs') return 'WBS';
    if (k == 'project') return 'PROJECT';
    if (k == 'pppanel' || k == 'nopp') return 'PP Panel';
    if (k == 'targetdelivery') return 'Target Delivery';
    if (k == 'startassembly' || k == 'startdate') return 'Start Assembly';
    if (k == 'typepanel' || k == 'paneltype') return 'Type Panel';
    if (k == 'actualdelivery' || k == 'closeddate') return 'Actual Delivery ke SEC';
    return key; // Kembalikan asli jika tidak terdaftar
  }

  for (var tableName in excel.tables.keys) {
    final lowerCaseTableName = tableName.toLowerCase().replaceAll(' ', '_');
    final sheet = excel.tables[tableName]!;
    if (sheet.maxRows <= 1) {
      result[lowerCaseTableName] = [];
      continue;
    }

    // UBAH BARIS INI: Gunakan standardizeKey
    final List<String> header = sheet.rows.first
        .map((cell) => standardizeKey(cell?.value?.toString().trim() ?? ''))
        .toList();

    final List<Map<String, dynamic>> sheetRows = [];
    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.rows[i];
      final rowData = <String, dynamic>{};
      bool isRowCompletelyEmpty = true;
      for (int j = 0; j < header.length; j++) {
        final key = header[j];
        if (key.isNotEmpty) {
          final dynamic rawValue = (j < row.length) ? row[j]?.value : null;
          final String cellValueAsString = rawValue?.toString() ?? '';
          rowData[key] = cellValueAsString;
          if (cellValueAsString.trim().isNotEmpty) isRowCompletelyEmpty = false;
        }
      }
      if (!isRowCompletelyEmpty) sheetRows.add(rowData);
    }
    result[lowerCaseTableName] = sheetRows;
  }
  return result;
}

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4, width: 40,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AppColors.grayLight, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const Text("Upload Data", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text("Tentukan mode kolom file sebelum mengunggah.", style: TextStyle(fontSize: 13, color: AppColors.gray)),
          
          const SizedBox(height: 24),
          const Text("Pilih Mode Struktur File:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.gray)),
          const SizedBox(height: 12),
          
          Row(
            children: [
              _buildModeButton("Default", ImportMode.defaultMode),
              const SizedBox(width: 12),
              _buildModeButton("WBS, No Panel, Target Delivery", ImportMode.wbsMode),
            ],
          ),
          
          const SizedBox(height: 24),
          
          InkWell(
            onTap: _pickAndProcessFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: BoxBorder.all(color: AppColors.grayLight, width: 1.5),
                color: AppColors.white,
              ),
              child: _isProcessing
                  ? const Center(child: CircularProgressIndicator(color: AppColors.schneiderGreen))
                  : Column(
                      children: [
                        const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.schneiderGreen),
                        const SizedBox(height: 12),
                        Text(_statusText, style: const TextStyle(fontWeight: FontWeight.w400)),
                        const SizedBox(height: 4),
                        const Text(".xlsx atau .json", style: TextStyle(fontSize: 11, color: AppColors.gray)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoSection(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: AppColors.gray)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final bool isWbsMode = _selectedMode == ImportMode.wbsMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grayLight.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Kolom yang diperlukan (${isWbsMode ? 'WBS Mode' : 'Default Mode'}):",
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.black, fontFamily: 'Lexend'),
          ),
          const SizedBox(height: 8),
          _infoRow(
            Icons.check_circle_outline, 
            "Mandatory", 
            isWbsMode ? "WBS" : "No PP, No Panel, Project"
          ),
          const SizedBox(height: 8),
          _infoRow(
            Icons.add_circle_outline, 
            "Optional", 
            isWbsMode ? "No Panel, Target Delivery" : "No WBS, Start Date, Target Delivery, Vendor ID, Panel Type, Remarks"
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.grayLight),
          const SizedBox(height: 8),
          const Text(
            "*Sistem otomatis mengenali penulisan Spasi (Title Case) maupun Underscore (snake_case) untuk semua kolom di atas.",
            style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: AppColors.gray, fontFamily: 'Lexend'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String columns) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.gray),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 10, color: AppColors.gray, height: 1.4, fontFamily: 'Lexend'),
              children: [
                TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.black)),
                TextSpan(text: columns),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton(String label, ImportMode mode) {
    final bool isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.schneiderGreen.withOpacity(0.1) : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: BoxBorder.all(
              color: isSelected ? AppColors.schneiderGreen : AppColors.grayLight,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
              color: isSelected ? AppColors.schneiderGreen : AppColors.black,
            ),
          ),
        ),
      ),
    );
  }
}