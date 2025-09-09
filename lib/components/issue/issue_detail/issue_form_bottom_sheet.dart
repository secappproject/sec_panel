import 'dart:io';
import 'package:flutter/material.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/issue.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IssueFormBottomSheet extends StatefulWidget {
  final VoidCallback onIssueSaved;
  // Tetap nullable untuk fleksibilitas di masa depan
  final Issue? existingIssue;

  const IssueFormBottomSheet({
    super.key,
    required this.onIssueSaved,
    this.existingIssue, // Dibuat opsional
  });

  @override
  State<IssueFormBottomSheet> createState() => _IssueFormBottomSheetState();
}

class _IssueFormBottomSheetState extends State<IssueFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  String? _selectedType;
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isEditMode = false;

  final List<String> _issueTypeOptions = const [
    "Masalah 1",
    "Masalah 2",
    "Masalah 3",
  ];

  @override
  void initState() {
    super.initState();

    // ▼▼▼ FIX: NULL CHECK IS ADDED HERE ▼▼▼
    _isEditMode = widget.existingIssue != null;

    if (_isEditMode) {
      // Access properties only if existingIssue is not null
      _descriptionController = TextEditingController(
        text: widget.existingIssue!.description,
      );
      _selectedType = widget.existingIssue!.title;
    } else {
      // Initialize for creating a new issue
      _descriptionController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitIssue() async {
    // Check for null only in edit mode
    if (_isEditMode && widget.existingIssue == null) return;

    if (!_formKey.currentState!.validate() || _selectedType == null) {
      if (_selectedType == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih tipe masalah.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('loggedInUsername') ?? 'unknown_user';

      // ▼▼▼ FIX: NULL CHECK FOR 'status' and 'id' ▼▼▼
      final issueData = {
        'issue_title': _selectedType,
        'issue_description': _descriptionController.text.trim(),
        'issue_status': widget.existingIssue!.status,
        'updated_by': username,
      };

      await DatabaseHelper.instance.updateIssue(
        widget.existingIssue!.id,
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
    // This build method assumes it's always in edit mode based on your current usage.
    // If you plan to use it for adding new issues, you'd add more logic here.
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
                _isEditMode ? "Edit Issue" : "Tambah Issue", // Dynamic title
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              _buildSelectorSection(
                label: "Tipe Masalah",
                options: _issueTypeOptions,
                selectedValue: _selectedType,
                onTap: (tappedOption) {
                  setState(() {
                    _selectedType = tappedOption;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: "Deskripsi (Opsional)",
                maxLines: 4,
              ),
              const SizedBox(height: 24),
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
          controller: controller,
          maxLines: maxLines,
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
                : Text(_isEditMode ? "Update" : "Simpan"),
          ),
        ),
      ],
    );
  }
}
