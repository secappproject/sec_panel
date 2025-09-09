import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secpanel/components/issue/issue_chat/issue_comment_sheet.dart';
import 'package:secpanel/components/issue/issue_detail/issue_detail.dart';
import 'package:secpanel/components/issue/panel_issue_screen.dart';
import 'package:secpanel/components/issue/photo_viewer.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/issue.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IssueCard extends StatefulWidget {
  final IssueWithPhotos issue;
  final VoidCallback onUpdate;

  const IssueCard({super.key, required this.issue, required this.onUpdate});

  @override
  State<IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<IssueCard> {
  late bool _isSolved;

  final Map<String, Map<String, dynamic>> _actionDetailsMap = {
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

  @override
  void initState() {
    super.initState();
    _isSolved = widget.issue.status == 'solved';
  }

  @override
  void didUpdateWidget(covariant IssueCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.issue.status != oldWidget.issue.status) {
      setState(() {
        _isSolved = widget.issue.status == 'solved';
      });
    }
  }

  Future<void> _toggleSolvedStatus() async {
    if (widget.issue == null) return;
    final newStatus = _isSolved ? 'unsolved' : 'solved';

    setState(() => _isSolved = !_isSolved); // Optimistic UI

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('loggedInUsername') ?? 'unknown_user';
      final issueData = {
        'issue_title': widget.issue!.title,
        'issue_description': widget.issue!.description,
        'issue_status': newStatus,
        'updated_by': username,
      };

      await DatabaseHelper.instance.updateIssue(widget.issue!.id, issueData);
      widget.onUpdate();
    } catch (e) {
      setState(() => _isSolved = !_isSolved); // Revert on error
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
          photos: widget.issue.photos,
          initialIndex: initialIndex,
        ),
      ),
    );
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
          border: Border.all(width: 1, color: AppColors.grayLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
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
                  child: Text(
                    user.avatarInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: actionDetails['color'] as Color,
                    child: Image.asset(actionDetails['icon'] as String),
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
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                    children: [
                      TextSpan(
                        text: '${user.name} ',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: actionText,
                        style: const TextStyle(
                          color: AppColors.gray,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimestamp(log.timestamp),
                  style: const TextStyle(
                    color: AppColors.gray,
                    fontWeight: FontWeight.w300,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusIcon(),
        ],
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
          Text(
            widget.issue.title,
            style: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          if (widget.issue.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.issue.description,
              style: const TextStyle(
                color: AppColors.gray,
                fontSize: 12,
                fontWeight: FontWeight.w300,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    final photosToShow = widget.issue.photos.take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
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
              childAspectRatio: itemWidth / itemHeight,
            ),
            itemCount: photosToShow.length,
            itemBuilder: (context, index) {
              if (index == 3 && widget.issue.photos.length > 4) {
                return _buildMorePhotosIndicator(index, itemHeight);
              }
              return _buildPhotoItem(index, itemHeight);
            },
          );
        },
      ),
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
                child: child,
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.grayLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.broken_image, color: AppColors.gray),
              );
            },
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
                  child: Text(
                    '+$remainingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
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
                // Make this async
                // Get username from SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                final username = prefs.getString('loggedInUsername');

                // Get the full User object
                // We assume the username is the ID and also the name for simplicity here.
                // In a real app, you might fetch the full User profile.
                if (username != null && mounted) {
                  final currentUser = User(id: username, name: username);

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => IssueCommentSheet(
                      issue: widget.issue,
                      onUpdate: widget.onUpdate,
                      currentUser: currentUser,
                    ),
                  );
                } else {
                  // Handle case where user is not logged in
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error: Not logged in.")),
                  );
                }
              },
              label: 'Comment',
              icon: Image.asset(
                'assets/images/message.png',
                color: AppColors.schneiderGreen,
                width: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStyledButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => IssueDetailBottomSheet(
                    issueId: widget.issue.id,
                    onUpdate: widget.onUpdate,
                  ),
                );
              },
              label: 'See Detail',
              icon: const Icon(
                Icons.north_east,
                color: AppColors.schneiderGreen,
                size: 14,
              ),
            ),
          ),
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
            _isSolved ? 'assets/images/check.png' : 'assets/images/uncheck.png',
            height: 36,
          ),
          const SizedBox(height: 2),
          Text(
            _isSolved ? 'Solved' : '',
            style: TextStyle(
              color: _isSolved ? AppColors.schneiderGreen : AppColors.gray,
              fontWeight: FontWeight.w400,
              fontSize: 10,
            ),
          ),
        ],
      ),
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
}
