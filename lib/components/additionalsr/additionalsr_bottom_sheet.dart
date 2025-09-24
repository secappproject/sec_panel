import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/additionalsr.dart';
import 'package:secpanel/theme/colors.dart';

class AdditionalSrBottomSheet extends StatefulWidget {
  final String poNumber;
  final String panelNoPp;
  final String panelTitle;

  const AdditionalSrBottomSheet({
    super.key,
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

  @override
  void initState() {
    super.initState();
    _fetchSRs();
  }

  Future<void> _fetchSRs() async {
    setState(() => _isLoading = true);
    try {
      final srs =
          await DatabaseHelper.instance.getAdditionalSRs(widget.poNumber);
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
                          'Additional SR Package',
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
                  ElevatedButton.icon(
                    onPressed: () => _showEditSRDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tambah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),),
                    style: ElevatedButton.styleFrom(
                      shadowColor: Colors.transparent,
                      backgroundColor: AppColors.schneiderGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _srs.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 48.0),
                            child: Text(
                              'Belum ada Additional SR.',
                              style: TextStyle(color: AppColors.gray),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchSRs,
                          child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _srs.map((sr) {
                            return SizedBox(
                              width: MediaQuery.of(context).size.width / 2 - 24, // 2 kolom
                              child: _buildSRListItemCard(sr),
                            );
                          }).toList(),
                        )
                      ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSRListItemCard(AdditionalSR sr) {
    final bool isClosed = sr.status == 'close';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      // Qty
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Qty',
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: 11,
                              fontWeight: FontWeight.w300,
                            )
                          ),
                          Text(
                            sr.quantity.toString(),
                            style: const TextStyle(
                              color: AppColors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8,),
                      // PO
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No. PO',
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: 11,
                              fontWeight: FontWeight.w300,
                            )
                          ),
                          Text(
                            sr.poNumber.toString(),
                            style: const TextStyle(
                              color: AppColors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8,),
                      // Status
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: 11,
                              fontWeight: FontWeight.w300,
                            )
                          ),
                          if (sr.status == "Open" || sr.status == "open")...[
                            Row(
                              children: [
                                const Text(
                                  'Open ',
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  )
                                ),
                                Image.asset("assets/images/on-progress-blue.png", height: 12,),
                              ],
                            )
                          ],
                          if (sr.status == "Close" || sr.status == "close")...[
                            Row(
                              children: [
                                const Text(
                                  'Close ',
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  )
                                ),
                                Image.asset("assets/images/done-green.png"),
                              ],
                            )
                          ]
                        ],
                      ),

                      const SizedBox(height: 8,),
                      // Remarks
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Remarks (No. DO)',
                            style: TextStyle(
                              color: AppColors.gray,
                              fontSize: 11,
                              fontWeight: FontWeight.w300,
                            )
                          ),
                          Text(
                            sr.remarks.toString(),
                            style: const TextStyle(
                              color: AppColors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),

                      // [BARU] Tampilkan Received Date jika status close
                      if (sr.status.toLowerCase() == 'close' && sr.receivedDate != null) ...[
                        const SizedBox(height: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Received Date',
                              style: TextStyle(
                                color: AppColors.gray,
                                fontSize: 11,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            Text(
                              DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(sr.receivedDate!),
                              style: const TextStyle(
                                color: AppColors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
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
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Anda yakin ingin menghapus item ini?",
                                  style: TextStyle(fontSize: 14, color: AppColors.gray),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          backgroundColor: AppColors.red,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
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
                          Image.asset("assets/images/trash.png",
                              height: 20),
                          const SizedBox(width: 8),
                          const Text('Hapus',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400)),
                        ],
                      ),
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


  // [BARU] Widget helper untuk teks info yang ringkas
  Widget _buildInfoText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.gray,
          fontWeight: FontWeight.w300,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// Dialog Form untuk Tambah/Edit (tidak ada perubahan di sini)
class _AddEditSRDialog extends StatefulWidget {
  final String panelNoPp;
  final String poNumber;
  final AdditionalSR? sr;
  final VoidCallback onSave;

  const _AddEditSRDialog(
      {required this.poNumber, required this.panelNoPp, this.sr, required this.onSave});

  @override
  State<_AddEditSRDialog> createState() => _AddEditSRDialogState();
}

class _AddEditSRDialogState extends State<_AddEditSRDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _poController;
  late TextEditingController _itemController;
  late TextEditingController _qtyController;
  late TextEditingController _remarksController;
  late String _status;
  bool _usePanelPoAsPo = false;

  @override
  void initState() {
    super.initState();
    final srPoNumber = widget.sr?.poNumber;
      _poController = TextEditingController(
        text: (srPoNumber == null || srPoNumber.isEmpty || srPoNumber.startsWith("TEMP_"))
            ? ''
            : srPoNumber,
      );
    _itemController = TextEditingController(text: widget.sr?.item ?? '');
    _qtyController =
        TextEditingController(text: widget.sr?.quantity.toString() ?? '');
    _remarksController = TextEditingController(text: widget.sr?.remarks ?? '');
    _status = widget.sr?.status ?? 'open';
  }
  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      String poNumber;

      if (_usePanelPoAsPo) {
        // user pilih samakan dengan panel → pakai no PP
        poNumber = widget.poNumber;
      } else {
        // user manual isi → wajib validator
        poNumber = _poController.text.trim();
      }

      final srData = AdditionalSR(
        id: widget.sr?.id,
        poNumber: poNumber,  
        panelNoPp: widget.panelNoPp,
        item: _itemController.text,
        quantity: int.tryParse(_qtyController.text) ?? 0,
        remarks: _remarksController.text,
        status: _status,
        receivedDate: widget.sr?.receivedDate, // [PENTING] Kirim tanggal yang ada agar tidak hilang
      );
      try {
        if (widget.sr == null) {
          await DatabaseHelper.instance
              .createAdditionalSR(widget.poNumber, srData);
        } else {
          await DatabaseHelper.instance.updateAdditionalSR(srData.id!, srData);
        }
        widget.onSave();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: AppColors.red),
          );
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
              // SwitchListTile(
              //   title: const Text(
              //     'No. PO sama dengan No. Po Panel',
              //     style: TextStyle(fontSize: 12),
              //   ),
              //   value: _usePanelPoAsPo,
              //   onChanged: (bool value) {
              //     setState(() {
              //       _usePanelPoAsPo = value;
              //       if (_usePanelPoAsPo) {
              //         _poController.text = widget.poNumber;  
              //       } else {
              //         _poController.text = widget.sr?.poNumber ?? '';
              //       }
              //     });
              //   },
              //   dense: true,
              //   contentPadding: EdgeInsets.zero,
              //   activeColor: AppColors.schneiderGreen,
              // ),

              const SizedBox(height: 8),
              _buildTextField(
                controller: _poController,
                label: 'No. PO',
                isEnabled: !_usePanelPoAsPo,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
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
                    if (val != null) setState(() => _status = val);
                  }),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
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
        helperText: !isEnabled ? 'Menggunakan No. Po Panel' : null,
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
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
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.schneiderGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text("Simpan"),
          ),
        ),
      ],
    );
  }
}