import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secpanel/components/issue/issue_detail/delete_issue.dart';
import 'package:secpanel/components/issue/issue_detail/issue_detail_card_skeleton.dart';
import 'package:secpanel/components/issue/issue_detail/issue_form_bottom_sheet.dart';
import 'package:secpanel/components/issue/panel_issue_screen.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/issue.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IssueDetailCard extends StatefulWidget {
  final int issueId;
  final VoidCallback onUpdate;
  final BuildContext scaffoldContext;

  const IssueDetailCard({
    super.key,
    required this.issueId,
    required this.onUpdate,
    required this.scaffoldContext,
  });

  @override
  State<IssueDetailCard> createState() => _IssueDetailCardState();
}

class _IssueDetailCardState extends State<IssueDetailCard> {
  IssueWithPhotos? _issue;
  bool _isLoading = true;
  String? _errorMessage;
  late bool _isSolved;

  @override
  void initState() {
    super.initState();
    _loadIssueDetails();
  }

  Future<void> _loadIssueDetails() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final issueDetails = await DatabaseHelper.instance.getIssueById(
        widget.issueId,
      );
      if (mounted) {
        setState(() {
          _issue = issueDetails;
          _isSolved = _issue!.status == 'solved';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat detail isu: $e";
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteConfirmation() {
    Navigator.pop(context); // Close the detail bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DeleteConfirmationBottomSheet(
        issueTitle: _issue!.title,
        onConfirmDelete: () async {
          Navigator.pop(ctx); // Close the confirmation sheet
          try {
            await DatabaseHelper.instance.deleteIssue(_issue!.id);
            PanelIssuesScreen.showSnackBar('Issue berhasil dihapus.');
            widget.onUpdate(); // Refresh the main list
          } catch (e) {
            PanelIssuesScreen.showSnackBar(
              'Gagal menghapus isu: $e',
              isError: true,
            );
          }
        },
      ),
    );
  }

  Future<void> _toggleSolvedStatus() async {
    if (_issue == null) return;
    final newStatus = _isSolved ? 'unsolved' : 'solved';

    setState(() => _isSolved = !_isSolved); // Optimistic UI

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('loggedInUsername') ?? 'unknown_user';
      final issueData = {
        'issue_title': _issue!.title,
        'issue_description': _issue!.description,
        'issue_status': newStatus,
        'updated_by': username,
      };

      await DatabaseHelper.instance.updateIssue(_issue!.id, issueData);
      widget.onUpdate();
    } catch (e) {
      setState(() => _isSolved = !_isSolved); // Revert on error
      PanelIssuesScreen.showSnackBar('Gagal update status: $e', isError: true);
    }
  }

  void _showFullScreenImage(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Image.memory(imageBytes, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const IssueDetailCardSkeleton();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildActionButtons(),
          const SizedBox(height: 24),
          _buildDetails(),
          if (_issue!.photos.isNotEmpty) const SizedBox(height: 16),
          if (_issue!.photos.isNotEmpty) _buildPhotos(),
          const SizedBox(height: 24),
          _buildActivityLog(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final creator = _issue!.logs.isNotEmpty
        ? _issue!.logs.first.user
        : User(id: _issue!.createdBy, name: _issue!.createdBy);
    final actionDetails = _getActionDetails('membuat issue');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                backgroundColor: creator.avatarColor,
                radius: 20,
                child: Text(
                  creator.avatarInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -2,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: actionDetails['color'],
                  child: SizedBox(child: Image.asset(actionDetails['icon'])),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _issue!.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.gray,
                    fontFamily: 'Poppins',
                  ),
                  children: [
                    const TextSpan(text: 'dibuat oleh '),
                    TextSpan(
                      text: creator.name,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _toggleSolvedStatus,
              child: Image.asset(
                _isSolved
                    ? 'assets/images/check.png'
                    : 'assets/images/uncheck.png',
                height: 40,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isSolved ? 'Solved' : '',
              style: TextStyle(
                color: _isSolved ? AppColors.schneiderGreen : AppColors.gray,
                fontWeight: FontWeight.w400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildStyledButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                builder: (ctx) => IssueFormBottomSheet(
                  onIssueSaved: () {
                    Navigator.pop(ctx);
                    _loadIssueDetails();
                    widget.onUpdate();
                    PanelIssuesScreen.showSnackBar(
                      'Issue berhasil diperbarui!',
                    );
                  },
                  existingIssue: _issue!,
                ),
              );
            },
            label: 'Edit',
            icon: Image.asset('assets/images/edit-green.png', height: 16),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStyledButton(
            onPressed: _showDeleteConfirmation,
            label: 'Delete',
            icon: Image.asset('assets/images/trash.png', height: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          "Tentang Isu",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.black,
            height: 1.5,
          ),
        ),
        Text(
          _issue!.description != ''
              ? _issue!.description
              : 'Tidak ada deskripsi yang diberikan.',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w300,
            color: AppColors.gray,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotos() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _issue!.photos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final photo = _issue!.photos[index];
          final imageBytes = base64Decode(photo.photoData);
          return GestureDetector(
            onTap: () => _showFullScreenImage(imageBytes),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grayLight, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.memory(imageBytes, fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityLog() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grayLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Log Aktivitas',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.black,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Divider(color: AppColors.grayLight, height: 1, thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              children: _issue!.logs.map((log) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _buildActivityLogRow(log),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogRow(LogEntry log) {
    final actionDetails = _getActionDetails(log.action);
    final formattedDate = DateFormat(
      'dd MMM yyyy, HH:mm',
    ).format(log.timestamp);
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                backgroundColor: log.user.avatarColor,
                radius: 18,
                child: Text(
                  log.user.avatarInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -1,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: actionDetails['color'],
                  child: SizedBox(child: Image.asset(actionDetails['icon'])),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                  children: [
                    TextSpan(
                      text: '${log.user.name} ',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    TextSpan(
                      text: log.action.toLowerCase(),
                      style: const TextStyle(color: AppColors.gray),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  color: AppColors.gray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStyledButton({
    required VoidCallback onPressed,
    required String label,
    required Widget icon,
  }) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.grayLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          splashFactory: NoSplash.splashFactory,
          elevation: 0,
        ).copyWith(overlayColor: WidgetStateProperty.all(Colors.transparent)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            icon,
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getActionDetails(String action) {
    final Map<String, Map<String, dynamic>> actionMap = {
      'membuat issue': {
        'icon': 'assets/images/create-issue.png',
        'color': const Color(0xFF1A73E8),
      },
      'menandai solved': {
        'icon': 'assets/images/solve-issue.png',
        'color': AppColors.schneiderGreen,
      },
      'mengubah issue': {
        'icon': 'assets/images/edit-issue.png',
        'color': const Color(0xFF5F6368),
      },
      'membuka kembali issue': {
        'icon': 'assets/images/reopen-issue.png',
        'color': const Color(0xFFFBBC04),
      },
    };
    return actionMap[action.toLowerCase()] ?? actionMap['mengubah issue']!;
  }
}
