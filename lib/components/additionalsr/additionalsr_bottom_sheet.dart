import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/additionalsr.dart';
import 'package:secpanel/models/approles.dart'; // Import AppRole
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
      builder: (context) => _AddEditSRDialog( // Pastikan _AddEditSRDialog sudah ada di file ini atau diimport
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
                  (!_isViewer) ?
                  ElevatedButton.icon(
                    onPressed: () => _showEditSRDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Tambah',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                    ),
                    style: ElevatedButton.styleFrom(
                      shadowColor: Colors.transparent,
                      backgroundColor: AppColors.schneiderGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ) 
                  : SizedBox()
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
                              // --- LOGIKA DISESUAIKAN DI SINI ---
                              int crossAxisCount;
                              if (constraints.maxWidth >= 600) {
                                crossAxisCount = 3; // Untuk non-mobile (Tablet & Desktop)
                              } else {
                                crossAxisCount = 2; // Untuk mobile
                              }

                              const double spacing = 12.0;
                              final double totalSpacing = (crossAxisCount - 1) * spacing;
                              final double itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;

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
                      if (sr.status.toLowerCase() == 'close' &&
                          sr.receivedDate != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoColumn(
                          'Received Date',
                          DateFormat('d MMM yyyy, HH:mm', 'id_ID')
                              .format(sr.receivedDate!),
                        ),
                      ],
                      if (sr.status.toLowerCase() != 'close' &&
                          sr.receivedDate == null) ...[
                        const SizedBox(height: 8),
                        _buildInfoColumn(
                          'Received Date',
                          "Belum Diterima",
                        ),
                      ],
                    ],
                  ),
                ),
                (!_isViewer) ?
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
                                      borderRadius: BorderRadius.circular(100),
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
                                              color: AppColors.schneiderGreen),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ),
                                        child: const Text("Batal",
                                            style: TextStyle(
                                                color:
                                                    AppColors.schneiderGreen)),
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
                                  fontSize: 12, fontWeight: FontWeight.w400)),
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
                                  fontSize: 12, fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                  ],
                ): SizedBox(),
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

