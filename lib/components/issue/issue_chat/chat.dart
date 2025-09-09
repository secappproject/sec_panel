import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secpanel/components/issue/issue_detail/issue_detail.dart';
import 'package:secpanel/models/chatmessage.dart'; // Pastikan path ini benar
import 'package:secpanel/models/issuetest.dart'; // Pastikan path ini benar
import 'package:secpanel/theme/colors.dart'; // Pastikan path ini benar
import 'package:uuid/uuid.dart';

class IssueChatScreen extends StatefulWidget {
  final Issue issue;
  final Issue? initialIssueToForward;

  const IssueChatScreen({
    super.key,
    required this.issue,
    this.initialIssueToForward,
  });

  @override
  State<IssueChatScreen> createState() => _IssueChatScreenState();
}

class _IssueChatScreenState extends State<IssueChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<File> _currentDraftImages = [];
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final Uuid _uuid = const Uuid();
  final User _currentUser = abacusUser; // Asumsi user saat ini

  Issue? _issueToForward;

  @override
  void initState() {
    super.initState();
    _issueToForward = widget.initialIssueToForward;
    // Menambahkan pesan awal atau isu yang sedang dibahas
    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage(
          id: _uuid.v4(),
          sender: widget.issue.lastLog.user,
          timestamp: widget.issue.lastLog.timestamp,
          repliedIssue: widget.issue,
        ),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _currentDraftImages.addAll(
            result.files
                .where((file) => file.path != null)
                .map((file) => File(file.path!)),
          );
        });
      }
    } catch (e) {
      debugPrint("Gagal memilih gambar: $e");
    }
  }

  void _removeImageFromDraft(int index) {
    setState(() {
      _currentDraftImages.removeAt(index);
    });
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty &&
        _currentDraftImages.isEmpty &&
        _issueToForward == null)
      return;

    final List<String> imageUrlsToSend = _currentDraftImages
        .map((file) => file.path)
        .toList();

    final newMessage = ChatMessage(
      id: _uuid.v4(),
      text: _textController.text.trim(),
      sender: _currentUser,
      timestamp: DateTime.now(),
      imageUrls: imageUrlsToSend,
      repliedIssue: _issueToForward,
    );

    setState(() {
      _messages.add(newMessage);
      _textController.clear();
      _currentDraftImages.clear();
      _issueToForward = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                bool showDateChip =
                    index == 0 ||
                    !_isSameDay(
                      _messages[index - 1].timestamp,
                      message.timestamp,
                    );
                if (showDateChip) {
                  return Column(
                    children: [
                      _buildDateChip(
                        DateFormat('EEE, dd MMM').format(message.timestamp),
                      ),
                      _buildChatBubble(message: message),
                    ],
                  );
                }
                return _buildChatBubble(message: message);
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) =>
      date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(
        bottom: BorderSide(color: Colors.black.withOpacity(0.1), width: 1),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.gray, size: 16),
        onPressed: () => Navigator.of(context).pop(),
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.issue.panelNoPp,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              _buildAppBarInfoChip("Panel", "ABACUS"),
              const SizedBox(width: 8),
              _buildAppBarInfoChip("Busbar", "Presisi"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarInfoChip(String label, String value) {
    return Row(
      children: [
        Text(
          "$label:",
          style: const TextStyle(color: AppColors.gray, fontSize: 10),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.gray.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateChip(String date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.grayLight),
        ),
        child: Text(
          date,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 10,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble({required ChatMessage message}) {
    final bool isSender = message.sender.id == _currentUser.id;
    final alignment = isSender
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final Color bubbleColor = isSender ? const Color(0xFFF5F5F5) : Colors.white;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisAlignment: isSender
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isSender) ...[
              CircleAvatar(
                backgroundColor: message.sender.avatarColor,
                radius: 16,
                child: Text(
                  message.sender.avatarInitials,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: alignment,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        message.sender.name,
                        style: const TextStyle(
                          color: AppColors.gray,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.grayLight,
                          width: 1,
                        ),
                      ),
                      child: message.repliedIssue != null
                          ? _buildIssueMessage(
                              message.repliedIssue!,
                              message.text,
                              message.imageUrls,
                              isSender: isSender,
                            )
                          : _buildStandardMessage(
                              message.text,
                              message.imageUrls,
                            ),
                    ),
                  ],
                ),
              ),
            ],
            if (isSender) ...[
              Flexible(
                child: Column(
                  crossAxisAlignment: alignment,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.grayLight,
                          width: 1,
                        ),
                      ),
                      child: message.repliedIssue != null
                          ? _buildIssueMessage(
                              message.repliedIssue!,
                              message.text,
                              message.imageUrls,
                              isSender: isSender,
                            )
                          : _buildStandardMessage(
                              message.text,
                              message.imageUrls,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        Padding(
          padding: EdgeInsets.only(
            top: 4,
            left: isSender ? 0 : 56,
            right: isSender ? 0 : 0,
          ),
          child: Text(
            DateFormat('HH.mm').format(message.timestamp),
            style: const TextStyle(color: AppColors.gray, fontSize: 11),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showFullScreenImage(File imageFile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            // Agar gambar bisa di-zoom
            child: Image.file(imageFile, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardMessage(String? text, List<String> imageUrls) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- URUTAN DIPASTIKAN BENAR: GAMBAR DULU ---
          if (imageUrls.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                bottom: (text != null && text.isNotEmpty) ? 8.0 : 0,
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: imageUrls.map((path) {
                  final imageFile = File(path);
                  // --- GAMBAR DIBUAT BISA DITEKAN ---
                  return GestureDetector(
                    onTap: () => _showFullScreenImage(imageFile),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        imageFile,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // --- TEKS DI BAWAH GAMBAR ---
          if (text != null && text.isNotEmpty)
            Text(
              text,
              style: const TextStyle(color: AppColors.black, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildIssueMessage(
    Issue issue,
    String? additionalText,
    List<String> additionalImages, {
    required bool isSender,
  }) {
    final Color dividerColor = isSender
        ? const Color(0xFFDBDBDB)
        : const Color(0xFFF5F5F5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => IssueDetailBottomSheet(issue: issue),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "• ${issue.status[0].toUpperCase()}${issue.status.substring(1)} Issue",
                      style: TextStyle(
                        color: issue.status == 'solved'
                            ? AppColors.schneiderGreen
                            : AppColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(width: 4),
                    Image.asset("assets/images/view-detail.png", height: 20),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      issue.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        color: AppColors.black,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        issue.description,
                        style: const TextStyle(
                          color: AppColors.gray,
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (issue.imageUrls.isNotEmpty)
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: issue.imageUrls.map((imageUrl) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          imageUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if ((additionalText != null && additionalText.isNotEmpty) ||
            additionalImages.isNotEmpty)
          Container(
            height: 1,
            color: dividerColor,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
          ),
        if ((additionalText != null && additionalText.isNotEmpty) ||
            additionalImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (additionalText != null && additionalText.isNotEmpty)
                  Text(
                    additionalText,
                    style: const TextStyle(
                      color: AppColors.black,
                      fontSize: 12,
                    ),
                  ),
                if (additionalImages.isNotEmpty) ...[
                  if (additionalText != null && additionalText.isNotEmpty)
                    const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: additionalImages
                        .map(
                          (path) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(path),
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_issueToForward != null) _buildReplyPreviewCard(),

          // --- _buildImagePreview DIHAPUS DARI SINI ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: _issueToForward != null
                  ? const BorderRadius.vertical(
                      top: Radius.zero,
                      bottom: Radius.circular(12),
                    )
                  : BorderRadius.circular(12),
              border: Border.all(color: AppColors.grayLight),
            ),
            child: Column(
              // <-- Bungkus Row dengan Column
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- DAN DIPINDAHKAN KE SINI, DI ATAS TEXTFIELD ---
                if (_currentDraftImages.isNotEmpty) _buildImagePreview(),

                // Padding untuk Row input
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 8.0,
                          ),
                          child: TextField(
                            controller: _textController,
                            maxLines: 5,
                            minLines: 1,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.black,
                            ),
                            decoration: const InputDecoration(
                              hintText: "Tulis pesan...",
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: AppColors.gray,
                                fontWeight: FontWeight.w300,
                                fontSize: 12,
                              ),
                            ),
                            cursorColor: AppColors.schneiderGreen,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: AppColors.gray,
                          size: 20,
                        ),
                        onPressed: _pickImage,
                        style: ButtonStyle(
                          overlayColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          splashFactory: NoSplash.splashFactory,
                        ),
                      ),
                      IconButton(
                        icon: Image.asset(
                          "assets/images/send-chat.png",
                          height: 36,
                        ),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Ubah _buildImagePreview agar memiliki padding yang benar di dalam container
  Widget _buildImagePreview() {
    return Padding(
      // Beri padding agar tidak menempel di tepi
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _currentDraftImages.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0), // Hanya padding kanan
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _currentDraftImages[index],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        radius: 10,
                        child: Icon(Icons.close, color: Colors.white, size: 12),
                      ),
                      onPressed: () => _removeImageFromDraft(index),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReplyPreviewCard() {
    if (_issueToForward == null) return const SizedBox.shrink();
    return Container(
      // Padding disesuaikan agar lebih rapat
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      // Margin bawah dihapus agar menempel ke input
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: AppColors.white, // Latar belakang abu-abu
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12), // Hanya radius atas
          bottom: Radius.zero, // Tidak ada radius bawah
        ),
        border: Border.all(
          color: AppColors.grayLight,
          width: 1,
        ), // Border tipis
        // Border bawah dihapus atau diganti dengan bagian atas input field
        // Karena akan menempel, border bawah ini bisa disesuaikan atau dihilangkan
        // Untuk kasus ini, kita biarkan saja border all, nanti overlap dengan border input field
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- BAGIAN INI DIHAPUS (GARIS VERTIKAL HIJAU) ---
          // Container(
          //   width: 4,
          //   height: 38,
          //   color: AppColors.schneiderGreen,
          //   margin: const EdgeInsets.only(right: 8, top: 2),
          // ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _issueToForward!.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.black,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2), // Jarak antar title dan description
                Text(
                  _issueToForward!.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.gray,
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.gray, size: 20),
            onPressed: () => setState(() => _issueToForward = null),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            padding: EdgeInsets.zero, // Hapus padding default IconButton
            constraints:
                const BoxConstraints(), // Hapus batasan ukuran default IconButton
          ),
        ],
      ),
    );
  }
}
