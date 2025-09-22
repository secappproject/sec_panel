// issue_card.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:secpanel/components/issue/issue_chat/issue_comment_sheet.dart';
import 'package:secpanel/components/issue/issue_detail/issue_detail.dart';
import 'package:secpanel/components/issue/panel_issue_screen.dart';
import 'package:secpanel/components/issue/photo_viewer.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/issue.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class IssueCard extends StatefulWidget {
  final IssueWithPhotos issue;
  final String panelNoPp; // ▼▼▼ [PERBAIKAN] Tambahkan properti ini
  final VoidCallback onUpdate;

  const IssueCard({
    super.key,
    required this.issue,
    required this.panelNoPp, // ▼▼▼ [PERBAIKAN] Jadikan required
    required this.onUpdate,
  });

  @override
  State<IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<IssueCard> {
  late bool _isSolved;

  static const List<Color> _userAvatarColors = [
    Color(0xFFFF5DD1),
    Color(0xFF0400FF),
    Color(0xFF00B2FF),
    Color(0xFFFF9E50),
    Color(0xFFFF0000),
  ];

  final Map<String, Map<String, dynamic>> _actionDetailsMap = {
    'membuat issue': {
      'icon': 'assets/images/create-issue.png',
      'color': const Color(0xFF1A73E8)
    },
    'menandai solved': {
      'icon': 'assets/images/solve-issue.png',
      'color': AppColors.schneiderGreen
    },
    'mengubah issue': {
      'icon': 'assets/images/edit-issue.png',
      'color': const Color(0xFF5F6368)
    },
    'membuka kembali issue': {
      'icon': 'assets/images/reopen-issue.png',
      'color': const Color(0xFFFBBC04)
    },
    'mengubah daftar notifikasi': {
      'icon': 'assets/images/mail-config.png',
      'color': const Color(0xFF9AA0A6)
    },
  };

  @override
  void initState() {
    super.initState();
    _isSolved = widget.issue.status == 'solved';
  }

  @override
  void didUpdateWidget(covariant IssueCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.issue.status != oldWidget.issue.status) {
      setState(() => _isSolved = widget.issue.status == 'solved');
    }
  }

  void _showManageNotificationsDialog(
      BuildContext context, List<String> emails) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double mobileBreakpoint = 600.0;

    // ▼▼▼ [PERBAIKAN] Teruskan panelNoPp ke ManageNotificationsSheet ▼▼▼
    final manageSheetWidget = ManageNotificationsSheet(
      issue: widget.issue,
      initialEmails: emails,
      onUpdate: widget.onUpdate,
      panelNoPp: widget.panelNoPp,
    );
    // ▲▲▲ [AKHIR PERBAIKAN] ▲▲▲

    if (screenWidth < mobileBreakpoint) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => manageSheetWidget,
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
              child: manageSheetWidget,
            ),
          );
        },
      );
    }
  }

  Future<void> _toggleSolvedStatus() async {
    final newStatus = _isSolved ? 'unsolved' : 'solved';
    setState(() => _isSolved = !_isSolved);
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('loggedInUsername') ?? 'unknown_user';
      final issueData = {
        'issue_title': widget.issue.title,
        'issue_description': widget.issue.description,
        'issue_status': newStatus,
        'updated_by': username,
        'notify_email': widget.issue.notifyEmail ?? '',
      };
      await DatabaseHelper.instance.updateIssue(widget.issue.id, issueData);
      widget.onUpdate();
    } catch (e) {
      setState(() => _isSolved = !_isSolved);
      PanelIssuesScreen.showSnackBar('Gagal update status: $e', isError: true);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays > 0) return '${difference.inDays} hari lalu';
    if (difference.inHours > 0) return '${difference.inHours} jam lalu';
    if (difference.inMinutes > 0) return '${difference.inMinutes} menit lalu';
    return 'Baru saja';
  }

  void _openPhotoViewer(BuildContext context, {int initialIndex = 0}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PhotoViewerScreen(
                photos: widget.issue.photos, initialIndex: initialIndex)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.all(width: 1, color: AppColors.grayLight)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildNotifyChips(),
            _buildContent(),
            if (widget.issue.photos.isNotEmpty) _buildPhotoGrid(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final log = widget.issue.lastLog;
    final user = log.user;
    final actionText = log.action.toLowerCase();
    final actionDetails =
        _actionDetailsMap[actionText] ?? _actionDetailsMap['mengubah issue']!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                    backgroundColor: user.avatarColor,
                    radius: 20,
                    child: Text(user.avatarInitials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14))),
                Positioned(
                    right: -2,
                    bottom: -2,
                    child: CircleAvatar(
                        radius: 10,
                        backgroundColor: actionDetails['color'] as Color,
                        child: Image.asset(actionDetails['icon'] as String))),
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
                            fontWeight: FontWeight.w300,
                            fontSize: 12,
                            fontFamily: 'Lexend'),
                        children: [
                      TextSpan(
                          text: '${user.name} ',
                          style: const TextStyle(fontWeight: FontWeight.w400)),
                      TextSpan(
                          text: actionText,
                          style: const TextStyle(
                              color: AppColors.gray,
                              fontWeight: FontWeight.w300)),
                    ])),
                const SizedBox(height: 2),
                Text(_formatTimestamp(log.timestamp),
                    style: const TextStyle(
                        color: AppColors.gray,
                        fontWeight: FontWeight.w300,
                        fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusIcon(),
        ],
      ),
    );
  }

  Widget _buildNotifyChips() {
    final String notifyEmail = widget.issue.notifyEmail ?? '';
    final emails =
        notifyEmail.split(',').where((e) => e.trim().isNotEmpty).toList();
    const double avatarRadius = 15;
    const double overlap = 6;
    const int maxVisibleUsers = 2;
    List<Widget> avatarWidgets = [];

    if (emails.isNotEmpty) {
      final int usersToShow =
          emails.length > maxVisibleUsers ? maxVisibleUsers : emails.length;
      for (int i = 0; i < usersToShow; i++) {
        final email = emails[i];
        final initials = (email.split('@').first.length >= 2
                ? email.split('@').first.substring(0, 2)
                : email.split('@').first)
            .toUpperCase();
        final color = _userAvatarColors[i % _userAvatarColors.length];
        avatarWidgets.add(Positioned(
            left: i * (avatarRadius * 2 - overlap),
            child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: color,
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w400)))));
      }
      if (emails.length > maxVisibleUsers) {
        avatarWidgets.add(Positioned(
            left: usersToShow * (avatarRadius * 2 - overlap),
            child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.white,
                child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1)),
                    child: const Center(
                        child:
                            Icon(Icons.add, size: 14, color: Colors.black54))))));
      }
    }

    final int totalVisibleItems = avatarWidgets.length;
    final double stackWidth = totalVisibleItems > 0
        ? (totalVisibleItems * (avatarRadius * 2 - overlap)) + overlap
        : 0;

    final systemChip = GestureDetector(
      onTap: () => _showManageNotificationsDialog(context, emails),
      child: CircleAvatar(
          radius: avatarRadius,
          backgroundColor: Colors.grey.shade200,
          child: Image.asset("assets/images/mail-config.png")),
    );

    final addChip = GestureDetector(
      onTap: () => _showManageNotificationsDialog(context, emails),
      child: CircleAvatar(
          radius: avatarRadius,
          backgroundColor: Colors.grey.shade100,
          child: const Icon(Icons.add, size: 16, color: Colors.black54)),
    );

    return GestureDetector(
      onTap: () => _showManageNotificationsDialog(context, emails),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200, width: 1.5)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emails.isNotEmpty) ...[
                SizedBox(
                    width: stackWidth,
                    height: avatarRadius * 2,
                    child: Stack(children: avatarWidgets)),
                const SizedBox(width: 8),
              ] else ...[
                addChip,
                const SizedBox(width: 8),
              ],
              systemChip,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.issue.title,
              style: const TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 16)),
          if (widget.issue.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(widget.issue.description,
                style: const TextStyle(
                    color: AppColors.gray,
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    final photosToShow = widget.issue.photos.take(4).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: LayoutBuilder(builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - 8) / 2;
        final double itemHeight = itemWidth * 0.8;
        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: itemWidth / itemHeight),
          itemCount: photosToShow.length,
          itemBuilder: (context, index) {
            if (index == 3 && widget.issue.photos.length > 4) {
              return _buildMorePhotosIndicator(index, itemHeight);
            }
            return _buildPhotoItem(index, itemHeight);
          },
        );
      }),
    );
  }

  Widget _buildPhotoItem(int index, double height) {
    final photo = widget.issue.photos[index];
    final imageBytes = base64Decode(photo.photoData);
    return GestureDetector(
      onTap: () => _openPhotoViewer(context, initialIndex: index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Hero(
          tag: photo.id,
          child: Image.memory(
            imageBytes,
            height: height,
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  child: child);
            },
            errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                    color: AppColors.grayLight,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.broken_image, color: AppColors.gray)),
          ),
        ),
      ),
    );
  }

  Widget _buildMorePhotosIndicator(int index, double height) {
    final photo = widget.issue.photos[index];
    final imageBytes = base64Decode(photo.photoData);
    final remainingCount = widget.issue.photos.length - 4;
    return GestureDetector(
      onTap: () => _openPhotoViewer(context, initialIndex: index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Hero(
          tag: photo.id,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(imageBytes, height: height, fit: BoxFit.cover),
              Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Center(
                      child: Text('+$remainingCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w400)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Expanded(
              child: _buildStyledButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final username = prefs.getString('loggedInUsername');
                    if (username != null && mounted) {
                      final currentUser = User(id: username, name: username);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => IssueCommentSheet(
                            issue: widget.issue,
                            onUpdate: widget.onUpdate,
                            currentUser: currentUser),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Error: Not logged in.")));
                    }
                  },
                  label: 'Comment',
                  icon: Image.asset('assets/images/message.png',
                      color: AppColors.schneiderGreen, width: 14))),
          const SizedBox(width: 12),
          Expanded(
              child: _buildStyledButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => IssueDetailBottomSheet(
                          issueId: widget.issue.id, onUpdate: widget.onUpdate),
                    );
                  },
                  label: 'See Detail',
                  icon: const Icon(Icons.north_east,
                      color: AppColors.schneiderGreen, size: 14))),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    return GestureDetector(
      onTap: _toggleSolvedStatus,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
              _isSolved
                  ? 'assets/images/check.png'
                  : 'assets/images/uncheck.png',
              height: 36),
          const SizedBox(height: 2),
          Text(_isSolved ? 'Solved' : '',
              style: TextStyle(
                  color: _isSolved
                      ? AppColors.schneiderGreen
                      : AppColors.gray,
                  fontWeight: FontWeight.w400,
                  fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildStyledButton(
      {required VoidCallback onPressed,
      required String label,
      required Widget icon}) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.grayLight),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          splashFactory: NoSplash.splashFactory,
          elevation: 0,
        ).copyWith(
            overlayColor: MaterialStateProperty.all(Colors.transparent)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w400,
                    fontSize: 12)),
            const SizedBox(width: 8),
            icon,
          ],
        ),
      ),
    );
  }
}

