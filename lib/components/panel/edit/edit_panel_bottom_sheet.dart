import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/approles.dart';
import 'package:secpanel/models/paneldisplaydata.dart';
import 'package:secpanel/models/panels.dart';
import 'package:secpanel/models/company.dart';
import 'package:secpanel/models/busbar.dart';
import 'package:secpanel/models/component.dart';
import 'package:secpanel/models/palet.dart';
import 'package:secpanel/models/corepart.dart';
import 'package:secpanel/theme/colors.dart';

class EditPanelBottomSheet extends StatefulWidget {
  final PanelDisplayData panelData;
  final Company currentCompany;
  final List<Company> k3Vendors;
  final Function(Panel) onSave;
  final VoidCallback onDelete;

  const EditPanelBottomSheet({
    super.key,
    required this.panelData,
    required this.currentCompany,
    required this.k3Vendors,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<EditPanelBottomSheet> createState() => _EditPanelBottomSheetState();
}

class _EditPanelBottomSheetState extends State<EditPanelBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _noPanelController;
  late final TextEditingController _noWbsController;
  late final TextEditingController _projectController;
  late final TextEditingController _noPpController;
  late final TextEditingController _progressController;
  late final TextEditingController _panelRemarkController;

  late String _originalNoPp;

  late Panel _panel;
  late DateTime? _selectedDate;
  late DateTime? _selectedTargetDeliveryDate;
  late String? _selectedK3VendorId;

  String? _selectedPanelType;
  final List<String> panelTypeOptions = const ["MCCF", "MCCW", "PCC"];

  late bool _isClosed;
  late DateTime? _closedDate;

  bool _canMarkAsSent = false;
  bool _isLoading = false;
  bool _isSuccess = false;

  bool get _isAdmin => widget.currentCompany.role == AppRole.admin;
  bool get _isK3 => widget.currentCompany.role == AppRole.k3;

  List<Company> _k5Vendors = [];
  List<Company> _whsVendors = [];

  List<String> _selectedBusbarVendorIds = [];

  String? _selectedComponentVendorId;
  String? _selectedPaletVendorId;
  String? _selectedCorepartVendorId;

  String? _selectedBusbarPccStatus;
  String? _selectedBusbarMccStatus;
  String? _selectedComponentStatus;
  String? _selectedPaletStatus;
  String? _selectedCorepartStatus;

  DateTime? _aoBusbarPcc;
  DateTime? _aoBusbarMcc;

  final List<String> busbarStatusOptions = [
    "On Progress",
    "Siap 100%",
    "Close",
    "Red Block",
  ];
  final List<String> componentStatusOptions = ["Open", "On Progress", "Done"];
  final List<String> paletCorepartStatusOptions = ["Open", "Close"];

  @override
  void initState() {
    super.initState();
    _panel = Panel.fromMap(widget.panelData.panel.toMap());
    _originalNoPp = _panel.noPp;

    _noPanelController = TextEditingController(text: _panel.noPanel);
    _noWbsController = TextEditingController(text: _panel.noWbs);
    _projectController = TextEditingController(text: _panel.project);
    _panelRemarkController = TextEditingController(text: _panel.remarks);

    _noPpController = TextEditingController(
      text: _panel.noPp.startsWith('TEMP_PP_') ? '' : _panel.noPp,
    );
    _progressController = TextEditingController(
      text: _panel.percentProgress?.toInt().toString() ?? '0',
    );
    _selectedDate = _panel.startDate;
    _selectedTargetDeliveryDate = _panel.targetDelivery;
    _selectedK3VendorId = _panel.vendorId;
    _selectedPanelType = _panel.panelType;

    _isClosed = _panel.isClosed;
    _closedDate = _panel.closedDate;

    _selectedBusbarVendorIds = List<String>.from(
      widget.panelData.busbarVendorIds,
    );

    _selectedBusbarPccStatus = _panel.statusBusbarPcc;
    _selectedBusbarMccStatus = _panel.statusBusbarMcc;
    _selectedComponentStatus = _panel.statusComponent;
    _selectedPaletStatus = _panel.statusPalet;
    _selectedCorepartStatus = _panel.statusCorepart;

    _aoBusbarPcc = _panel.aoBusbarPcc;
    _aoBusbarMcc = _panel.aoBusbarMcc;

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCanMarkAsSent());
    _progressController.addListener(_updateCanMarkAsSent);

    _loadVendors();
  }

