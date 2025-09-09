import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/issue.dart';
import 'package:secpanel/theme/colors.dart';

class IssueCommentSheet extends StatefulWidget {
  final IssueWithPhotos issue;
  final VoidCallback onUpdate;
  final User currentUser; // Parameter yang diperlukan

  const IssueCommentSheet({
    super.key,
    required this.issue,
    required this.onUpdate,
    required this.currentUser, // Dibuat menjadi required
  });

  @override
  State<IssueCommentSheet> createState() => _IssueCommentSheetState();
}

class _IssueCommentSheetState extends State<IssueCommentSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<File> _newDraftImages = [];
  final List<String> _existingImageUrls = [];

  bool _isLoading = true;
  List<IssueComment> _comments = [];
  Map<String?, List<IssueComment>> _groupedComments = {};
  List<IssueComment> _topLevelComments = [];

  IssueComment? _replyingTo;
  IssueComment? _editingComment;

  String get _baseUrl {
    if (kReleaseMode) {
      return "https://secpanel-db.onrender.com";
    } else {
      if (Platform.isAndroid) {
        return "https://secpanel-db.onrender.com";
      } else {
        return "https://secpanel-db.onrender.com";
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final comments = await DatabaseHelper.instance.getComments(
        widget.issue.id,
      );
      if (!mounted) return;

      setState(() {
        _comments = comments;
        _groupComments();
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToBottom(animated: false),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat komentar: $e")));
    }
  }

  void _groupComments() {
    final grouped = <String?, List<IssueComment>>{null: []};
    final sortedComments = List<IssueComment>.from(_comments)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (var comment in sortedComments) {
      final parentId = comment.replyToCommentId;
      bool parentExists =
          parentId == null || _comments.any((c) => c.id == parentId);

      if (parentId == null || !parentExists) {
        (grouped[null] ??= []).add(comment);
      } else {
        (grouped[parentId] ??= []).add(comment);
      }
    }

    _groupedComments = grouped;
    _topLevelComments = grouped[null] ?? [];
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays > 0) return '${difference.inDays} hari lalu';
    if (difference.inHours > 0) return '${difference.inHours} jam lalu';
    if (difference.inMinutes > 0) return '${difference.inMinutes} menit lalu';
    return 'Baru saja';
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: animated ? 300 : 0),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _newDraftImages.addAll(
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

  void _removeImageFromDraft(int index, {required bool isNewImage}) {
    setState(() {
      if (isNewImage) {
        final fileIndex = index - _existingImageUrls.length;
        _newDraftImages.removeAt(fileIndex);
      } else {
        _existingImageUrls.removeAt(index);
      }
    });
  }

  Future<void> _submitComment() async {
    final hasText = _textController.text.trim().isNotEmpty;
    final hasImages =
        _newDraftImages.isNotEmpty || _existingImageUrls.isNotEmpty;
    if (!hasText && !hasImages) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    try {
      if (_editingComment != null) {
        await DatabaseHelper.instance.updateComment(
          commentId: _editingComment!.id,
          text: _textController.text.trim(),
          existingImageUrls: _existingImageUrls,
          newImages: _newDraftImages,
        );
      } else {
        final parentId = _replyingTo?.replyToCommentId ?? _replyingTo?.id;
        await DatabaseHelper.instance.createComment(
          issueId: widget.issue.id,
          text: _textController.text.trim(),
          senderId: widget.currentUser.id,
          replyToCommentId: parentId,
          replyToUserId: _replyingTo?.sender.id,
          images: _newDraftImages,
        );
      }

      _cancelReplyOrEdit(); // This now correctly clears all draft image lists
      await _fetchComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal mengirim komentar: $e")));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startReply(IssueComment comment) {
    setState(() {
      _replyingTo = comment;
      _editingComment = null;
      _newDraftImages.clear();
      _existingImageUrls.clear();
    });
  }

  void _cancelReplyOrEdit() {
    setState(() {
      _replyingTo = null;
      _editingComment = null;
      _textController.clear();
      _newDraftImages.clear();
      _existingImageUrls.clear();
    });
  }

  void _startEdit(IssueComment comment) {
    setState(() {
      _editingComment = comment;
      _replyingTo = null;
      _textController.text = comment.text;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
      _newDraftImages.clear();
      _existingImageUrls.clear();
      _existingImageUrls.addAll(comment.imageUrls);
    });
  }

  Future<void> _deleteComment(String commentId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await DatabaseHelper.instance.deleteComment(commentId);
      await _fetchComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menghapus komentar: $e")));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              _buildSheetHeader(),
              const Divider(height: 1, color: AppColors.grayLight),
              Expanded(
                // ▼▼▼ UBAH LOGIKA DI DALAM EXPANDED INI ▼▼▼
                child: _isLoading && _comments.isEmpty
                    ? _buildLoadingSkeleton() // Tampilkan skeleton
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 20.0,
                        ),
                        // Ganti itemCount agar skeleton bisa tampil
                        itemCount: _topLevelComments.length,
                        itemBuilder: (context, index) {
                          final comment = _topLevelComments[index];
                          final replies = _groupedComments[comment.id] ?? [];
                          replies.sort(
                            (a, b) => a.timestamp.compareTo(b.timestamp),
                          );
                          return _buildCommentThread(comment, replies);
                        },
                      ),
                // ▲▲▲ SAMPAI SINI PERUBAHANNYA ▲▲▲
              ),
              // Indikator loading saat mengirim/menghapus
              if (_isLoading && _comments.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: LinearProgressIndicator()),
                ),
              _buildMessageComposer(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      itemCount: 4, // Tampilkan 4 skeleton sebagai placeholder
      itemBuilder: (context, index) => const CommentCardSkeleton(),
    );
  }

  Widget _buildSheetHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        "Komentar",
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildCommentThread(
    IssueComment parentComment,
    List<IssueComment> replies,
  ) {
    return Column(
      children: [
        _buildCommentItem(comment: parentComment),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40.0, top: 20),
            child: Column(
              children: replies
                  .map(
                    (reply) => _buildCommentItem(comment: reply, isReply: true),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentItem({
    required IssueComment comment,
    bool isReply = false,
  }) {
    final bool isCurrentUser = comment.sender.id == widget.currentUser.id;
    final bool isCreator = comment.sender.id == 'admin';

    return Padding(
      padding: EdgeInsets.only(bottom: isReply ? 20.0 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: comment.sender.avatarColor,
            radius: isReply ? 16 : 20,
            child: Text(
              comment.sender.avatarInitials,
              style: TextStyle(
                color: Colors.white,
                fontSize: isReply ? 12 : 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCommentHeader(comment, isCreator),
                const SizedBox(height: 4),
                _buildCommentContent(comment),
                const SizedBox(height: 8),
                _buildCommentActions(comment, isCurrentUser),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentHeader(IssueComment comment, bool isCreator) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          comment.sender.name,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 6),
        if (isCreator) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.grayLight,
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFF0066FF), size: 14),
                const SizedBox(width: 4),
                const Text(
                  'Creator',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
        const Spacer(),
        Text(
          _formatTimestamp(comment.timestamp),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentContent(IssueComment comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (comment.text.isNotEmpty)
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.black,
                fontFamily: 'Poppins',
              ),
              children: [
                if (comment.replyTo != null)
                  TextSpan(
                    text: '@${comment.replyTo!.name} ',
                    style: const TextStyle(
                      color: Color(0xFF0066FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                TextSpan(text: comment.text),
              ],
            ),
          ),
        if (comment.imageUrls.isNotEmpty) ...[
          SizedBox(height: comment.text.isNotEmpty ? 8 : 0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: comment.imageUrls.map((imageUrl) {
              final fullUrl = _baseUrl + imageUrl;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(imageUrl: fullUrl),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    fullUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentActions(IssueComment comment, bool isCurrentUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton('Balas', () => _startReply(comment)),
        if (isCurrentUser) ...[
          _buildActionSeparator(),
          _buildActionButton('Hapus', () => _deleteComment(comment.id)),
          _buildActionSeparator(),
          _buildActionButton('Edit', () => _startEdit(comment)),
        ],
        if (comment.isEdited) ...[
          _buildActionSeparator(),
          const Text(
            'Diedit',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppColors.gray,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildActionSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text('•', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
    );
  }

  Widget _buildMessageComposer() {
    bool isReplying = _replyingTo != null;
    bool isEditing = _editingComment != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
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
          if (isReplying || isEditing) _buildReplyOrEditPreviewCard(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: (isReplying || isEditing)
                  ? const BorderRadius.vertical(bottom: Radius.circular(12))
                  : BorderRadius.circular(12),
              border: Border.all(color: AppColors.grayLight),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImagePreview(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      ),
                      IconButton(
                        icon: Image.asset(
                          "assets/images/send-chat.png",
                          height: 36,
                        ),
                        onPressed: _submitComment,
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

  Widget _buildImagePreview() {
    final allImageCount = _existingImageUrls.length + _newDraftImages.length;
    if (allImageCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: allImageCount,
          itemBuilder: (context, index) {
            Widget imageWidget;
            bool isNewImage;

            if (index < _existingImageUrls.length) {
              final url = _baseUrl + _existingImageUrls[index];
              imageWidget = Image.network(
                url,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              );
              isNewImage = false;
            } else {
              final fileIndex = index - _existingImageUrls.length;
              imageWidget = Image.file(
                _newDraftImages[fileIndex],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              );
              isNewImage = true;
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageWidget,
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
                      onPressed: () =>
                          _removeImageFromDraft(index, isNewImage: isNewImage),
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

  Widget _buildReplyOrEditPreviewCard() {
    final String title = _editingComment != null
        ? 'Mengedit Pesan'
        : 'Membalas ${_replyingTo?.sender.name ?? ''}';
    final String content = _editingComment != null
        ? _editingComment!.text
        : _replyingTo?.text ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(color: AppColors.grayLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.black,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
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
            onPressed: _cancelReplyOrEdit,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;

  const FullScreenImageViewer({super.key, this.imageUrl, this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: imageFile != null
              ? Image.file(imageFile!)
              : Image.network(imageUrl!),
        ),
      ),
    );
  }
}

class CommentCardSkeleton extends StatelessWidget {
  const CommentCardSkeleton({super.key});

  Widget _buildPlaceholder({double? width, double height = 14}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: Colors.grey[200], radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlaceholder(width: 120, height: 12),
                const SizedBox(height: 8),
                _buildPlaceholder(width: double.infinity),
                const SizedBox(height: 4),
                _buildPlaceholder(width: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