// =======================================================================
// MANAGE NOTIFICATIONS SHEET
// =======================================================================

class ManageNotificationsSheet extends StatefulWidget {
  final IssueWithPhotos issue;
  final String panelNoPp; // ▼▼▼ [PERBAIKAN] Tambahkan properti ini
  final List<String> initialEmails;
  final VoidCallback onUpdate;

  const ManageNotificationsSheet(
      {super.key,
      required this.issue,
      required this.panelNoPp, // ▼▼▼ [PERBAIKAN] Jadikan required
      required this.initialEmails,
      required this.onUpdate});

  @override
  State<ManageNotificationsSheet> createState() =>
      _ManageNotificationsSheetState();
}

class _ManageNotificationsSheetState extends State<ManageNotificationsSheet> {
  late List<String> _notifyEmails;
  final _emailInputController = TextEditingController();
  final _emailFocusNode = FocusNode();

  List<String> _recommendedEmails = [];
  bool _isLoadingRecommendations = true;

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
    _notifyEmails = List.from(widget.initialEmails);
    _loadRecommendedEmails();
  }

  @override
  void dispose() {
    _emailInputController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  // ▼▼▼ [PERBAIKAN LOGIKA] Mengambil rekomendasi berdasarkan panelNoPp ▼▼▼
  Future<void> _loadRecommendedEmails() async {
    if (!mounted) return;
    setState(() => _isLoadingRecommendations = true);
    try {
      final emails = await DatabaseHelper.instance
          .getEmailRecommendations(panelNoPp: widget.panelNoPp);
      if (mounted) {
        setState(() {
          // Filter email yang sudah ada di daftar notifikasi saat ini
          _recommendedEmails = emails
              .where((rec) => !_notifyEmails.contains(rec))
              .toList();
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat rekomendasi email dari BE: $e");
      if (mounted) setState(() => _isLoadingRecommendations = false);
    }
  }
  // ▲▲▲ [AKHIR PERBAIKAN] ▲▲▲

  Future<void> _updateEmailsOnBackend({String? successMessage}) async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('loggedInUsername') ?? 'unknown_user';
      final emailsString = _notifyEmails.join(',');

      final issueData = {
        'issue_title': widget.issue.title,
        'issue_description': widget.issue.description,
        'issue_status': widget.issue.status,
        'updated_by': username,
        'notify_email': emailsString,
      };

      await DatabaseHelper.instance.updateIssue(widget.issue.id, issueData);

      widget.onUpdate();

      if (mounted && successMessage != null) {
        PanelIssuesScreen.showSnackBar(successMessage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menyimpan: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
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
      _updateEmailsOnBackend(successMessage: '$email berhasil ditambahkan.');
    }
    _emailFocusNode.requestFocus();
  }

  void _addRecommendedEmail(String email) {
    if (!_notifyEmails.contains(email)) {
      setState(() {
        _notifyEmails.add(email);
        _recommendedEmails.remove(email); // Hapus dari rekomendasi
      });
      _updateEmailsOnBackend(successMessage: '$email berhasil ditambahkan.');
    }
  }

  void _removeEmail(int index) {
    if (!mounted) return;
    final removedEmail = _notifyEmails[index];
    setState(() {
      _notifyEmails.removeAt(index);
    });
    _updateEmailsOnBackend(successMessage: '$removedEmail berhasil dihapus.');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Notify Emails",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.gray),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          _buildEmailInviteField(),
          _buildEmailRecommendations(),
          Flexible(
            child: SingleChildScrollView(
              child: _buildInvitedList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmailInviteField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _emailInputController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            cursorColor: AppColors.schneiderGreen,
            onFieldSubmitted: (_) => _addEmailToList(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
            decoration: InputDecoration(
              hintText: 'Emails, comma separated',
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
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
          child: const Text("Add",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
        ),
      ],
    );
  }

  Widget _buildInvitedList() {
    if (_notifyEmails.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Who has access",
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
                                  fontWeight: FontWeight.w400))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(email,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300))),
                      TextButton(
                        onPressed: () => _removeEmail(index),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade400,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
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
    if (_recommendedEmails.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recommendedEmails.map((email) {
              return ActionChip(
                onPressed: () => _addRecommendedEmail(email),
                backgroundColor: AppColors.grayLight,
                side: BorderSide.none,
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
}