  Future<void> _loadVendors() async {
    final k5 = await DatabaseHelper.instance.getK5Vendors();
    final whs = await DatabaseHelper.instance.getWHSVendors();
    if (mounted) {
      setState(() {
        _k5Vendors = k5;
        _whsVendors = whs;

        _selectedComponentVendorId =
            widget.panelData.componentVendorIds.isNotEmpty
            ? widget.panelData.componentVendorIds.first
            : null;
        _selectedPaletVendorId = widget.panelData.paletVendorIds.isNotEmpty
            ? widget.panelData.paletVendorIds.first
            : null;
        _selectedCorepartVendorId =
            widget.panelData.corepartVendorIds.isNotEmpty
            ? widget.panelData.corepartVendorIds.first
            : null;
      });
    }
  }

  @override
  void dispose() {
    _noPanelController.dispose();
    _noWbsController.dispose();
    _projectController.dispose();
    _noPpController.dispose();
    _progressController.removeListener(_updateCanMarkAsSent);
    _progressController.dispose();
    _panelRemarkController.dispose();
    super.dispose();
  }

  void _updateCanMarkAsSent() {
    final progress = int.tryParse(_progressController.text) ?? 0;
    final paletReady = _selectedPaletStatus == 'Close';
    final corepartReady = _selectedCorepartStatus == 'Close';
    final busbarMccReady = _selectedBusbarMccStatus == 'Close';

    bool allConditionsMet;
    switch (_selectedPanelType) {
      case 'MCCW':
        allConditionsMet =
            progress == 100 && paletReady && corepartReady && busbarMccReady;
        break;
      case 'PCC':
      case 'MCCF':
        allConditionsMet = progress == 100 && paletReady;
        break;
      default:
        allConditionsMet = false;
    }

    if (mounted && _canMarkAsSent != allConditionsMet) {
      setState(() {
        _canMarkAsSent = allConditionsMet;
        if (!_canMarkAsSent) {
          _isClosed = false;
          _closedDate = null;
        }
      });
    }
  }

  Future<void> _handleClosePanelToggle(bool isClosing) async {
    if (isClosing) {
      final selectedDate = await showDialog<DateTime>(
        context: context,
        builder: (BuildContext context) {
          return _CloseConfirmationDialog(
            initialDate: _closedDate ?? DateTime.now(),
          );
        },
      );

      if (selectedDate == null) return;

      setState(() {
        _isClosed = true;
        _closedDate = selectedDate;
      });
    } else {
      setState(() {
        _isClosed = false;
        _closedDate = null;
      });
    }
  }
  // edit_panel_bottom_sheet.dart

