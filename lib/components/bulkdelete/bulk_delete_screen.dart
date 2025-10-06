// filename: lib/components/bulkdelete/bulk_delete_screen.dart
import 'package:flutter/material.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/paneldisplaydata.dart';
import 'package:secpanel/theme/colors.dart';

// Class untuk membawa hasil kembali ke halaman utama
class BulkDeleteResult {
  final bool success;
  final String message;
  final bool dataHasChanged;

  BulkDeleteResult({
    required this.success,
    required this.message,
    this.dataHasChanged = false,
  });
}


class BulkDeleteBottomSheet extends StatefulWidget {
  final List<PanelDisplayData> panelsToDisplay; 

  const BulkDeleteBottomSheet({
    super.key,
    required this.panelsToDisplay,
  });

  @override
  // Ganti State
  State<BulkDeleteBottomSheet> createState() => _BulkDeleteBottomSheetState();
}

class _BulkDeleteBottomSheetState extends State<BulkDeleteBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = ''; 
  bool _isDeleting = false;
  final Set<String> _selectedPanelPks = {};
  bool _dataHasChanged = false;

  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

 List<PanelDisplayData> get _filteredAndSearchedPanels {
    final List<PanelDisplayData> baseList = widget.panelsToDisplay;

    if (_searchText.isEmpty) {
      return baseList;
    }

    final lowerCaseSearch = _searchText.toLowerCase();
    
    return baseList.where((data) {
      final panel = data.panel;
      return (panel.noPanel?.toLowerCase().contains(lowerCaseSearch) ?? false) ||
             (panel.noPp.toLowerCase().contains(lowerCaseSearch)) ||
             (panel.project?.toLowerCase().contains(lowerCaseSearch) ?? false) ||
             (data.panelVendorName.toLowerCase().contains(lowerCaseSearch));
    }).toList();
  }

  void _onSelectAll(bool? selected) {
    setState(() {
      final currentList = _filteredAndSearchedPanels; 
      if (selected == true) {
        _selectedPanelPks.addAll(currentList.map((p) => p.panel.noPp));
      } else {
        for (var panel in currentList) {
          _selectedPanelPks.remove(panel.panel.noPp);
        }
      }
    });
  }
  Future<bool> _showConfirmationBottomSheet({
    required String title,
    required String content,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext innerContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.grayLight,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.red,
                size: 50,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.gray),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(innerContext, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.schneiderGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        "Batal",
                        style: TextStyle(
                          color: AppColors.schneiderGreen,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(innerContext, true),
                      style: ElevatedButton.styleFrom(
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        "Ya, Hapus",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }
 Future<void> _deleteSinglePanel(String noPp, String? noPanel) async {
    final confirm = await _showConfirmationBottomSheet(
      title: 'Hapus Panel?',
      content:
          'Anda yakin ingin menghapus panel "$noPanel"? Tindakan ini tidak dapat dibatalkan.',
    );

    if (confirm && mounted) {
      try {
        await DatabaseHelper.instance.deletePanel(noPp);
        _dataHasChanged = true;
        
        // Hapus dari daftar terpilih dan perbarui UI lokal
        setState(() {
          _selectedPanelPks.remove(noPp);
          // Karena kita tidak memuat ulang data dari DB di sini,
          // user harus menutup sheet untuk melihat perubahan di HomeScreen.
          // Untuk menghilangkan panel dari tampilan BulkDelete, 
          // kita perlu mengubah cara BulkDeleteBottomSheet mendapatkan datanya.
          // Saat ini kita tidak akan menghapus secara lokal di sini, 
          // hanya memperbarui _selectedPanelPks dan mengandalkan refresh HomeScreen.
        });
        
        // Cukup tutup bottom sheet dengan pesan sukses
        if (mounted) {
            Navigator.of(context).pop(
                BulkDeleteResult(
                    success: true,
                    message: 'Panel "$noPanel" berhasil dihapus.',
                    dataHasChanged: _dataHasChanged,
                ),
            );
        }

      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(
            BulkDeleteResult(
              success: false,
              message: 'Gagal menghapus panel "$noPanel": $e',
              dataHasChanged: _dataHasChanged,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSelectedPanels() async {
    final List<String> panelsToDelete = _selectedPanelPks.toList();
    final count = panelsToDelete.length;
    final confirm = await _showConfirmationBottomSheet(
      title: 'Konfirmasi Hapus Massal',
      content:
          'Anda yakin ingin menghapus $count panel yang dipilih? Tindakan ini tidak dapat dibatalkan.',
    );

    if (confirm && mounted) {
      setState(() => _isDeleting = true);
      try {
        await DatabaseHelper.instance.deletePanels(panelsToDelete);

        Navigator.of(context).pop(
          BulkDeleteResult(
            success: true,
            message: '$count panel berhasil dihapus.',
            dataHasChanged: true,
          ),
        );
      } catch (e) {
        Navigator.of(context).pop(
          BulkDeleteResult(
            success: false,
            message: 'Gagal menghapus panel: $e',
            dataHasChanged: _dataHasChanged,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final panelsToDisplay = _filteredAndSearchedPanels; // Gunakan getter baru
    final isSelectionEmpty = _selectedPanelPks.isEmpty;
    final isListEmpty = panelsToDisplay.isEmpty;
    
    return PopScope(
      canPop: !_isDeleting,
      onPopInvoked: (didPop) {
        if (!didPop) return;
        // Kembalikan status dataHasChanged saat ditutup secara manual
        // Navigator.of(context).pop(
        //       BulkDeleteResult(
        //           success: true,
        //           message: '',
        //           dataHasChanged: _dataHasChanged,
        //       ),
        //   );
      },
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  Container(
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.grayLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Bulk Delete Panel',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    style: TextStyle(color: AppColors.black, fontSize: 12, fontWeight: FontWeight.w300),
                    controller: _searchController,
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.schneiderGreen, ), borderRadius: BorderRadius.all(Radius.circular(12))),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.grayLight, ), borderRadius: BorderRadius.all(Radius.circular(12))),
                      hintText: 'Cari No. Panel, No. PP, Project, atau Vendor...',
                      hintStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: AppColors.gray),
                      prefixIcon: const Icon(Icons.search, color: AppColors.gray),
                      suffixIcon: _searchText.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.gray, size: 12,),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchText = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.grayLight),
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchText = value),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: isListEmpty
                  ? const Center(
                      child: Text(
                        "Tidak ada data panel yang sesuai dengan filter atau pencarian.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.gray),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          checkboxTheme: CheckboxThemeData(
                            fillColor:
                                MaterialStateProperty.resolveWith<Color?>((
                                  Set<MaterialState> states,
                                ) {
                              if (states.contains(MaterialState.selected)) {
                                return AppColors.schneiderGreen;
                              }
                              return null;
                            }),
                            checkColor: MaterialStateProperty.all(Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            onSelectAll: panelsToDisplay.isEmpty || _isDeleting ? null : _onSelectAll, 
                            headingRowColor: MaterialStateProperty.all(
                              AppColors.white,
                            ),
                            columns: const [
                              DataColumn(label: Text('No. Panel', style: TextStyle(fontWeight: FontWeight.w300),)),
                              DataColumn(label: Text('No. PP', style: TextStyle(fontWeight: FontWeight.w300),)),
                              DataColumn(label: Text('Project', style: TextStyle(fontWeight: FontWeight.w300),)),
                              DataColumn(label: Text('Vendor Panel', style: TextStyle(fontWeight: FontWeight.w300),)),
                              DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.w300),)),
                            ],
                            rows: panelsToDisplay.map((data) {
                              final panel = data.panel;
                              final isSelected = _selectedPanelPks.contains(
                                panel.noPp,
                              );
                              return DataRow(
                                selected: isSelected,
                                onSelectChanged: _isDeleting
                                    ? null
                                    : (selected) {
                                        setState(() {
                                          if (selected == true) {
                                            _selectedPanelPks.add(panel.noPp);
                                          } else {
                                            _selectedPanelPks.remove(
                                              panel.noPp,
                                            );
                                          }
                                        });
                                      },
                                cells: [
                                  DataCell(Text(panel.noPanel ?? '-', style: TextStyle(fontWeight: FontWeight.w300),)),
                                  DataCell(
                                    Text(
                                      panel.noPp.startsWith("TEMP_PP_")
                                          ? ''
                                          : panel.noPp,
                                          style: TextStyle(fontWeight: FontWeight.w300),
                                    ),
                                  ),
                                  DataCell(Text(panel.project ?? '-',
                                          style: TextStyle(fontWeight: FontWeight.w300),)),
                                  DataCell(Text(data.panelVendorName,
                                          style: TextStyle(fontWeight: FontWeight.w300),)),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.red,
                                      ),
                                      onPressed: _isDeleting
                                          ? null
                                          : () => _deleteSinglePanel(
                                                panel.noPp,
                                                panel.noPanel,
                                              ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      // [PERBAIKAN] Tombol tutup sekarang mengirimkan hasil yang benar.
                      onPressed: _isDeleting
                          ? null
                          : () => Navigator.of(context).pop(
                                BulkDeleteResult(
                                  success:
                                      true, // Dianggap sukses karena tidak ada error
                                  message: '', // Tidak ada pesan
                                  dataHasChanged: _dataHasChanged,
                                ),
                              ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.schneiderGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        "Tutup",
                        style: TextStyle(
                          color: AppColors.schneiderGreen,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: _isDeleting
                          ? Container()
                          : const Icon(Icons.delete_forever_outlined),
                      label: _isDeleting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              'Hapus (${_selectedPanelPks.length})',
                              style: const TextStyle(fontSize: 12),
                            ),
                      onPressed: isSelectionEmpty || _isDeleting
                          ? null
                          : _deleteSelectedPanels,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.grayLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}