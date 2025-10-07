// lib/components/export/export_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:secpanel/models/company.dart';
import 'package:secpanel/models/paneldisplaydata.dart'; // <-- Import yang mungkin dibutuhkan
import 'package:secpanel/theme/colors.dart';

class PreviewBottomSheet extends StatefulWidget {
  final Company currentUser;
  // [PERBAIKAN 1] Tambahkan variabel untuk menerima data terfilter
  final List<PanelDisplayData> filteredPanels;

  const PreviewBottomSheet({
    super.key,
    required this.currentUser,
    // [PERBAIKAN 2] Tambahkan parameter di constructor
    required this.filteredPanels,
  });

  @override
  State<PreviewBottomSheet> createState() => _PreviewBottomSheetState();
}

class _PreviewBottomSheetState extends State<PreviewBottomSheet> {
 bool _exportPanelData = true;
  bool _exportUserData = true;
  bool _exportIssueData = false; 
  bool _exportSrData = false;   
  String _selectedFormat = 'Excel';


  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Lexend',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Lexend',
                fontSize: 12,
                color: AppColors.gray,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(right: 8, bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.schneiderGreen.withOpacity(0.08)
              : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.schneiderGreen : AppColors.grayLight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? AppColors.schneiderGreen : AppColors.gray,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleSelectOption(String format) {
    final bool isSelected = _selectedFormat == format;
    return GestureDetector(
      onTap: () => setState(() => _selectedFormat = format),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(right: 8, bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.schneiderGreen.withOpacity(0.08)
              : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.schneiderGreen : AppColors.grayLight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          format,
          style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAnyDataSelected = _exportPanelData || _exportUserData || _exportIssueData || _exportSrData;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
          const SizedBox(height: 24),
          const Text(
            "Extract Data",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [PERBAIKAN 3] Tampilkan jumlah panel yang akan diekspor
                  _buildSectionTitle(
                    "Pilih Data untuk Di-extract",
                    subtitle:
                        "Berdasarkan filter yang sedang aktif di halaman utama.",
                  ),
                  Wrap(
                    children: [
                      _buildToggleOption(
                        label:
                            "Data Panel (${widget.filteredPanels.length} item)",
                        isSelected: _exportPanelData,
                        onTap: () => setState(
                          () => _exportPanelData = !_exportPanelData,
                        ),
                      ),
                      _buildToggleOption(
                        label: "Data User & Relasi",
                        isSelected: _exportUserData,
                        onTap: () =>
                            setState(() => _exportUserData = !_exportUserData),
                      ),
                      _buildToggleOption(
                        label: "Issue",
                        isSelected: _exportIssueData,
                        onTap: () =>
                            setState(() => _exportIssueData = !_exportIssueData),
                      ),
                      _buildToggleOption(
                        label: "Additional SR",
                        isSelected: _exportSrData,
                        onTap: () =>
                            setState(() => _exportSrData = !_exportSrData),
                      ),
                    ],
                  ),
                  _buildSectionTitle("Pilih Format File"),
                  Wrap(
                    children: ['Excel', 'JSON']
                        .map((format) => _buildSingleSelectOption(format))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.schneiderGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Batal',
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.schneiderGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.grayNeutral,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: !isAnyDataSelected
                      ? null
                      : () => Navigator.of(context).pop({
                          'exportPanel': _exportPanelData,
                          'exportUser': _exportUserData,
                          'exportIssue': _exportIssueData,
                          'exportSr': _exportSrData,
                          'format': _selectedFormat,
                        }),
                  child: const Text('Extract', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
