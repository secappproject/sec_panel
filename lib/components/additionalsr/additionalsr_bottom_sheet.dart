import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/additionalsr.dart';
import 'package:secpanel/models/approles.dart'; 
import 'package:secpanel/models/company.dart';
import 'package:secpanel/theme/colors.dart';

class AdditionalSrBottomSheet extends StatefulWidget {
  final Company currentCompany;
  final String poNumber;
  final String panelNoPp;
  final String panelTitle;

  const AdditionalSrBottomSheet({
    super.key,
    required this.currentCompany,
    required this.poNumber,
    required this.panelNoPp,
    required this.panelTitle,
  });

  @override
  State<AdditionalSrBottomSheet> createState() =>
      _AdditionalSrBottomSheetState();
}

class _AdditionalSrBottomSheetState extends State<AdditionalSrBottomSheet> {
  List<AdditionalSR> _srs = [];
  bool _isLoading = true;
  bool get _isViewer => widget.currentCompany.role == AppRole.viewer;

  @override
  void initState() {
    super.initState();
    _fetchSRs();
  }

  Future<void> _fetchSRs() async {
    setState(() => _isLoading = true);
    try {
      final srs =
          await DatabaseHelper.instance.getAdditionalSRs(widget.panelNoPp);
      if (mounted) {
        setState(() {
          _srs = srs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditSRDialog({AdditionalSR? sr}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddEditSRDialog(
        panelNoPp: widget.panelNoPp,
        poNumber: widget.poNumber,
        sr: sr,
        onSave: () {
          _fetchSRs();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Additional SR',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          widget.panelTitle,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.gray),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  (!_isViewer)
                      ? ElevatedButton.icon(
                          onPressed: () => _showEditSRDialog(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text(
                            'Tambah',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w400),
                          ),
                          style: ElevatedButton.styleFrom(
                            shadowColor: Colors.transparent,
                            backgroundColor: AppColors.schneiderGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                        )
                      : const SizedBox()
                ],
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _srs.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48.0),
                            child: Text(
                              'Belum ada Additional SR.',
                              style: TextStyle(
                                  color: AppColors.gray,
                                  fontWeight: FontWeight.w300),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchSRs,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount;
                              if (constraints.maxWidth >= 600) {
                                crossAxisCount = 3;
                              } else {
                                crossAxisCount = 2;
                              }

                              const double spacing = 12.0;
                              final double totalSpacing =
                                  (crossAxisCount - 1) * spacing;
                              final double itemWidth =
                                  (constraints.maxWidth - totalSpacing) /
                                      crossAxisCount;

                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: _srs.map((sr) {
                                  return SizedBox(
                                    width: itemWidth,
                                    child: _buildSRListItemCard(sr),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSRListItemCard(AdditionalSR sr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(width: 1, color: AppColors.grayLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sr.item,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoColumn('Qty', sr.quantity.toString()),
                      const SizedBox(height: 8),
                      _buildInfoColumn('No. PO', sr.poNumber.toString()),
                      const SizedBox(height: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status',
                              style: TextStyle(
                                color: AppColors.gray,
                                fontSize: 11,
                                fontWeight: FontWeight.w300,
                              )),
                          if (sr.status.toLowerCase() == "open") ...[
                            Row(
                              children: [
                                const Text('Open ',
                                    style: TextStyle(
                                      color: AppColors.black,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                    )),
                                Image.asset(
                                  "assets/images/on-progress-blue.png",
                                  height: 12,
                                ),
                              ],
                            )
                          ],
                          if (sr.status.toLowerCase() == "close") ...[
                            Row(
                              children: [
                                const Text('Close ',
                                    style: TextStyle(
                                      color: AppColors.black,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                    )),
                                Image.asset(
                                  "assets/images/done-green.png",
                                  height: 12,
                                ),
                              ],
                            )
                          ]
                        ],
                      ),
                      if (sr.supplier != null && sr.supplier!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoColumn('Supplier', sr.supplier!),
                      ],
                      const SizedBox(height: 8),
                      _buildInfoColumn(
                          'Remarks (No. DO)', sr.remarks.toString()),

                      
                      if (sr.receivedDate != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoColumn(
                          'Received Date',
                          DateFormat('d MMM yyyy', 'id_ID')
                              .format(sr.receivedDate!),
                        ),
                      ],

                      
                      if (sr.status.toLowerCase() == 'close' &&
                          sr.closeDate != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoColumn(
                          'Close Date',
                          DateFormat('d MMM yyyy, HH:mm', 'id_ID')
                              .format(sr.closeDate!),
                        ),
                      ],
                      if (sr.status.toLowerCase() != 'close' &&
                          sr.closeDate == null) ...[
                        const SizedBox(height: 8),
                        _buildInfoColumn(
                          'Close Date',
                          "Belum Ditutup",
                        ),
                      ],
                    ],
                  ),
                ),
                if (!_isViewer)
                  PopupMenuButton<String>(
                    color: const Color(0XFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.gray, size: 20),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showEditSRDialog(sr: sr);
                      } else if (value == 'delete') {
                        final confirm = await showModalBottomSheet<bool>(
                          context: context,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (ctx) {
                            return Padding(
                              padding: const EdgeInsets.all(20),
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
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    "Konfirmasi Hapus",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Anda yakin ingin menghapus item ini?",
                                    style: TextStyle(
                                        fontSize: 14, color: AppColors.gray),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            side: const BorderSide(
                                                color:
                                                    AppColors.schneiderGreen),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: const Text("Batal",
                                              style: TextStyle(
                                                  color: AppColors
                                                      .schneiderGreen)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            backgroundColor: AppColors.red,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: const Text("Hapus"),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            );
                          },
                        );

                        if (confirm == true && sr.id != null) {
                          await DatabaseHelper.instance
                              .deleteAdditionalSR(sr.id!);
                          _fetchSRs();
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Image.asset("assets/images/edit-gray.png",
                                height: 20),
                            const SizedBox(width: 8),
                            const Text('Edit',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Image.asset("assets/images/trash.png", height: 20),
                            const SizedBox(width: 8),
                            const Text('Hapus',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400)),
                          ],
                        ),
                      ),
                    ],
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.gray,
            fontSize: 11,
            fontWeight: FontWeight.w300,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }
}


class _AddEditSRDialog extends StatefulWidget {
  final String panelNoPp;
  final String poNumber;
  final AdditionalSR? sr;
  final VoidCallback onSave;

  const _AddEditSRDialog(
      {required this.poNumber,
      required this.panelNoPp,
      this.sr,
      required this.onSave});

  @override
  State<_AddEditSRDialog> createState() => _AddEditSRDialogState();
}

class _AddEditSRDialogState extends State<_AddEditSRDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _poController;
  late TextEditingController _itemController;
  late TextEditingController _qtyController;
  late TextEditingController _remarksController;
  late TextEditingController _closeDateController;
  late String _status;

  
  late TextEditingController _receivedDateController;
  DateTime? _selectedReceivedDate;

  bool _isSaving = false;

  List<Company> _supplierCompanies = [];
  bool _isLoadingCompanies = true;

  String? _selectedSupplier;

  @override
  void initState() {
    super.initState();
    final sr = widget.sr;
    _poController = TextEditingController(text: sr?.poNumber ?? '');
    _itemController = TextEditingController(text: sr?.item ?? '');
    _qtyController = TextEditingController(text: sr?.quantity.toString() ?? '');
    _remarksController = TextEditingController(text: sr?.remarks ?? '');
    _status = sr?.status ?? 'open';

    
    _closeDateController = TextEditingController();
    if (sr?.closeDate != null) {
      _closeDateController.text =
          DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(sr!.closeDate!);
    }

    
    _receivedDateController = TextEditingController();
    if (sr?.receivedDate != null) {
      _selectedReceivedDate = sr!.receivedDate;
      _receivedDateController.text =
          DateFormat('d MMM yyyy', 'id_ID').format(sr.receivedDate!);
    }

    _fetchSupplierCompanies().then((_) {
      if (sr?.supplier != null && sr!.supplier!.isNotEmpty) {
        if (!_supplierCompanies.any((c) => c.name == sr.supplier)) {
          _supplierCompanies.add(Company(
            id: sr.supplier!,
            name: sr.supplier!,
            role: AppRole.k3,
          ));
          _supplierCompanies.sort((a, b) => a.name.compareTo(b.name));
        }
        _selectedSupplier = sr.supplier;
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _fetchSupplierCompanies() async {
    if (mounted) setState(() => _isLoadingCompanies = true);
    try {
      final results = await Future.wait([
        DatabaseHelper.instance.getK3Vendors(),
        DatabaseHelper.instance.getK5Vendors(),
        DatabaseHelper.instance.getG3Vendors(),
      ]);
      final k3Vendors = results[0];
      final k5Vendors = results[1];
      final g3Vendors = results[2];

      final allVendors = [...k3Vendors, ...k5Vendors, ...g3Vendors];

      final uniqueVendorsMap = {for (var v in allVendors) v.name: v};
      final uniqueVendors = uniqueVendorsMap.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        setState(() {
          _supplierCompanies = uniqueVendors;
        });
      }
    } catch (e) {
      debugPrint("Error fetching K3/K5/G3 vendors: $e");
    } finally {
      if (mounted) setState(() => _isLoadingCompanies = false);
    }
  }

  Future<void> _showAddNewSupplierSheet() async {
    final newSupplierData = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddNewSupplierSheet(),
    );

    if (newSupplierData != null) {
      final String newName = newSupplierData['name'];
      final AppRole newRole = newSupplierData['role'];

      if (!_supplierCompanies.any((c) => c.name == newName)) {
        setState(() {
          _supplierCompanies.add(Company(
            id: newName.toLowerCase().replaceAll(' ', '_'),
            name: newName,
            role: newRole,
          ));
          _supplierCompanies.sort((a, b) => a.name.compareTo(b.name));
          _selectedSupplier = newName;
        });
      } else {
        setState(() {
          _selectedSupplier = newName;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    if (_formKey.currentState!.validate()) {
      if (_selectedSupplier == null || _selectedSupplier!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih atau isi supplier.'),
            backgroundColor: AppColors.red,
          ),
        );
        return;
      }

      setState(() => _isSaving = true);

      try {
        
        DateTime? closeDate;
        if (_status.toLowerCase() == 'close') {
          
          closeDate = widget.sr?.closeDate ?? DateTime.now().toUtc();
        } else {
          
          closeDate = null;
        }

        String finalSupplier = _selectedSupplier!;

        final srData = AdditionalSR(
          id: widget.sr?.id,
          poNumber: _poController.text.trim(),
          panelNoPp: widget.panelNoPp,
          item: _itemController.text.trim(),
          quantity: int.tryParse(_qtyController.text) ?? 0,
          supplier: finalSupplier,
          remarks: _remarksController.text.trim(),
          status: _status,
          closeDate: closeDate, 
          receivedDate: _selectedReceivedDate, 
        );

        if (widget.sr == null) {
          await DatabaseHelper.instance
              .createAdditionalSR(widget.panelNoPp, srData);
        } else {
          await DatabaseHelper.instance.updateAdditionalSR(srData.id!, srData);
        }

        if (mounted) {
          widget.onSave();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: AppColors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  
  Future<void> _selectReceivedDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedReceivedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.schneiderGreen, 
              onPrimary: Colors.white, 
              onSurface: AppColors.black, 
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.schneiderGreen, 
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedReceivedDate) {
      setState(() {
        _selectedReceivedDate = picked;
        _receivedDateController.text =
            DateFormat('d MMM yyyy', 'id_ID').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
              Text(
                widget.sr == null ? 'Tambah SR Baru' : 'Edit SR',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _poController,
                label: 'No. PO',
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _itemController,
                label: 'Item',
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _qtyController,
                label: 'Quantity',
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              _buildSupplierField(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _remarksController,
                label: 'Remarks (No. DO)',
                validator: (v) {
                  if (_status == 'close' && (v == null || v.trim().isEmpty)) {
                    return 'Remarks wajib diisi saat status Close';
                  }
                  return null;
                },
              ),
              
              
              const SizedBox(height: 16),
              _buildDatePickerField(
                controller: _receivedDateController,
                label: 'Received Date (Manual)',
                onTap: () => _selectReceivedDate(context),
              ),

              const SizedBox(height: 16),
              _buildSelectorSection(
                label: "Status",
                options: const {'open': 'Open', 'close': 'Close'},
                selectedValue: _status,
                onTap: (val) {
                  if (val != null) {
                    setState(() {
                      _status = val;
                      
                      if (_status == 'close') {
                        
                        if (_closeDateController.text.isEmpty) {
                           final now = DateTime.now();
                           _closeDateController.text =
                            DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(now);
                        }
                      } else {
                        
                        _closeDateController.clear();
                      }
                    });
                  }
                },
              ),

              
              const SizedBox(height: 16),
              _buildTextField(
                controller: _closeDateController,
                label: 'Close Date',
                isEnabled: false,
                hintText: 'Otomatis terisi saat status di-Close', 
              ),
              
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Supplier",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 12),
        _isLoadingCompanies
            ? const Center(
                child: CircularProgressIndicator(
                color: AppColors.schneiderGreen,
              ))
            : Wrap(
                spacing: 8,
                runSpacing: 12,
                children: [
                  ..._supplierCompanies.map((company) {
                    return _buildSupplierOptionButton(
                      company: company,
                      selected: _selectedSupplier == company.name,
                      onTap: () {
                        setState(() {
                          _selectedSupplier = company.name;
                        });
                      },
                    );
                  }),
                  _buildOtherButton(
                    selected: false,
                    onTap: _showAddNewSupplierSheet,
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildSupplierOptionButton({
    required Company company,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final Color borderColor =
        selected ? AppColors.schneiderGreen : AppColors.grayLight;
    final Color color =
        selected ? AppColors.schneiderGreen.withOpacity(0.08) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              company.name,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: AppColors.black,
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                company.role.name.toUpperCase(),
                style: const TextStyle(fontSize: 10, color: AppColors.gray),
              ),
              backgroundColor: AppColors.grayLight,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherButton(
      {required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grayLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          "Lainnya...",
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: AppColors.gray,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isEnabled = true,
    String? hintText,
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
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: isEnabled,
          cursorColor: AppColors.schneiderGreen,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText ?? (isEnabled ? 'Masukkan $label' : null),
            hintStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.gray,
              fontWeight: FontWeight.w300
            ),
            filled: !isEnabled,
            fillColor: Colors.grey.shade100,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  
  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          cursorColor: AppColors.schneiderGreen,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
          decoration: InputDecoration(
            hintText: 'Pilih Tanggal (Opsional)',
            hintStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.gray,
              fontWeight: FontWeight.w300
            ),
            suffixIcon: Row( 
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.text.isNotEmpty) 
                  IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.gray, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedReceivedDate = null;
                        _receivedDateController.clear();
                      });
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.calendar_month_outlined, color: AppColors.gray),
                  onPressed: onTap,
                ),
              ],
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildSelectorSection({
    required String label,
    required Map<String, String> options,
    required String? selectedValue,
    required ValueChanged<String?> onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: options.entries.map((entry) {
            return _buildOptionButton(
              label: entry.value,
              selected: selectedValue == entry.key,
              onTap: () => onTap(entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final Color borderColor =
        selected ? AppColors.schneiderGreen : AppColors.grayLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.schneiderGreen.withOpacity(0.08)
              : Colors.white,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.schneiderGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text("Batal",
                style: TextStyle(color: AppColors.schneiderGreen)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.schneiderGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text("Simpan"),
          ),
        ),
      ],
    );
  }
}


class _AddNewSupplierSheet extends StatefulWidget {
  const _AddNewSupplierSheet();
  @override
  State<_AddNewSupplierSheet> createState() => _AddNewSupplierSheetState();
}

class _AddNewSupplierSheetState extends State<_AddNewSupplierSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  AppRole _selectedRole = AppRole.g3;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final String finalName = _nameController.text.trim().toLowerCase();
      Navigator.pop(context, {
      'name': finalName,
      'role': _selectedRole, 
      'roleString': _selectedRole.name.toLowerCase(), 
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 16,
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
            const Text(
              "Pilih Perusahaan",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Company',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  cursorColor: AppColors.schneiderGreen,
                  controller: _nameController,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: AppColors.black,
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Nama tidak boleh kosong' : null,
                  decoration: InputDecoration(
                    fillColor: AppColors.white,
                    filled: true,
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
                      borderSide: const BorderSide(
                        color: AppColors.schneiderGreen,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildRoleSelector(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
  Widget _buildRoleSelector() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Role',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: AppRole.values
                .where((role) => role == AppRole.g3)
                .map((role) {
              return _buildOptionButton(
                label: role.name.toUpperCase(),
                selected: _selectedRole == role,
                onTap: () => setState(() => _selectedRole = role),
              );
            }).toList(),
          ),
        ],
      );
    }

  Widget _buildOptionButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final Color borderColor =
        selected ? AppColors.schneiderGreen : AppColors.grayLight;
    final Color color =
        selected ? AppColors.schneiderGreen.withOpacity(0.08) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: AppColors.black,
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
            onPressed: _isSaving ? null : () => Navigator.pop(context),
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
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.schneiderGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text("Simpan", style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }
}