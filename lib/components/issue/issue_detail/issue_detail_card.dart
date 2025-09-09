import 'package:flutter/material.dart';
import 'package:secpanel/components/issue/issue_detail/delete_issue.dart';
import 'package:secpanel/components/issue/issue_detail/issue_form_bottom_sheet.dart';
import 'package:secpanel/components/issue/panel_issue_screen.dart';
import 'package:secpanel/models/issuetest.dart';
import 'package:secpanel/theme/colors.dart';

class IssueDetailCard extends StatefulWidget {
  final Issue issue;
  final BuildContext scaffoldContext;

  const IssueDetailCard({
    super.key,
    required this.issue,
    required this.scaffoldContext,
  });

  @override
  State<IssueDetailCard> createState() => _IssueDetailCardState();
}

class _IssueDetailCardState extends State<IssueDetailCard> {
  late bool isSolved;
  late final List<LogEntry> activityLogs;

  @override
  void initState() {
    super.initState();
    isSolved = widget.issue.status == 'solved';
    activityLogs = [
      LogEntry(
        user: admin,
        action: 'membuat issue',
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
      ),
      LogEntry(
        user: abacusUser,
        action: 'mengubah issue',
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
      ),
      LogEntry(
        user: admin,
        action: 'menandai solved',
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];
  }

  void _showFullScreenImage(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 16),
          _buildPhotos(),
          const SizedBox(height: 24),
          _buildActivityLog(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final creator = widget.issue.lastLog.user;
    final actionDetails = _getActionDetails(
      'membuat issue',
    ); // Icon untuk header adalah 'create'

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
                widget.issue.title,
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
              onTap: () => setState(() => isSolved = !isSolved),
              child: Image.asset(
                isSolved
                    ? 'assets/images/check.png'
                    : 'assets/images/uncheck.png',
                height: 40,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isSolved ? 'Solved' : '',
              style: TextStyle(
                color: isSolved ? AppColors.schneiderGreen : AppColors.gray,
                fontWeight: FontWeight.w400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    // Tutup dulu bottom sheet detail saat ini
    Navigator.pop(context);

    // Tampilkan bottom sheet konfirmasi delete
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DeleteConfirmationBottomSheet(
        issueTitle: widget.issue.title,
        onConfirmDelete: () {
          // Tutup bottom sheet konfirmasi
          Navigator.pop(ctx);

          // Tampilkan notifikasi sukses
          scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Issue berhasil dihapus.'),
              backgroundColor: AppColors.schneiderGreen,
            ),
          );

          // Di sini Anda bisa menambahkan logika untuk refresh daftar isu utama
          print('Issue ${widget.issue.title} dihapus. Muat ulang data...');
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildStyledButton(
            onPressed: () {
              showModalBottomSheet(
                context:
                    context, // Gunakan context lokal untuk menampilkan sheet ini
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) {
                  return IssueFormBottomSheet(
                    panelNoPp: "DUMMY-PNL-01",
                    onIssueSaved: () {
                      // --- PERUBAHAN: Gunakan scaffoldContext yang sudah dioper ---
                      ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
                        const SnackBar(
                          content: Text('Issue berhasil diperbarui!'),
                          backgroundColor: AppColors.schneiderGreen,
                        ),
                      );
                      setState(() {});
                    },
                    existingIssue: widget.issue,
                  );
                },
              );
            },
            label: 'Edit',
            icon: Image.asset('assets/images/edit-green.png', height: 16),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStyledButton(
            // --- PERUBAHAN: Panggil fungsi konfirmasi delete ---
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        const SizedBox(height: 12),
        Text(
          widget.issue.description * 5,
          style: TextStyle(
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
    final List<String> photos = [
      'assets/images/send.png',
      'assets/images/message.png',
    ];
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showFullScreenImage(photos[index]),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grayLight, width: 1),
              ),
              child: ClipRRect(
                // BorderRadius sedikit lebih kecil dari container agar border tidak terpotong
                borderRadius: BorderRadius.circular(11),
                child: Image.asset(photos[index], fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- MODIFIKASI: Struktur Log Aktivitas diubah total ---
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
          // Menggunakan Column untuk menampilkan daftar log
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              children: activityLogs.map((log) {
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

  // Helper widget baru untuk satu baris log
  Widget _buildActivityLogRow(LogEntry log) {
    final actionDetails = _getActionDetails(log.action);
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
          child: RichText(
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
        ),
        SizedBox(width: 4),
        Text(
          '4 hari lalu',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w300,
            color: AppColors.gray,
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
          overlayColor: Colors.transparent,
          elevation: 0,
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
    };
    return actionMap[action.toLowerCase()] ??
        {
          'icon': 'assets/images/edit-issue.png',
          'color': const Color(0xFF5F6368),
        };
  }
}
