// lib/components/panel/additional_sr/additional_sr_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/additionalsr.dart';
import 'package:secpanel/theme/colors.dart';

class AdditionalSrBottomSheet extends StatefulWidget {
  final String panelNoPp;
  final String panelTitle;

  const AdditionalSrBottomSheet({
    super.key,
    required this.panelNoPp,
    required this.panelTitle,
  });

  @override
  State<AdditionalSrBottomSheet> createState() => _AdditionalSrBottomSheetState();
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
      final srs = await DatabaseHelper.instance.getAdditionalSRs(widget.panelNoPp);
      if (mounted) {
        setState(() {
          _srs = srs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditSRDialog({AdditionalSR? sr}) {
    showDialog(
      context: context,
      builder: (context) => _AddEditSRDialog(
        panelNoPp: widget.panelNoPp,
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
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Additional SR Package',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            widget.panelTitle,
                            style: const TextStyle(fontSize: 14, color: AppColors.gray),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showEditSRDialog(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tambah'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.schneiderGreen,
                        foregroundColor: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _srs.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada Additional SR.',
                              style: TextStyle(color: AppColors.gray),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchSRs,
                            child: ListView.separated(
                              controller: controller,
                              itemCount: _srs.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final sr = _srs[index];
                                return _buildSRListItem(sr);
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSRListItem(AdditionalSR sr) {
    final bool isClosed = sr.status == 'close';
    return ListTile(
      title: Text('${sr.item} (Qty: ${sr.quantity})', style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PO: ${sr.poNumber}'),
          Text('DO: ${sr.remarks}'),
        ],
      ),
      leading: Icon(
        isClosed ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isClosed ? Colors.green : Colors.orange,
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'edit') {
            _showEditSRDialog(sr: sr);
          } else if (value == 'delete') {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Konfirmasi'),
                content: const Text('Anda yakin ingin menghapus item ini?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
            if (confirm == true && sr.id != null) {
              await DatabaseHelper.instance.deleteAdditionalSR(sr.id!);
              _fetchSRs();
            }
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
          const PopupMenuItem<String>(value: 'delete', child: Text('Hapus')),
        ],
      ),
    );
  }
}

// Dialog Form untuk Tambah/Edit
class _AddEditSRDialog extends StatefulWidget {
  final String panelNoPp;
  final AdditionalSR? sr;
  final VoidCallback onSave;

  const _AddEditSRDialog({required this.panelNoPp, this.sr, required this.onSave});

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

  @override
  void initState() {
    super.initState();
    _poController = TextEditingController(text: widget.sr?.poNumber ?? '');
    _itemController = TextEditingController(text: widget.sr?.item ?? '');
    _qtyController = TextEditingController(text: widget.sr?.quantity.toString() ?? '');
    _remarksController = TextEditingController(text: widget.sr?.remarks ?? '');
    _status = widget.sr?.status ?? 'open';
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final srData = AdditionalSR(
        id: widget.sr?.id,
        panelNoPp: widget.panelNoPp,
        poNumber: _poController.text,
        item: _itemController.text,
        quantity: int.tryParse(_qtyController.text) ?? 0,
        remarks: _remarksController.text,
        status: _status,
      );

      try {
        if (widget.sr == null) {
          await DatabaseHelper.instance.createAdditionalSR(widget.panelNoPp, srData);
        } else {
          await DatabaseHelper.instance.updateAdditionalSR(srData.id!, srData);
        }
        widget.onSave();
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.sr == null ? 'Tambah SR Baru' : 'Edit SR'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _itemController,
                decoration: const InputDecoration(labelText: 'Item'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _qtyController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _poController,
                decoration: const InputDecoration(labelText: 'No. PO'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks (No. DO)'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['open', 'close']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        ElevatedButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}