  Future<void> _saveChanges() async {
    if (_isLoading || _isSuccess) return;

    setState(() => _isLoading = true);

    try {
      // 1. Siapkan objek panel dengan semua data dari form
      final panelToSave = Panel.fromMap(_panel.toMap());
      panelToSave.noPanel = _noPanelController.text.trim();
      panelToSave.noWbs = _noWbsController.text.trim();
      panelToSave.project = _projectController.text.trim();
      panelToSave.noPp = _noPpController.text.trim();
      panelToSave.remarks = _panelRemarkController.text.trim();

      panelToSave.percentProgress =
          double.tryParse(_progressController.text.trim()) ?? 0.0;
      panelToSave.startDate = _selectedDate;
      panelToSave.targetDelivery = _selectedTargetDeliveryDate;
      panelToSave.vendorId = _selectedK3VendorId;
      panelToSave.panelType = _selectedPanelType;
      panelToSave.isClosed = _isClosed;
      panelToSave.closedDate = _closedDate;
      panelToSave.statusBusbarPcc = _selectedBusbarPccStatus;
      panelToSave.statusBusbarMcc = _selectedBusbarMccStatus;
      panelToSave.statusComponent = _selectedComponentStatus;
      panelToSave.statusPalet = _selectedPaletStatus;
      panelToSave.statusCorepart = _selectedCorepartStatus;
      panelToSave.aoBusbarPcc = _aoBusbarPcc;
      panelToSave.aoBusbarMcc = _aoBusbarMcc;

      // 2. Panggil API dan TANGKAP HASILNYA
      final Panel finalPanel = await DatabaseHelper.instance.changePanelNoPp(
        _originalNoPp,
        panelToSave,
      );

      // 3. Urus relasi Busbar secara terpisah menggunakan no_pp yang BENAR
      final oldVendorIds = Set<String>.from(widget.panelData.busbarVendorIds);
      final newVendorIds = Set<String>.from(_selectedBusbarVendorIds);

      final vendorsToDelete = oldVendorIds.difference(newVendorIds);
      for (final vendorId in vendorsToDelete) {
        await DatabaseHelper.instance.deleteBusbar(finalPanel.noPp, vendorId);
      }

      final vendorsToAdd = newVendorIds.difference(oldVendorIds);
      for (final vendorId in vendorsToAdd) {
        // Saat menambah, gunakan No. PP BARU dari `finalPanel`
        await DatabaseHelper.instance.upsertBusbar(
          Busbar(panelNoPp: finalPanel.noPp, vendor: vendorId),
        );
      }
      // 4. Urus relasi Palet & Corepart dengan memeriksa perubahan vendor K3
      final oldK3VendorId = widget.panelData.paletVendorIds.isNotEmpty
          ? widget.panelData.paletVendorIds.first
          : null;
      final newK3VendorId = _selectedK3VendorId;

      // Cek apakah vendor K3 berubah
      if (oldK3VendorId != newK3VendorId) {
        // Jika vendor lama ada, hapus relasi lamanya
        if (oldK3VendorId != null && oldK3VendorId.isNotEmpty) {
          await DatabaseHelper.instance.deletePalet(
            finalPanel.noPp,
            oldK3VendorId,
          );
          await DatabaseHelper.instance.deleteCorepart(
            finalPanel.noPp,
            oldK3VendorId,
          );
        }

        // Jika vendor baru dipilih, tambahkan relasi baru
        if (newK3VendorId != null && newK3VendorId.isNotEmpty) {
          // Tambah relasi baru menggunakan No. PP BARU (finalPanel.noPp)
          await DatabaseHelper.instance.upsertPalet(
            Palet(panelNoPp: finalPanel.noPp, vendor: newK3VendorId),
          );
          await DatabaseHelper.instance.upsertCorepart(
            Corepart(panelNoPp: finalPanel.noPp, vendor: newK3VendorId),
          );
        }
      }

      // 5. Urus relasi Component (ini sepertinya statis ke 'warehouse', jadi aman)
      await DatabaseHelper.instance.upsertComponent(
        Component(panelNoPp: finalPanel.noPp, vendor: 'warehouse'),
      );

      await DatabaseHelper.instance.upsertComponent(
        Component(panelNoPp: finalPanel.noPp, vendor: 'warehouse'),
      );

      // 5. Update UI
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        widget.onSave(
          finalPanel,
        ); // Kembalikan panel final yang datanya paling update
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showModalBottomSheet(
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
              const Text(
                'Hapus Panel?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Anda yakin ingin menghapus panel "${_panel.noPanel}"? Tindakan ini tidak dapat dibatalkan.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.gray),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(innerContext),
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
                      onPressed: () {
                        Navigator.pop(innerContext);
                        widget.onDelete();
                      },
                      style: ElevatedButton.styleFrom(
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
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Form(
            key: _formKey,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Edit Panel ${_panel.noPanel ?? ''}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_isAdmin)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.red,
                        ),
                        onPressed: _showDeleteConfirmation,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grayLight, width: 1),
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Panel"),
                      _buildPanelTypeSelector(),
                      const SizedBox(height: 16),
                      if (_isAdmin || _isK3) ...[
                        _buildMarkAsSent(),
                        if (_isClosed && _closedDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Ditutup pada: ${DateFormat('dd MMMM yyyy').format(_closedDate!)}',
                              style: const TextStyle(
                                color: AppColors.gray,
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                      _buildTextField(
                        controller: _noPanelController,
                        label: "No. Panel",
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _noWbsController,
                        label: "No. WBS",
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _projectController,
                        label: "Project",
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _noPpController,
                        label: "No. PP",
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return 'No. PP tidak boleh kosong';
                        //   }
                        //   return null;
                        // },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildTextField(
                              controller: _progressController,
                              label: "Progress",
                              isNumber: true,
                              suffixText: "%",
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '0-100';
                                }
                                final progress = int.tryParse(value);
                                if (progress == null ||
                                    progress < 0 ||
                                    progress > 100) {
                                  return '0-100';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _buildDateTimePicker()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTargetDeliveryPicker(),
                      const SizedBox(height: 16),
                      if (_isAdmin)
                        _buildAdminVendorPicker()
                      else if (_isK3) ...[
                        // <-- TAMBAHKAN BLOK INI
                        _buildK3VendorDisplay(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _panelRemarkController,
                          label: "Panel Remark",
                          maxLines: 3,
                        ),
                      ],
                    ],
                  ),
                ),
                if (_isAdmin) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grayLight, width: 1),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("Busbar"),
                        _buildMultiSelectorBusbarVendor(),
                        const SizedBox(height: 16),
                        _buildSelectorSection(
                          label: "Status Busbar PCC",
                          options: Map.fromEntries(
                            busbarStatusOptions.map((s) => MapEntry(s, s)),
                          ),
                          selectedValue: _selectedBusbarPccStatus,
                          onTap: (val) => setState(() {
                            _selectedBusbarPccStatus = val;
                            _updateCanMarkAsSent();
                          }),
                          isEnabled: _selectedBusbarVendorIds.isNotEmpty,
                        ),
                        const SizedBox(height: 16),
                        _buildDatePickerField(
                          label: "Acknowledgement Order PCC",
                          selectedDate: _aoBusbarPcc,
                          onDateChanged: (date) =>
                              setState(() => _aoBusbarPcc = date),
                          icon: Icons.assignment_turned_in_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildSelectorSection(
                          label: "Status Busbar MCC",
                          options: Map.fromEntries(
                            busbarStatusOptions.map((s) => MapEntry(s, s)),
                          ),
                          selectedValue: _selectedBusbarMccStatus,
                          onTap: (val) => setState(() {
                            _selectedBusbarMccStatus = val;
                            _updateCanMarkAsSent();
                          }),
                          isEnabled: _selectedBusbarVendorIds.isNotEmpty,
                        ),
                        const SizedBox(height: 16),
                        _buildDatePickerField(
                          label: "Acknowledgement Order MCC",
                          selectedDate: _aoBusbarMcc,
                          onDateChanged: (date) =>
                              setState(() => _aoBusbarMcc = date),
                          icon: Icons.assignment_turned_in_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grayLight, width: 1),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("Komponen"),
                        _buildSelectorSection(
                          label: "Status Komponen",
                          options: Map.fromEntries(
                            componentStatusOptions.map((s) => MapEntry(s, s)),
                          ),
                          selectedValue: _selectedComponentStatus,
                          onTap: (val) => setState(() {
                            _selectedComponentStatus = val;
                            _updateCanMarkAsSent();
                          }),
                          isEnabled: _selectedComponentVendorId != null,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grayLight, width: 1),
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Palet"),
                      _buildSelectorSection(
                        label: "Status Palet",
                        options: Map.fromEntries(
                          paletCorepartStatusOptions.map((s) => MapEntry(s, s)),
                        ),
                        selectedValue: _selectedPaletStatus,
                        onTap: (val) => setState(() {
                          _selectedPaletStatus = val;
                          _updateCanMarkAsSent();
                        }),
                        isEnabled: _selectedK3VendorId != null,
                      ),
                      if (_selectedK3VendorId == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Atur vendor panel terlebih dahulu",
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grayLight, width: 1),
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Corepart"),
                      _buildSelectorSection(
                        label: "Status Corepart",
                        options: Map.fromEntries(
                          paletCorepartStatusOptions.map((s) => MapEntry(s, s)),
                        ),
                        selectedValue: _selectedCorepartStatus,
                        onTap: (val) => setState(() {
                          _selectedCorepartStatus = val;
                          _updateCanMarkAsSent();
                        }),
                        isEnabled: _selectedK3VendorId != null,
                      ),
                      if (_selectedK3VendorId == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Atur vendor panel terlebih dahulu",
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGET BUILDERS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.black,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isNumber = false,
    String? suffixText,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 8),
        TextFormField(
          cursorColor: AppColors.schneiderGreen,
          controller: controller,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: validator,
          decoration: InputDecoration(
            suffixText: suffixText,
            hintText: 'Masukkan $label',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grayLight),
            ),
            enabledBorder: OutlineInputBorder(
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

  Widget _buildPanelTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tipe Panel",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: panelTypeOptions.map((type) {
            return _buildOptionButton(
              label: type,
              selected: _selectedPanelType == type,
              onTap: () {
                setState(() {
                  _selectedPanelType = type;
                });
                _updateCanMarkAsSent();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSelectorSection({
    required String label,
    required Map<String, String> options,
    required String? selectedValue,
    required ValueChanged<String?> onTap,
    bool isEnabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isEnabled ? AppColors.black : AppColors.gray,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: options.entries.map((entry) {
            return _buildOptionButton(
              label: entry.value,
              selected: selectedValue == entry.key,
              onTap: isEnabled ? () => onTap(entry.key) : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMultiSelectorBusbarVendor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vendor Busbar (K5)",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: _k5Vendors.map((vendor) {
            final bool isSelected = _selectedBusbarVendorIds.contains(
              vendor.id,
            );
            return _buildOptionButton(
              label: vendor.name,
              selected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedBusbarVendorIds.remove(vendor.id);
                  } else {
                    _selectedBusbarVendorIds.add(vendor.id);
                  }
                  _updateCanMarkAsSent();
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMarkAsSent() {
    final Color textColor = (_isAdmin || _isK3)
        ? AppColors.black
        : AppColors.gray;

    String subtitleText;
    switch (_selectedPanelType) {
      case 'MCCW':
        subtitleText =
            "Syarat: Progres 100%, Palet, Corepart & Busbar MCC Close.";
        break;
      case 'PCC':
      case 'MCCF':
        subtitleText = "Syarat: Progres 100% & Palet Close.";
        break;
      default:
        subtitleText = "Pilih tipe panel terlebih dahulu.";
    }

    return Column(
      children: [
        CheckboxListTile(
          title: Text(
            "Tandai Sudah Dikirim",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          subtitle: Text(
            subtitleText,
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.w300,
            ),
          ),
          value: _isClosed,
          onChanged: _selectedPanelType != null && _canMarkAsSent
              ? (bool? value) => _handleClosePanelToggle(value ?? false)
              : null,
          activeColor: AppColors.schneiderGreen,
          controlAffinity: ListTileControlAffinity.trailing,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    Future<void> pickDateTime() async {
      final now = DateTime.now();
      final initialPickerDate = _selectedDate ?? now;

      final date = await showDatePicker(
        context: context,
        initialDate: initialPickerDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
        builder: (context, child) => Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.schneiderGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        ),
      );
      if (date == null) return;

      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialPickerDate),
      );
      if (time == null) return;

      setState(
        () => _selectedDate = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Waktu Mulai Pengerjaan",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: pickDateTime,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grayLight),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppColors.gray,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedDate != null
                      ? DateFormat('d MMM yyyy HH:mm').format(_selectedDate!)
                      : 'Pilih Tanggal & Waktu',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: _selectedDate != null
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

  Widget _buildTargetDeliveryPicker() {
    return _buildDatePickerField(
      label: 'Target Delivery',
      selectedDate: _selectedTargetDeliveryDate,
      onDateChanged: (date) =>
          setState(() => _selectedTargetDeliveryDate = date),
      icon: Icons.flag_outlined,
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onDateChanged,
    required IconData icon,
  }) {
    Future<void> pickDate() async {
      final date = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
        builder: (context, child) => Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.schneiderGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        ),
      );
      if (date != null) onDateChanged(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: pickDate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grayLight),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.gray),
                const SizedBox(width: 8),
                Text(
                  selectedDate != null
                      ? DateFormat('d MMM yyyy').format(selectedDate)
                      : 'Pilih Tanggal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
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

  Widget _buildAdminVendorPicker() {
    return _buildSelectorSection(
      label: "Vendor Panel (K3)",
      options: Map.fromEntries(
        widget.k3Vendors.map((v) => MapEntry(v.id, v.name)),
      ),
      selectedValue: _selectedK3VendorId,
      onTap: (val) => setState(() => _selectedK3VendorId = val),
    );
  }

  Widget _buildK3VendorDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vendor Panel",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.grayLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.grayLight),
          ),
          child: Text(
            widget.currentCompany.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              color: AppColors.gray,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final Color borderColor = selected
        ? AppColors.schneiderGreen
        : AppColors.grayLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.schneiderGreen.withOpacity(0.08)
              : (onTap != null ? Colors.white : Colors.grey.shade100),
          border: Border.all(
            color: onTap != null ? borderColor : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: onTap != null ? AppColors.black : AppColors.gray,
          ),
        ),
      ),
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
              style: TextStyle(color: AppColors.schneiderGreen, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveChanges,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _isSuccess
                  ? Colors.green
                  : AppColors.schneiderGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : _isSuccess
                ? const Icon(Icons.check, size: 16)
                : const Text("Simpan", style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }
}

class _CloseConfirmationDialog extends StatefulWidget {
  final DateTime initialDate;

  const _CloseConfirmationDialog({required this.initialDate});

  @override
  State<_CloseConfirmationDialog> createState() =>
      _CloseConfirmationDialogState();
}

class _CloseConfirmationDialogState extends State<_CloseConfirmationDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.schneiderGreen,
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Konfirmasi Tutup Panel'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pilih tanggal penutupan panel:'),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                  const Icon(
                    Icons.calendar_today,
                    color: AppColors.schneiderGreen,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Batal', style: TextStyle(color: AppColors.gray)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.schneiderGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Simpan'),
          onPressed: () {
            Navigator.of(context).pop(_selectedDate);
          },
        ),
      ],
    );
  }
}
