import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/issue.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:secpanel/components/issue/issue_chat/issue_comment_sheet.dart'; // Untuk skeleton

// Aset Ikon (Pastikan path ini ada di pubspec.yaml dan file ada di proyek Anda)
const String _addIcon = 'assets/images/plus.png';
const String _sendIcon = 'assets/images/send-chat.png';

// Model untuk UI Chat dengan tambahan `suggestedActions`
class AiChatMessage {
  final String id;
  final User sender;
  final String? text;
  final File? imageFile;
  final DateTime timestamp;
  final bool isThinking;
  final bool isError;
  final List<String> suggestedActions;

  AiChatMessage({
    required this.id,
    required this.sender,
    required this.timestamp,
    this.text,
    this.imageFile,
    this.isThinking = false,
    this.isError = false,
    this.suggestedActions = const [],
  });
}

class AskAiScreen extends StatefulWidget {
  final String panelNoPp;
  final String panelTitle;
  final User currentUser;
  final VoidCallback onUpdate;

  const AskAiScreen({
    super.key,
    required this.panelNoPp,
    required this.panelTitle,
    required this.currentUser,
    required this.onUpdate,
  });

  @override
  State<AskAiScreen> createState() => _AskAiScreenState();
}

class _AskAiScreenState extends State<AskAiScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiChatMessage> _messages = [];
  final List<File> _draftImages = [];
  bool _isSending = false;
  List<String> _currentSuggestions = [];

  static final User geminiAI = User(id: 'gemini_ai', name: 'Gemini AI');

  @override
  void initState() {
    super.initState();
    _messages.add(
      AiChatMessage(
        id: 'initial-${DateTime.now().millisecondsSinceEpoch}',
        sender: geminiAI,
        text:
            "Halo! Ada yang bisa saya bantu terkait panel **${widget.panelTitle}**? Coba tanyakan 'apa saja isu yang ada?' untuk memulai.",
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
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

  Future<void> _sendMessage({String? textFromChip}) async {
    final text = textFromChip ?? _textController.text.trim();
    if ((text.isEmpty && _draftImages.isEmpty) || _isSending) return;

    FocusScope.of(context).unfocus();
    final List<File> imagesToSend = List.from(_draftImages);

    setState(() {
      _isSending = true;
      _currentSuggestions = []; // Hapus sugesti lama saat pesan baru dikirim

      if (imagesToSend.isNotEmpty) {
        for (var imageFile in imagesToSend) {
          _messages.add(
            AiChatMessage(
              id: 'user-img-${imageFile.path}',
              sender: widget.currentUser,
              imageFile: imageFile,
              timestamp: DateTime.now(),
            ),
          );
        }
      }
      if (text.isNotEmpty) {
        _messages.add(
          AiChatMessage(
            id: 'user-text-${DateTime.now().millisecondsSinceEpoch}',
            sender: widget.currentUser,
            text: text,
            timestamp: DateTime.now(),
          ),
        );
      }

      _textController.clear();
      _draftImages.clear();

      _messages.add(
        AiChatMessage(
          id: 'thinking-${DateTime.now().millisecondsSinceEpoch}',
          sender: geminiAI,
          text: '',
          timestamp: DateTime.now(),
          isThinking: true,
        ),
      );
    });
    _scrollToBottom();

    String? imageB64;
    if (imagesToSend.isNotEmpty) {
      final imageBytes = await imagesToSend.first.readAsBytes();
      imageB64 = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
    }

    try {
      final aiResponse = await DatabaseHelper.instance.askAiAboutPanel(
        panelNoPp: widget.panelNoPp,
        question: text,
        senderId: widget.currentUser.id,
        imageB64: imageB64,
      );

      final List<String> suggestions = List<String>.from(
        aiResponse['suggested_actions'] ?? [],
      );

      final aiResponseMessage = AiChatMessage(
        id:
            aiResponse['id'] as String? ??
            'ai-msg-${DateTime.now().millisecondsSinceEpoch}',
        text: aiResponse['text'] as String? ?? "Maaf, terjadi kesalahan.",
        sender: geminiAI,
        timestamp: DateTime.now(),
        suggestedActions: suggestions,
      );

      setState(() {
        _messages.removeWhere((msg) => msg.isThinking);
        _messages.add(aiResponseMessage);
        _currentSuggestions = suggestions;
        if (aiResponse['action_taken'] == true) {
          widget.onUpdate();
        }
      });
    } catch (e) {
      final errorMessage = AiChatMessage(
        id: 'error-${DateTime.now().millisecondsSinceEpoch}',
        text: "Gagal terhubung dengan AI: ${e.toString()}",
        sender: geminiAI,
        timestamp: DateTime.now(),
        isError: true,
      );
      setState(() {
        _messages.removeWhere((msg) => msg.isThinking);
        _messages.add(errorMessage);
      });
    } finally {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _draftImages.add(File(result.files.single.path!));
        });
      }
    } catch (e) {
      debugPrint("Gagal memilih gambar: $e");
    }
  }

  void _removeDraftImage(int index) {
    setState(() => _draftImages.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isSender = message.sender.id == widget.currentUser.id;

                if (message.isThinking) return _AiLoadingBubble(user: geminiAI);

                return isSender
                    ? _UserMessageBubble(message: message)
                    : _AiMessageBubble(message: message);
              },
            ),
          ),
          if (_currentSuggestions.isNotEmpty && !_isSending)
            _buildSuggestionChips(),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.gray),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Tanya AI',
        style: TextStyle(
          color: AppColors.black,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      centerTitle: true,
      shape: const Border(
        bottom: BorderSide(color: AppColors.grayLight, width: 1),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.grayLight, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_draftImages.isNotEmpty) ...[
            _buildImagePreview(),
            const SizedBox(height: 8),
          ],
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.grayLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                IconButton(
                  icon: Image.asset(
                    _addIcon,
                    width: 24,
                    height: 24,
                    color: AppColors.gray,
                  ),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      controller: _textController,
                      maxLines: 5,
                      minLines: 1,
                      cursorColor: AppColors.schneiderGreen,
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan...',
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 4),
                        hintStyle: TextStyle(
                          color: AppColors.gray,
                          fontWeight: FontWeight.w300,
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                Container(
                  child: IconButton(
                    icon: Image.asset(_sendIcon, width: 32),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: _currentSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _currentSuggestions[index];
          return GestureDetector(
            onTap: () => _sendMessage(textFromChip: suggestion),
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.schneiderGreen.withOpacity(0.5),
                ),
              ),
              child: Text(
                suggestion,
                style: const TextStyle(
                  color: AppColors.schneiderGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePreview() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _draftImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _draftImages[index],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: GestureDetector(
                    onTap: () => _removeDraftImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.7),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// WIDGET-WIDGET PENDUKUNG (Bubbles, Skeletons)
// ===========================================================================

class _UserMessageBubble extends StatelessWidget {
  final AiChatMessage message;
  const _UserMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.imageFile != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                      maxHeight: 250,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(message.imageFile!, fit: BoxFit.cover),
                    ),
                  ),
                if (message.text != null && message.text!.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.schneiderGreen,
                      borderRadius: BorderRadius.circular(
                        20,
                      ).copyWith(bottomRight: const Radius.circular(4)),
                    ),
                    child: Text(
                      message.text!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH.mm').format(message.timestamp.toLocal()),
                  style: const TextStyle(color: AppColors.gray, fontSize: 10),
                ),
              ],
            ),
          ),
          // const SizedBox(width: 8),
          // CircleAvatar(
          //   radius: 20,
          //   backgroundColor: AppColors.schneiderGreen,
          //   child: Text(
          //     message.sender.avatarInitials,
          //     style: const TextStyle(
          //       color: Colors.white,
          //       fontSize: 12,
          //       fontWeight: FontWeight.w400,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _AiMessageBubble extends StatelessWidget {
  final AiChatMessage message;
  const _AiMessageBubble({required this.message});

  Widget _buildRichText(String text) {
    List<InlineSpan> spans = [];
    final pattern = RegExp(r"(\*\*.*?\*\*)|(\*.*?\*)");
    final defaultStyle = const TextStyle(
      fontSize: 12,
      height: 1.5,
      color: AppColors.black,
      fontFamily: 'Lexend',
    );
    final boldStyle = defaultStyle.copyWith(fontWeight: FontWeight.w600);
    final italicStyle = defaultStyle.copyWith(fontStyle: FontStyle.italic);

    text.splitMapJoin(
      pattern,
      onMatch: (Match match) {
        String matchText = match[0]!;
        if (matchText.startsWith('**') && matchText.endsWith('**')) {
          spans.add(
            TextSpan(
              text: matchText.substring(2, matchText.length - 2),
              style: boldStyle,
            ),
          );
        } else if (matchText.startsWith('*') && matchText.endsWith('*')) {
          spans.add(
            TextSpan(
              text: matchText.substring(1, matchText.length - 1),
              style: italicStyle,
            ),
          );
        }
        return '';
      },
      onNonMatch: (String nonMatch) {
        spans.add(TextSpan(text: nonMatch, style: defaultStyle));
        return '';
      },
    );
    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.blue,
            child: Text(
              message.sender.avatarInitials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.sender.name,
                  style: const TextStyle(
                    color: AppColors.gray,
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isError
                        ? Colors.red.shade50
                        : AppColors.gray.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(
                      20,
                    ).copyWith(bottomLeft: const Radius.circular(4)),
                  ),
                  child: _buildRichText(message.text!),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH.mm').format(message.timestamp.toLocal()),
                  style: const TextStyle(color: AppColors.gray, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiLoadingBubble extends StatelessWidget {
  final User user;
  const _AiLoadingBubble({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.blue,
            child: Text(
              user.avatarInitials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  color: AppColors.gray,
                  fontSize: 11,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gray.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(
                    20,
                  ).copyWith(bottomLeft: const Radius.circular(4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
