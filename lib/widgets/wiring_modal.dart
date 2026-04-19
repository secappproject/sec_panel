import 'package:flutter/material.dart';
import 'package:secpanel/models/paneldisplaydata.dart';
import 'package:secpanel/helpers/db_helper.dart';

class WiringModal {
  static Future<PanelDisplayData?> open({
    required BuildContext context,
    required PanelDisplayData panel,
  }) {
    return showModalBottomSheet<PanelDisplayData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WiringModalContent(panel: panel),
    );
  }
}

class _WiringModalContent extends StatefulWidget {
  final PanelDisplayData panel;

  const _WiringModalContent({Key? key, required this.panel}) : super(key: key);

  @override
  State<_WiringModalContent> createState() => _WiringModalContentState();
}

class _WiringModalContentState extends State<_WiringModalContent> {
  late TextEditingController _progressController;
  late String _selectedStatus;
  late String _selectedVendorId;
  DateTime? _targetDeliveryWiring;
  final List<String> _statusOptions = ["Open", "In Progress", "Closed"];

  @override
  void initState() {
    super.initState();

    _progressController = TextEditingController(
      text: widget.panel.wiringProgress.toString(),
    );

    _selectedStatus = _calculateStatus(widget.panel.wiringProgress);

    _selectedVendorId = widget.panel.wiringVendorIds.isNotEmpty
        ? widget.panel.wiringVendorIds.first
        : "";
    _targetDeliveryWiring = widget.panel.targetDeliveryWiring;
    _progressController.addListener(_handleProgressChange);
  }

  @override
  void dispose() {
    _progressController.removeListener(_handleProgressChange);
    _progressController.dispose();
    super.dispose();
  }

  // ==========================
  // FUNCTION HITUNG STATUS
  // ==========================
  String _calculateStatus(int progress) {
    if (progress >= 100) return "Closed";
    if (progress > 0) return "In Progress";
    return "Open";
  }

  void _handleProgressChange() {
    final value = int.tryParse(_progressController.text.trim()) ?? 0;
    final newStatus = _calculateStatus(value);

    if (newStatus != _selectedStatus) {
      setState(() {
        _selectedStatus = newStatus;
      });
    }
  }

  // ==========================
  // SAVE FUNCTION
  // ==========================
  Future<void> _onSavePressed() async {
    final int newProgress = int.tryParse(_progressController.text.trim()) ?? 0;

    if (newProgress < 0 || newProgress > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Progress harus antara 0 - 100")),
      );
      return;
    }

    final calculatedStatus = _calculateStatus(newProgress);

    try {
      await DatabaseHelper.instance.updateWiringStatus(
        panelNoPp: widget.panel.panel.noPp ?? '',
        noWbs: widget.panel.panel.noWbs ?? "",
        noPanel: widget.panel.panel.noPanel ?? '',
        wiringProgress: newProgress,
        status: calculatedStatus,
        wiringVendorId: _selectedVendorId.isNotEmpty ? _selectedVendorId : null,
        targetDeliveryWiring: _targetDeliveryWiring != null
            ? DateTime.parse(_targetDeliveryWiring!.toIso8601String())
            : null,
      );

      if (!mounted) return;

      setState(() {
        widget.panel.wiringProgress = newProgress;
        widget.panel.wiringStatus = calculatedStatus;
        widget.panel.targetDeliveryWiring = _targetDeliveryWiring;
        widget.panel.panel.statusWiring = calculatedStatus;

        if (newProgress == 100) {
          widget.panel.panel.closedDate = DateTime.now();
        }
      });

      if (Navigator.canPop(context)) {
        Navigator.pop(context, widget.panel);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Update Wiring Progress",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),

            /// Progress input
            TextFormField(
              controller: _progressController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Progress (%)",
                hintText: "0 - 100",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.speed),
              ),
            ),
            const SizedBox(height: 12),

            /// Status otomatis realtime
            Text(
              "Status otomatis: $_selectedStatus",
              style: TextStyle(
                color: _selectedStatus == "Closed"
                    ? Colors.green
                    : _selectedStatus == "In Progress"
                    ? Colors.orange
                    : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            /// TARGET DELIVERY WIRING
            const Text(
              "Target Delivery Wiring",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _targetDeliveryWiring ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );

                if (picked != null) {
                  setState(() {
                    _targetDeliveryWiring = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _targetDeliveryWiring != null
                      ? "${_targetDeliveryWiring!.day}/${_targetDeliveryWiring!.month}/${_targetDeliveryWiring!.year}"
                      : "Pilih tanggal",
                  style: TextStyle(
                    color: _targetDeliveryWiring != null
                        ? Colors.black
                        : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            /// Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _onSavePressed,
                  child: const Text("Save Changes"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
