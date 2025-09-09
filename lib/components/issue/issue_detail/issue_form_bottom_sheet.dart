import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/theme/colors.dart';

import '../../../models/issue.dart';

class IssueFormBottomSheet extends StatefulWidget {
  final VoidCallback onIssueSaved;
  final Issue existingIssue;

  const IssueFormBottomSheet({
    super.key,
    required this.onIssueSaved,
    required this.existingIssue,
  });

  @override
  State<IssueFormBottomSheet> createState() => _IssueFormBottomSheetState();
}

class _IssueFormBottomSheetState extends State<IssueFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String? _selectedType;
  final List<File> _selectedImages =
      []; // Note: API does not support adding photos on update yet
  bool _isLoading = false;

  final List<String> _issueTypeOptions = const [
    "Masalah 1",
    "Masalah 2",
    "Masalah 3",
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingIssue.title);
    _descriptionController = TextEditingController(
      text: widget.existingIssue.description,
    );
    _selectedType = widget.existingIssue.type;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      // TODO: Get real username
      const username = 'flutter_user';

      final issueData = {
        'issue_title': _titleController.text.trim(),
        'issue_description': _descriptionController.text.trim(),
        'issue_type': _selectedType ?? '',
        'issue_status': widget.existingIssue.status, // Keep original status
        'updated_by': username,
      };

      await DatabaseHelper.instance.updateIssue(
        widget.existingIssue.id,
        issueData,
      );

      if (mounted) {
        widget.onIssueSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui issue: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
              const Text(
                "Edit Issue",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _titleController,
                label: "Judul Issue",
                validator: (val) => val == null || val.isEmpty
                    ? 'Judul tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: "Deskripsi",
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildSelectorSection(
                label: "Tipe Masalah",
                options: _issueTypeOptions,
                selectedValue: _selectedType,
                onTap: (tappedOption) {
                  setState(() {
                    _selectedType = (_selectedType == tappedOption)
                        ? null
                        : tappedOption;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
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
                        foregroundColor: AppColors.schneiderGreen,
                      ),
                      child: const Text("Batal"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitIssue,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.schneiderGreen,
                        foregroundColor: Colors.white,
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
                          : const Text("Update"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int? maxLines = 1,
    String? Function(String?)? validator,
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
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          cursorColor: AppColors.schneiderGreen,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
          decoration: InputDecoration(
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

  Widget _buildSelectorSection({
    required String label,
    required List<String> options,
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
          children: options.map((option) {
            return _buildOptionButton(
              label: option,
              selected: selectedValue == option,
              onTap: () => onTap(option),
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
              : Colors.white,
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
}
