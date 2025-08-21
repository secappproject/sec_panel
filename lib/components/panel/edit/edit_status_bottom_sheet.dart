// lib/pages/edit_status_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/approles.dart';
import 'package:secpanel/models/paneldisplaydata.dart';
import 'package:secpanel/models/panels.dart';
import 'package:secpanel/models/company.dart';
import 'package:secpanel/theme/colors.dart';

class EditStatusBottomSheet extends StatefulWidget {
  final String? panelVendorName;
  final String busbarVendorNames;
  final String duration;
  final DateTime? startDate;
  final double progress;
  final PanelDisplayData panelData;
  final Company currentCompany;
  final VoidCallback onSave;

  const EditStatusBottomSheet({
    super.key,
    this.panelVendorName,
    required this.busbarVendorNames,
    required this.panelData,
    required this.startDate,
    required this.progress,
    required this.duration,
    required this.currentCompany,
    required this.onSave,
  });

  @override
  State<EditStatusBottomSheet> createState() => _EditStatusBottomSheetState();
}

class _EditStatusBottomSheetState extends State<EditStatusBottomSheet> {
  late String? _selectedPccStatus;
  late String? _selectedMccStatus;
  late String? _selectedComponentStatus;
  late final TextEditingController _remarkController;
  bool _isLoading = false;

  late DateTime? _aoBusbarPcc;
  late DateTime? _aoBusbarMcc;

  bool get _isK5 => widget.currentCompany.role == AppRole.k5;
  bool get _isWHS => widget.currentCompany.role == AppRole.warehouse;

  final List<String> _busbarStatusOptions = [
    "On Progress",
    "Siap 100%",
    "Close",
    "Red Block",
  ];
  final List<String> _componentStatusOptions = ["Open", "On Progress", "Done"];

