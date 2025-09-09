// lib/components/issue/issue_card.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:secpanel/models/issuetest.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secpanel/components/issue/issue_chat/chat.dart'; // Make sure this path is correct
import 'package:secpanel/components/issue/issue_detail/issue_detail.dart'; // Make sure this path is correct
import 'package:secpanel/theme/colors.dart'; // Make sure this path is correct

class IssueCard extends StatefulWidget {
  final Issue issue;

  const IssueCard({super.key, required this.issue});

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
  };

  @override
  void initState() {
    super.initState();
    _isSolved = widget.issue.status == 'solved';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) return '${difference.inDays} hari lalu';
    if (difference.inHours > 0) return '${difference.inHours} jam lalu';
    if (difference.inMinutes > 0) return '${difference.inMinutes} menit lalu';
    return 'Baru saja';
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
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildContentWithNotch(context),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final log = widget.issue.lastLog;
    final user = log.user;
    final actionText = log.action.toLowerCase();
    final actionDetails = _actionDetailsMap[actionText];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 45,
            height: 45,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: user.avatarColor,
                  radius: 18,
                  child: Text(
                    user.avatarInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (actionDetails != null)
                  Positioned(
                    right: -2,
                    bottom: -1,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: actionDetails['color'] as Color,
                      child: Image.asset(actionDetails['icon'] as String),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
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
          ),
          const SizedBox(width: 8),
          Text(
            _formatTimestamp(log.timestamp),
            style: const TextStyle(
              color: AppColors.gray,
              fontWeight: FontWeight.w300,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentWithNotch(BuildContext context) {
    const double iconBackgroundRadius = 22.0;
    const double notchCenterY = 30.0;

    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipPath(
          clipper: NotchedCardClipper(
            notchRadius: iconBackgroundRadius,
            notchCenterY: notchCenterY,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    right: iconBackgroundRadius * 2 + 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.issue.title,
                        style: const TextStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.issue.description,
                        style: const TextStyle(
                          color: AppColors.gray,
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.grayLight.withOpacity(0.8),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.issue.type,
                    style: const TextStyle(
                      color: AppColors.gray,
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: notchCenterY - iconBackgroundRadius,
          right: 12,
          child: _buildStatusIcon(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _buildStyledButton(
              // --- AWAL PERUBAHAN ---
              onPressed: () {
                // Hapus semua kode SharedPreferences di sini.
                // Langsung navigasi dengan membawa data issue untuk preview.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IssueChatScreen(
                      // `issue` ini adalah konteks utama dari halaman chat
                      issue: widget.issue,
                      // `initialIssueToForward` adalah issue yang mau kita jadikan preview
                      initialIssueToForward: widget.issue,
                    ),
                  ),
                );
              },
              // --- AKHIR PERUBAHAN ---
              label: 'Send',
              icon: Image.asset(
                'assets/images/send.png',
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
                  builder: (context) =>
                      IssueDetailBottomSheet(issue: widget.issue),
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
      onTap: () => setState(() => _isSolved = !_isSolved),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            _isSolved ? 'assets/images/check.png' : 'assets/images/uncheck.png',
            height: 40,
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
        style:
            OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.grayLight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              // --- FIX UNTUK DEPRECATION WARNING ---
              splashFactory: NoSplash.splashFactory,
              elevation: 0,
            ).copyWith(
              // Gunakan .copyWith untuk overlayColor yang baru
              overlayColor: WidgetStateProperty.all(Colors.transparent),
            ),
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

class NotchedCardClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double notchCenterY;

  NotchedCardClipper({required this.notchRadius, required this.notchCenterY});

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, notchCenterY - notchRadius)
      ..arcToPoint(
        Offset(size.width, notchCenterY + notchRadius),
        radius: Radius.circular(notchRadius),
        clockwise: false,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
