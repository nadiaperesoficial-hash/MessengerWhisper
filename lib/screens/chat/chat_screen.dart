import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/env.dart';
import '../../core/services/message_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/chat/glass_message_bar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.otherUserAvatarUrl,
  });

  final String chatId;
  final String otherUserName;
  final String? otherUserAvatarUrl;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageService = MessageService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _showEmoji = false;
  bool _isRecording = false;

  static const _emojis = [
    '😀', '😁', '😂', '🤣', '😊', '😍', '😘', '😜', '🤔', '😎',
    '😢', '😭', '😡', '👍', '👎', '👏', '🙏', '❤️', '🔥', '🎉',
    '😴', '🤗', '😇', '🥳', '🤩', '😱', '🤯', '😅', '🙄', '😏',
  ];

  @override
  void initState() {
    super.initState();
    _textController.addListener(() => setState(() {}));
    _loadHistory();
    _messageService.subscribeToChat(
      widget.chatId,
      onNewMessage: (msg) {
        if (!mounted) return;
        setState(() {
          _messages.add(msg);
        });
        _scrollToBottom();
      },
      onMessageRead: (messageId) {
        if (!mounted) return;
        setState(() {
          final index = _messages.indexWhere((m) => m['id'] == messageId);
          if (index != -1) {
            _messages[index] = Map<String, dynamic>.from(_messages[index])
              ..['read_at'] = DateTime.now().toIso8601String();
          }
        });
      },
    );
    _messageService.markChatAsRead(widget.chatId);
  }

  Future<void> _loadHistory() async {
    final history = await _messageService.loadLocalHistory(widget.chatId);
    if (!mounted) return;
    setState(() {
      _messages = history;
      _loading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _refreshMessages() async {
    final updated = await _messageService.loadLocalHistory(widget.chatId);
    if (!mounted) return;
    setState(() => _messages = updated);
    _scrollToBottom();
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    try {
      await _messageService.sendTextMessage(widget.chatId, text);
      await _refreshMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  /// Câmera foi removida por enquanto — esse botão abre a galeria diretamente.
  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    try {
      final file = File(picked.path);
      final url = await _messageService.uploadChatImage(file);
      await _messageService.sendImageMessage(widget.chatId, url);
      await _refreshMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar foto: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _pickGif() async {
    final gif = await GiphyGet.getGif(
      context: context,
      apiKey: Env.giphyApiKey,
      lang: GiphyLanguage.portuguese,
    );
    if (gif == null) return;
    final gifUrl = gif.images?.original?.url;
    if (gifUrl == null) return;
    try {
      await _messageService.sendGifMessage(widget.chatId, gifUrl);
      await _refreshMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar GIF: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  /// Um ícone só: pergunta rapidinho se é emoji (instantâneo, sem delay)
  /// ou GIF (abre o buscador do Giphy).
  void _handleEmojiOrGifTap() {
    if (_showEmoji) {
      setState(() => _showEmoji = false);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.emoji_emotions_outlined, color: AppColors.textPrimary),
                title: const Text('Emoji'),
                onTap: () {
                  Navigator.pop(context);
                  FocusScope.of(context).unfocus();
                  setState(() => _showEmoji = true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.gif_box_outlined, color: AppColors.textPrimary),
                title: const Text('GIF'),
                onTap: () {
                  Navigator.pop(context);
                  _pickGif();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _insertEmoji(String emoji) {
    _textController.text += emoji;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  }

  void _placeholderCall(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label em breve.')),
    );
  }

  @override
  void dispose() {
    _messageService.unsubscribe();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    final hasText = _textController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.chatBackground,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surface,
              backgroundImage: widget.otherUserAvatarUrl != null
                  ? CachedNetworkImageProvider(widget.otherUserAvatarUrl!)
                  : null,
              child: widget.otherUserAvatarUrl == null
                  ? Text(widget.otherUserName.isNotEmpty
                      ? widget.otherUserName[0].toUpperCase()
                      : '?')
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherUserName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () => _placeholderCall('Chamada de vídeo'),
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () => _placeholderCall('Ligação'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Diga oi 👋',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMine = msg['sender_id'] == myId;
                          return _MessageBubble(message: msg, isMine: isMine);
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: GlassMessageBar(
                controller: _textController,
                hasText: hasText,
                isRecording: _isRecording,
                emojiActive: _showEmoji,
                onEmojiOrGif: _handleEmojiOrGifTap,
                onGallery: _pickFromGallery,
                onSend: _sendText,
                onMicStart: (_) => setState(() => _isRecording = true),
                onMicEnd: (_) {
                  setState(() => _isRecording = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gravação de áudio em breve.')),
                  );
                },
              ),
            ),
          ),
          if (_showEmoji)
            SizedBox(
              height: 250,
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                ),
                itemCount: _emojis.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () => _insertEmoji(_emojis[index]),
                    child: Center(
                      child: Text(_emojis[index], style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final Map<String, dynamic> message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final type = message['type'] ?? 'text';
    final createdAt = DateTime.tryParse(message['created_at'] ?? '');
    final readAt = message['read_at'];
    final timeLabel = createdAt != null ? DateFormat('HH:mm').format(createdAt) : '';
    final statusLabel = isMine ? (readAt != null ? 'Lido' : 'Entregue') : null;
    final isMedia = type == 'image' || type == 'gif';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.bubbleOutgoing : AppColors.bubbleIncoming,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMedia && message['media_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: message['media_url'],
                  width: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              Text(
                message['content'] ?? '',
                style: TextStyle(
                  color: isMine ? Colors.white : AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: isMine ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                if (statusLabel != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    statusLabel,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