  @override
  void initState() {
    super.initState();

    // [PERUBAHAN] Cari remark milik vendor saat ini dari daftar remarks
    String currentVendorRemark = '';
    try {
      final remarkData = widget.panelData.busbarRemarks.firstWhere(
        (remark) => remark.vendorId == widget.currentCompany.id,
      );
      currentVendorRemark = remarkData.remark ?? '';
    } catch (e) {
      // It's okay if no remark is found, just leave it blank.
      // print("No existing remark found for vendor ${widget.currentCompany.id}: $e");
    }

    _remarkController = TextEditingController(text: currentVendorRemark);

    final panel = widget.panelData.panel;

    if (_isK5) {
      _selectedPccStatus = panel.statusBusbarPcc ?? "On Progress";
      _selectedMccStatus = panel.statusBusbarMcc ?? "On Progress";
      _aoBusbarPcc = panel.aoBusbarPcc;
      _aoBusbarMcc = panel.aoBusbarMcc;
    } else if (_isWHS) {
      _selectedComponentStatus = panel.statusComponent ?? "Open";
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      final panelToUpdate = await DatabaseHelper.instance.getPanelByNoPp(
        widget.panelData.panel.noPp,
      );
      if (panelToUpdate != null) {
        if (_isK5) {
          panelToUpdate.statusBusbarPcc = _selectedPccStatus;
          panelToUpdate.statusBusbarMcc = _selectedMccStatus;
          panelToUpdate.aoBusbarPcc = _aoBusbarPcc;
          panelToUpdate.aoBusbarMcc = _aoBusbarMcc;

          String? aoBusbarMcc = _aoBusbarMcc?.toIso8601String() ?? '';
          String? aoBusbarPcc = _aoBusbarPcc?.toIso8601String() ?? '';

          await DatabaseHelper.instance.upsertStatusAOK5(
            panelNoPp: widget.panelData.panel.noPp,
            vendorId: widget.currentCompany.id,
            aoBusbarPcc: aoBusbarPcc,
            aoBusbarMcc: aoBusbarMcc,
            statusBusbarPcc: _selectedPccStatus ?? '',
            statusBusbarMcc: _selectedMccStatus ?? '',
          );

          // Remark yang diisi oleh user K5 saat ini akan disimpan untuk vendornya sendiri
          await DatabaseHelper.instance.upsertBusbarRemarkandVendor(
            panelNoPp: widget.panelData.panel.noPp,
            vendorId: widget.currentCompany.id,
            newRemark: _remarkController.text,
          );
        } else if (_isWHS) {
          panelToUpdate.statusComponent = _selectedComponentStatus;
          await DatabaseHelper.instance.upsertStatusWHS(
            panelNoPp: widget.panelData.panel.noPp,
            vendorId: widget.currentCompany.id,
            statusComponent: _selectedComponentStatus ?? '',
          );
        }
      }
      if (mounted) {
        widget.onSave();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menyimpan: ${e.toString()}"),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getBusbarStatusImage(String status) {
    final lower = status.toLowerCase();
    if (lower == '' || lower.contains('on progress')) {
      return 'assets/images/new-yellow.png';
    } else if (lower.contains('close')) {
      return 'assets/images/done-green.png';
    } else if (lower.contains('siap 100%')) {
      return 'assets/images/done-blue.png';
    } else if (lower.contains('red block')) {
      return 'assets/images/on-block-red.png';
    }
    return 'assets/images/no-status-gray.png';
  }

  String _getComponentStatusImage(String status) {
    final lower = status.toLowerCase();
    if (lower == '' || lower.contains('open')) {
      return 'assets/images/no-status-gray.png';
    } else if (lower.contains('done')) {
      return 'assets/images/done-green.png';
    } else if (lower.contains('on progress')) {
      return 'assets/images/on-progress-blue.png';
    }
    return 'assets/images/no-status-gray.png';
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.5) return AppColors.red;
    if (progress < 1.0) return AppColors.orange;
    return AppColors.schneiderGreen;
  }

  String _getProgressImage(double progress) {
    if (progress < 0.5) return 'assets/images/progress-bolt-red.png';
    if (progress < 1.0) return 'assets/images/progress-bolt-orange.png';
    return 'assets/images/progress-bolt-green.png';
  }

  @override
  Widget build(BuildContext context) {
    final bool isFuture =
        widget.startDate != null && widget.startDate!.isAfter(DateTime.now());
    final String durationLabel = isFuture ? "Mulai Dalam" : "Durasi Proses";
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 16,
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
          _buildStatusCard(durationLabel),
          if (_isK5) ...[const SizedBox(height: 16), _buildRemarkField()],
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }
  // Salin dan ganti seluruh method _buildStatusCard() di edit_status_bottom_sheet.dart

  Widget _buildStatusCard(String durationLabel) {
    final panel = widget.panelData.panel;
    final progress = (panel.percentProgress ?? 0) / 100.0;

    final bool isTemporary = panel.noPp.startsWith('TEMP_PP_');
    final String displayDuration = isTemporary
        ? "Belum Diatur"
        : (widget.startDate == null ? "Belum Diatur" : widget.duration);
    final String displayPanelTitle = isTemporary
        ? "Belum Diatur"
        : (panel.noPanel ?? "Tanpa No. Panel");

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(width: 1, color: AppColors.grayLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(_getProgressImage(progress), height: 28),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: AppColors.grayNeutral,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayDuration,
                            style: const TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            durationLabel,
                            style: const TextStyle(
                              color: AppColors.gray,
                              fontWeight: FontWeight.w400,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Panel",
                          style: TextStyle(
                            color: AppColors.gray,
                            fontWeight: FontWeight.w400,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.grayLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.panelVendorName ?? "No Vendor",
                            style: const TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.w400,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width - 280,
                          height: 11,
                          decoration: BoxDecoration(
                            color: AppColors.gray.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getProgressColor(progress),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${(progress * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayPanelTitle,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildVendornameField(),
                const SizedBox(height: 20),
                if (_isK5) ...[
                  _buildStatusOptionsList(
                    title: "Status Busbar PCC",
                    selectedValue: _selectedPccStatus,
                    onChanged: (newValue) {
                      setState(() => _selectedPccStatus = newValue);
                    },
                  ),
                  _buildAODatePicker(
                    "AO Busbar PCC",
                    _aoBusbarPcc,
                    (date) => setState(() => _aoBusbarPcc = date),
                  ),
                  const SizedBox(height: 20),
                  _buildStatusOptionsList(
                    title: "Status Busbar MCC",
                    selectedValue: _selectedMccStatus,
                    onChanged: (newValue) {
                      setState(() => _selectedMccStatus = newValue);
                    },
                  ),
                  _buildAODatePicker(
                    "AO Busbar MCC",
                    _aoBusbarMcc,
                    (date) => setState(() => _aoBusbarMcc = date),
                  ),
                ] else if (_isWHS) ...[
                  _buildStatusOptionsList(
                    title: "Status Picking Component",
                    selectedValue: _selectedComponentStatus,
                    onChanged: (newValue) {
                      setState(() => _selectedComponentStatus = newValue);
                    },
                  ),
                ],
                const Divider(height: 24, color: AppColors.grayLight),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "No. PP",
                      style: TextStyle(fontSize: 12, color: AppColors.gray),
                    ),
                    // [PERBAIKAN 1] Menambahkan 'style:'
                    Text(
                      isTemporary ? "" : panel.noPp,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "No. WBS",
                      style: TextStyle(fontSize: 12, color: AppColors.gray),
                    ),
                    // [PERBAIKAN 2] Menambahkan 'style:'
                    Text(
                      isTemporary ? "" : (panel.noWbs ?? ""),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Project",
                      style: TextStyle(fontSize: 12, color: AppColors.gray),
                    ),
                    // [PERBAIKAN 3] Menambahkan 'style:'
                    Text(
                      panel.project ?? "",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOptionsList({
    required String title,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    final options = _isK5 ? _busbarStatusOptions : _componentStatusOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...options.map(
          (status) => _buildStatusOptionRow(
            status: status,
            groupValue: selectedValue,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusOptionRow({
    required String status,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(status),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              Text(
                status,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 4),
              Image.asset(
                _isK5
                    ? _getBusbarStatusImage(status)
                    : _getComponentStatusImage(status),
                height: 12,
              ),
              const Spacer(),
              SizedBox(
                height: 24,
                width: 24,
                child: Radio<String>(
                  value: status,
                  groupValue: groupValue,
                  onChanged: (value) => onChanged(value),
                  activeColor: AppColors.schneiderGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAODatePicker(
    String label,
    DateTime? selectedDate,
    ValueChanged<DateTime> onDateChanged,
  ) {
    return _buildDatePicker(
      label,
      selectedDate,
      onDateChanged,
      Icons.assignment_turned_in_outlined,
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? selectedDate,
    ValueChanged<DateTime> onDateChanged,
    IconData icon,
  ) {
    Future<void> pickDate() async {
      final date = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.schneiderGreen,
                onPrimary: Colors.white,
                onSurface: AppColors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      if (date != null) {
        onDateChanged(date);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        InkWell(
          onTap: pickDate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grayLight),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.gray),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  selectedDate != null
                      ? DateFormat('d MMM yyyy').format(selectedDate)
                      : 'Pilih Tanggal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: selectedDate != null
                        ? AppColors.black
                        : AppColors.gray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Salin dan ganti seluruh method _buildVendornameField() di edit_status_bottom_sheet.dart
  Widget _buildVendornameField() {
    if (!_isK5) return const SizedBox.shrink();

    // Widget ini sekarang tidak lagi menggunakan TextFormField, melainkan Row
    // untuk menampilkan proses assignment (penugasan) vendor.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vendor Busbar",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.grayLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.busbarVendorNames.isEmpty
              // KONDISI 1: Belum ada vendor yang ditugaskan
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "No Vendor",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.gray,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.gray,
                      size: 16,
                    ),
                    Expanded(
                      child: Text(
                        widget.currentCompany.name, // Nama vendor K5 yg login
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.schneiderGreen,
                        ),
                      ),
                    ),
                  ],
                )
              // KONDISI 2: Sudah ada vendor yang ditugaskan
              : Text(
                  widget.busbarVendorNames,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRemarkField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Remark Anda", // Judul diubah agar lebih jelas
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _remarkController,
          cursorColor: AppColors.schneiderGreen,
          maxLines: 3,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
          decoration: InputDecoration(
            hintText: 'Masukkan remark untuk vendor Anda...',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grayLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.schneiderGreen),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
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
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : _saveChanges, // Disable tombol saat loading
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.schneiderGreen,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Simpan",
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
          ),
        ),
      ],
    );
  }
}