// Dialog Form untuk Tambah/Edit
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
  late TextEditingController _supplierController;
  late TextEditingController _remarksController;
  late TextEditingController _receivedDateController;
  late String _status;

  // --- 1. STATE UNTUK LOADING ---
  bool _isSaving = false;

  List<Company> _supplierCompanies = [];
  bool _isLoadingCompanies = true;

  String? _selectedSupplier;
  bool _showManualSupplierInput = false;

  @override
  void initState() {
    super.initState();
    final sr = widget.sr;
    _poController = TextEditingController(text: sr?.poNumber ?? '');
    _itemController = TextEditingController(text: sr?.item ?? '');
    _qtyController = TextEditingController(text: sr?.quantity.toString() ?? '');
    _remarksController = TextEditingController(text: sr?.remarks ?? '');
    _status = sr?.status ?? 'open';
    _receivedDateController = TextEditingController();
    if (sr?.receivedDate != null) {
      _receivedDateController.text =
          DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(sr!.receivedDate!);
    }
    
    _supplierController = TextEditingController();
    
    _fetchSupplierCompanies().then((_) {
      if (sr?.supplier != null && sr!.supplier!.isNotEmpty) {
        if (_supplierCompanies.any((c) => c.name == sr.supplier)) {
          _selectedSupplier = sr.supplier;
          _showManualSupplierInput = false;
        } else {
          _selectedSupplier = 'Lainnya...';
          _showManualSupplierInput = true;
          _supplierController.text = sr.supplier!;
        }
        if (mounted) setState(() {});
      }
    });
  }
  
  Future<void> _fetchSupplierCompanies() async {
    if(mounted) setState(() => _isLoadingCompanies = true);
    try {
      final results = await Future.wait([
        DatabaseHelper.instance.getK3Vendors(),
        DatabaseHelper.instance.getK5Vendors(),
      ]);
      final k3Vendors = results[0];
      final k5Vendors = results[1];

      final allVendors = [...k3Vendors, ...k5Vendors];
      
      final uniqueVendorsMap = {for (var v in allVendors) v.name: v};
      final uniqueVendors = uniqueVendorsMap.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        setState(() {
          _supplierCompanies = uniqueVendors;
        });
      }
    } catch (e) {
      debugPrint("Error fetching K3/K5 vendors: $e");
    } finally {
      if(mounted) setState(() => _isLoadingCompanies = false);
    }
  }

  // --- 2. FUNGSI SUBMIT YANG SUDAH DIUBAH ---
  Future<void> _submit() async {
    // Mencegah double-click jika sudah dalam proses saving
    if (_isSaving) return;

    if (_formKey.currentState!.validate()) {
      if (_selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih atau isi supplier.'),
            backgroundColor: AppColors.red,
          ),
        );
        return;
      }
      
      // Atur state menjadi loading SEBELUM memanggil database
      setState(() => _isSaving = true);

      try {
        DateTime? receivedDate;
        if (_status.toLowerCase() == 'close') {
          receivedDate = widget.sr?.receivedDate ?? DateTime.now().toUtc();
        } else {
          receivedDate = null;
        }

        String finalSupplier;
        if (_selectedSupplier == 'Lainnya...') {
          finalSupplier = _supplierController.text.trim();
        } else {
          finalSupplier = _selectedSupplier ?? '';
        }

        if (finalSupplier.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Supplier tidak boleh kosong.'),
              backgroundColor: AppColors.red,
            ),
          );
          // Hentikan loading jika validasi gagal
          setState(() => _isSaving = false);
          return;
        }

        final srData = AdditionalSR(
          id: widget.sr?.id,
          poNumber: _poController.text.trim(),
          panelNoPp: widget.panelNoPp,
          item: _itemController.text.trim(),
          quantity: int.tryParse(_qtyController.text) ?? 0,
          supplier: finalSupplier,
          remarks: _remarksController.text.trim(),
          status: _status,
          receivedDate: receivedDate,
        );

        if (widget.sr == null) {
          await DatabaseHelper.instance
              .createAdditionalSR(widget.panelNoPp, srData);
        } else {
          await DatabaseHelper.instance.updateAdditionalSR(srData.id!, srData);
        }
        
        // Pastikan widget masih ada sebelum memanggil onSave
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
        // Atur state kembali ke tidak loading SETELAH semua selesai
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
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
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
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
                        // isi tanggal sekarang
                        final now = DateTime.now();
                        _receivedDateController.text =
                            DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(now);
                      } else {
                        // kosongin lagi kalau bukan close
                        _receivedDateController.clear();
                      }
                    });
                  }
                },
              ),
              if (_status == 'close') ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _receivedDateController,
                  label: 'Received Date',
                  isEnabled: false,
                ),
              ] else ...[
                const SizedBox(height: 16),
                const Text(
                  'PO Received Date',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Lexend',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Diperoleh saat diterima (close)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'Lexend',
                    color: AppColors.gray,
                  ),
                ),
              ],
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
            ? const Center(child: CircularProgressIndicator(color: AppColors.schneiderGreen,))
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
                          _showManualSupplierInput = false;
                          _supplierController.clear();
                        });
                      },
                    );
                  }),
                  _buildOtherButton(
                    selected: _selectedSupplier == 'Lainnya...',
                    onTap: () {
                      setState(() {
                        _selectedSupplier = 'Lainnya...';
                        _showManualSupplierInput = true;
                      });
                    },
                  ),
                ],
              ),
        if (_showManualSupplierInput) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _supplierController,
            label: "Nama Supplier Lainnya",
            validator: (v) {
              if (_showManualSupplierInput && (v == null || v.isEmpty)) {
                return 'Nama supplier wajib diisi';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSupplierOptionButton({
    required Company company,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final Color borderColor = selected
        ? AppColors.schneiderGreen
        : AppColors.grayLight;
    final Color color = selected
        ? AppColors.schneiderGreen.withOpacity(0.08)
        : Colors.white;

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

  Widget _buildOtherButton({required bool selected, required VoidCallback onTap}) {
    final Color borderColor = selected ? AppColors.schneiderGreen : AppColors.grayLight;
    final Color color = selected ? AppColors.schneiderGreen.withOpacity(0.08) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor),
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
            hintText: isEnabled ? 'Masukkan $label' : null,
            helperStyle: const TextStyle(
              fontSize: 11,
              color: AppColors.gray,
              fontWeight: FontWeight.w300,
            ),
            filled: !isEnabled,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
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

  // --- 3. TAMPILAN TOMBOL YANG SUDAH DIUBAH ---
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            // Nonaktifkan tombol saat menyimpan
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
            // Nonaktifkan tombol saat menyimpan
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.schneiderGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Tampilkan loading atau teks "Simpan" berdasarkan state
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