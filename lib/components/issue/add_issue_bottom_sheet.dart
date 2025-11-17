

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:secpanel/components/issue/panel_issue_screen.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/approles.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class AddIssueBottomSheet extends StatefulWidget {
  final String panelNoPp;
  final VoidCallback onIssueAdded;

  const AddIssueBottomSheet({
    super.key,
    required this.panelNoPp,
    required this.onIssueAdded,
  });

  @override
  State<AddIssueBottomSheet> createState() => _AddIssueBottomSheetState();
}

class _AddIssueBottomSheetState extends State<AddIssueBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _emailInputController = TextEditingController();
  final List<String> _notifyEmails = [];
  final FocusNode _emailFocusNode = FocusNode();

  List<String> _recommendedEmails = [];
  bool _isLoadingRecommendations = true;

  List<Map<String, dynamic>> _issueTitleOptions = [];
  String? _selectedTitle;
  bool _isLoadingTitles = true;
  bool _isAdmin = false;

  final List<File> _selectedImages = [];
  bool _isLoading = false;
  static const List<Color> _userAvatarColors = [
    Color(0xFFFF5DD1),
    Color(0xFF0400FF),
    Color(0xFF00B2FF),
    Color(0xFFFF9E50),
    Color(0xFFFF0000),
  ];
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _checkUserRole();
    await _loadIssueTitles();
    
    _loadRecommendedEmails();
  }

  
  Future<void> _loadRecommendedEmails() async {
    if (!mounted) return;
    setState(() => _isLoadingRecommendations = true);
    try {
      final emails = await DatabaseHelper.instance
          .getEmailRecommendations(panelNoPp: widget.panelNoPp);
      if (mounted) {
        setState(() {
          _recommendedEmails = emails;
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat rekomendasi email dari BE: $e");
      if (mounted) setState(() => _isLoadingRecommendations = false);
    }
  }
  

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedInUsername');
    if (username != null) {
      final company =
          await DatabaseHelper.instance.getCompanyByUsername(username);
      if (mounted && company != null) {
        setState(() => _isAdmin = company.role == AppRole.admin);
      }
    }
  }

  Future<void> _loadIssueTitles() async {
    if (!mounted) return;
    setState(() => _isLoadingTitles = true);
    try {
      final titles = await DatabaseHelper.instance.getIssueTitles();
      if (mounted) {
        setState(() {
          _issueTitleOptions = titles;
          if (_selectedTitle != null &&
              !_issueTitleOptions.any((t) => t['title'] == _selectedTitle)) {
            _selectedTitle = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text('Gagal memuat root cause: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingTitles = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _emailInputController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _addEmailToList() {
    final String email = _emailInputController.text.trim();
    if (email.isEmpty) return;

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (emailRegex.hasMatch(email) && !_notifyEmails.contains(email)) {
      setState(() {
        _notifyEmails.add(email);
        _emailInputController.clear();
      });
    }
    _emailFocusNode.requestFocus();
  }

  void _addRecommendedEmail(String email) {
    if (!_notifyEmails.contains(email)) {
      setState(() => _notifyEmails.add(email));
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.image, allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var platformFile in result.files) {
            if (platformFile.path != null) {
              _selectedImages.add(File(platformFile.path!));
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal membuka galeri: $e')));
      }
    }
  }

  void _removeImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  void _showFullScreenImage(File imageFile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            panEnabled: false,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4,
            child: Image.file(imageFile, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> _submitIssue() async {
    _addEmailToList();
    if (!_formKey.currentState!.validate() || _selectedTitle == null) {
      if (_selectedTitle == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Silakan pilih root cause.'),
            backgroundColor: Colors.red));
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      List<String> imageBase64List = [];
      for (var imageFile in _selectedImages) {
        final bytes = await imageFile.readAsBytes();
        imageBase64List.add(base64Encode(bytes));
      }
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('loggedInUsername') ?? 'unknown_user';
      final issueData = {
        'issue_title': _selectedTitle,
        'issue_description': _descriptionController.text.trim(),
        'notify_email': _notifyEmails.join(','),
        'created_by': username,
        'photos': imageBase64List,
      };
      await DatabaseHelper.instance
          .createIssueForPanel(widget.panelNoPp, issueData);
      if (mounted) {
        PanelIssuesScreen.showSnackBar('Issue baru berhasil ditambahkan!');
        widget.onIssueAdded();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal menambahkan issue: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddTitleSheet() async {
    final bool? success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: const _AddNewIssueTitleSheet()),
    );
    if (success == true) _loadIssueTitles();
  }

  Future<void> _showEditTitleSheet(Map<String, dynamic> titleData) async {
    final bool? success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: _EditIssueTitleSheet(titleData: titleData)),
    );
    if (success == true) _loadIssueTitles();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16),
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
                      borderRadius: BorderRadius.circular(100)),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Tambah Issue Baru",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),
              _buildIssueTitleSelector(),
              const SizedBox(height: 16),
              _buildCombinedDescriptionPhotoField(),
              const SizedBox(height: 24),
              _buildEmailInviteField(),
              _buildEmailRecommendations(),
              _buildInvitedList(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInviteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Notify Emails (Opsional)",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailInputController,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                cursorColor: AppColors.schneiderGreen,
                onFieldSubmitted: (_) => _addEmailToList(),
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
                decoration: InputDecoration(
                  hintText: 'Tambahkan email lalu tekan "Add"',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.grayLight)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.grayLight)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.schneiderGreen)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addEmailToList,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.schneiderGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text("Add",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvitedList() {
    if (_notifyEmails.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Akan dinotifikasi",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: AppColors.gray)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.grayLight)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _notifyEmails.length,
              itemBuilder: (context, index) {
                final email = _notifyEmails[index];
                final initials = (email.split('@').first.length >= 2
                        ? email.split('@').first.substring(0, 2)
                        : email.split('@').first)
                    .toUpperCase();
                final color =
                    _userAvatarColors[index % _userAvatarColors.length];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: color,
                        child: Text(initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w400)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(email,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w300)),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _notifyEmails.removeAt(index)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text("Remove",
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w400)),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.grayLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailRecommendations() {
    if (_isLoadingRecommendations) {
      return Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[100]!,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
                3,
                (_) => Container(
                    width: 150,
                    height: 32,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16)))),
          ),
        ),
      );
    }

    final availableRecommendations = _recommendedEmails
        .where((email) => !_notifyEmails.contains(email))
        .toList();
    if (availableRecommendations.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableRecommendations.map((email) {
              return ActionChip(
                onPressed: () => _addRecommendedEmail(email),
                backgroundColor: AppColors.grayLight,
                side: const BorderSide(color: Colors.transparent),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none),
                avatar: const Icon(Icons.add,
                    size: 16, color: AppColors.schneiderGreen),
                label: Text(email,
                    style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w300)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueTitleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Root Cause",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
        const SizedBox(height: 12),
        if (_isLoadingTitles)
          _buildLoadingSkeleton()
        else
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: [
              ..._issueTitleOptions.map((option) {
                final String title = option['title'] as String;
                return _buildOptionButton(
                  label: title,
                  selected: _selectedTitle == title,
                  onTap: () => setState(() => _selectedTitle = title),
                  onEdit: _isAdmin ? () => _showEditTitleSheet(option) : null,
                );
              }),
              if (_isAdmin) _buildOtherButton(onTap: _showAddTitleSheet),
            ],
          ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Wrap(
        spacing: 8,
        runSpacing: 12,
        children: List.generate(4, (index) {
          final double width =
              (index % 3 == 0) ? 150 : (index % 2 == 0) ? 120 : 100;
          return Container(
              width: width,
              height: 42,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(8)));
        }),
      ),
    );
  }

  Widget _buildOtherButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.grayLight),
            borderRadius: BorderRadius.circular(8)),
        child: const Text("Tambah Lainnya...",
            style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: AppColors.gray)),
      ),
    );
  }

  Widget _buildOptionButton(
      {required String label,
      required bool selected,
      required VoidCallback onTap,
      VoidCallback? onEdit}) {
    final Color borderColor =
        selected ? AppColors.schneiderGreen : AppColors.grayLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.schneiderGreen.withOpacity(0.08) : Colors.white,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: AppColors.black)),
            if (onEdit != null)
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.only(left: 8.0, top: 4, bottom: 4, right: 2),
                  child: Icon(Icons.edit,
                      size: 16, color: AppColors.schneiderGreen),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedDescriptionPhotoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Deskripsi (Opsional)",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grayLight)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 5,
                cursorColor: AppColors.schneiderGreen,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
                decoration: const InputDecoration(
                    hintText: 'Masukkan Deskripsi',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_selectedImages.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      _showFullScreenImage(_selectedImages[index]),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(_selectedImages[index],
                                        width: 60, height: 60, fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withOpacity(0.6)),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(left: 8),
                      child: const Center(
                          child: Icon(Icons.add,
                              color: AppColors.gray, size: 26)),
                    ),
                  ),
                ],
              ),
            ],
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
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text("Batal",
                style: TextStyle(
                    color: AppColors.schneiderGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w400)),
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
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text("Simpan", style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }
}

