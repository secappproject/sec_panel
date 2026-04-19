import 'package:flutter/material.dart';
import 'package:secpanel/models/paneldisplaydata.dart';

class WiringForm extends StatefulWidget {
  final PanelDisplayData panel;
  final ValueChanged<PanelDisplayData> onSubmit;

  const WiringForm({
    super.key,
    required this.panel,
    required this.onSubmit,
  });

  @override
  State<WiringForm> createState() => _WiringFormState();
}

class _WiringFormState extends State<WiringForm> {
  late String _status;
  late double _progress;

  final List<String> _statusOptions = [
    'Open',
    'In Progress',
    'Done',
  ];

  @override
  void initState() {
    super.initState();
    _status = _statusOptions.contains(widget.panel.wiringStatus)
        ? widget.panel.wiringStatus
        : 'Open'; // 🆕 pastikan value valid

    _progress = widget.panel.wiringProgress.toDouble(); // tetap
  }

  void _submit() {
    widget.panel.wiringStatus = _status;
    widget.panel.wiringProgress = _progress.round();
    widget.onSubmit(widget.panel);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Edit Wiring Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // STATUS DROPDOWN
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: _statusOptions
                .map(
                  (status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _status = value;
                if (value == 'Done') {
                  _progress = 100;
                } else if (value == 'Open') {
                  _progress = 0;
                } else {
                  _progress = _progress.clamp(1, 99); // 🆕 pastikan tidak 0/100
                }
              });
            },
          ),

          const SizedBox(height: 16),

          // PROGRESS SLIDER
          Row(
            children: [
              const Text('Progress'),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _progress,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${_progress.round()}%',
                  onChanged: (value) {
                    setState(() {
                      _progress = value;
                      if (value >= 100) {
                        _status = 'Done';
                      } else if (value > 0) {
                        _status = 'In Progress';
                      } else {
                        _status = 'Open';
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text('${_progress.round()}%'),
            ],
          ),

          const SizedBox(height: 16),

          // SAVE BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Simpan'),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