class _AddNewIssueTitleSheet extends StatefulWidget {
  const _AddNewIssueTitleSheet();
  @override
  State<_AddNewIssueTitleSheet> createState() => _AddNewIssueTitleSheetState();
}

class _AddNewIssueTitleSheetState extends State<_AddNewIssueTitleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await DatabaseHelper.instance.createIssueTitle(_titleController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Root cause baru berhasil ditambahkan.'),
            backgroundColor: AppColors.schneiderGreen));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                        borderRadius: BorderRadius.circular(100)))),
            const SizedBox(height: 24),
            const Text("Tambah Root Cause Baru",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              autofocus: true,
              cursorColor: AppColors.schneiderGreen,
              decoration: InputDecoration(
                labelText: 'Nama Root Cause',
                labelStyle: const TextStyle(color: AppColors.gray),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.grayLight)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.grayLight)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.schneiderGreen)),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side:
                                const BorderSide(color: AppColors.schneiderGreen),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6))),
                        child: const Text("Batal",
                            style: TextStyle(
                                color: AppColors.schneiderGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w400)))),
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
                                borderRadius: BorderRadius.circular(6))),
                        child: _isSaving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text("Simpan"))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditIssueTitleSheet extends StatefulWidget {
  final Map<String, dynamic> titleData;
  const _EditIssueTitleSheet({required this.titleData});
  @override
  State<_EditIssueTitleSheet> createState() => _EditIssueTitleSheetState();
}

class _EditIssueTitleSheetState extends State<_EditIssueTitleSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final int _titleId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleId = widget.titleData['id'] as int;
    _titleController =
        TextEditingController(text: widget.titleData['title'] as String);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await DatabaseHelper.instance
          .updateIssueTitle(_titleId, _titleController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Root cause berhasil diperbarui.'),
            backgroundColor: AppColors.schneiderGreen));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) =>
          _DeleteTitleConfirmationSheet(titleName: widget.titleData['title'] as String),
    );
    if (confirm != true) return;
    try {
      await DatabaseHelper.instance.deleteIssueTitle(_titleId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Root cause berhasil dihapus.'),
            backgroundColor: AppColors.schneiderGreen));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                        borderRadius: BorderRadius.circular(100)))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Edit Root Cause",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.red),
                    onPressed: _delete,
                    tooltip: 'Hapus Root Cause'),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              autofocus: true,
              cursorColor: AppColors.schneiderGreen,
              decoration: InputDecoration(
                labelText: 'Nama Root Cause',
                labelStyle: const TextStyle(color: AppColors.gray),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.grayLight)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.grayLight)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.schneiderGreen)),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side:
                                const BorderSide(color: AppColors.schneiderGreen),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6))),
                        child: const Text("Batal",
                            style: TextStyle(
                                color: AppColors.schneiderGreen,
                                fontWeight: FontWeight.w400,
                                fontSize: 12)))),
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
                                borderRadius: BorderRadius.circular(6))),
                        child: _isSaving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text("Simpan Perubahan",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400)))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteTitleConfirmationSheet extends StatelessWidget {
  final String titleName;
  const _DeleteTitleConfirmationSheet({required this.titleName});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                      borderRadius: BorderRadius.circular(100)))),
          const SizedBox(height: 24),
          const Text("Hapus Root Cause?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
              "Anda yakin ingin menghapus root cause \"$titleName\"? Tindakan ini tidak dapat diurungkan.",
              style: const TextStyle(color: AppColors.gray, fontSize: 14)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side:
                              const BorderSide(color: AppColors.schneiderGreen),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6))),
                      child: const Text("Batal",
                          style: TextStyle(
                              color: AppColors.schneiderGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w400)))),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6))),
                      child: const Text("Ya, Hapus",
                          style: TextStyle(fontSize: 12)))),
            ],
          ),
        ],
      ),
    );
  }
}