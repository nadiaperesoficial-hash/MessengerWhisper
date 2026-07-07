import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/story_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/stories/glass_caption_field.dart';

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
  });

  final String userId;
  final String userName;
  final String? userAvatarUrl;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  final _storyService = StoryService();
  final _chatService = ChatService();
  final _replyController = TextEditingController();
  final _replyFocusNode = FocusNode();

  List<Map<String, dynamic>> _stories = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _liked = false;
  bool _sendingReply = false;

  late AnimationController _progressController;
  static const _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _goNext();
      });

    _replyFocusNode.addListener(() {
      if (_replyFocusNode.hasFocus) {
        _progressController.stop();
      } else if (!_sendingReply) {
        _progressController.forward();
      }
    });

    _load();
  }

  Future<void> _load() async {
    final stories = await _storyService.fetchStoriesForUser(widget.userId);
    if (!mounted) return;
    setState(() {
      _stories = stories;
      _loading = false;
    });
    if (_stories.isNotEmpty) {
      _checkLiked();
      _markCurrentAsViewed();
      _progressController.forward(from: 0);
    }
  }

  Future<void> _checkLiked() async {
    final liked = await _storyService.isLikedByMe(_stories[_currentIndex]['id']);
    if (mounted) setState(() => _liked = liked);
  }

  void _markCurrentAsViewed() {
    final storyId = _stories[_currentIndex]['id'] as String;
    // Dispara e esquece — não precisa travar a navegação esperando confirmação.
    _storyService.markStoryAsViewed(storyId);
  }

  void _goNext() {
    if (_currentIndex < _stories.length - 1) {
      setState(() => _currentIndex++);
      _checkLiked();
      _markCurrentAsViewed();
      _progressController.forward(from: 0);
    } else {
      Navigator.pop(context);
    }
  }

  void _goPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _checkLiked();
      _markCurrentAsViewed();
      _progressController.forward(from: 0);
    } else {
      _progressController.forward(from: 0);
    }
  }

  Future<void> _toggleLike() async {
    final story = _stories[_currentIndex];
    setState(() => _liked = !_liked);
    if (_liked) {
      await _storyService.likeStory(story['id']);
    } else {
      await _storyService.unlikeStory(story['id']);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingReply = true);
    _progressController.stop();
    try {
      final chatId = await _chatService.getOrCreateOneToOneChat(widget.userId);
      await _chatService.sendTextMessage(chatId, text);
      _replyController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensagem enviada.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível enviar.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendingReply = false);
        _replyFocusNode.unfocus();
        _progressController.forward();
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  Color _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (_stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nenhuma story disponível',
                style: TextStyle(color: Colors.white)),
          ),
        ),
      );
    }

    final story = _stories[_currentIndex];
    final isText = story['type'] == 'text';
    final createdAt = DateTime.tryParse(story['created_at'] ?? '');

    return Scaffold(
      backgroundColor: isText ? _colorFromHex(story['background_color']) : Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTapUp: (details) {
              final width = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < width / 3) {
                _goPrevious();
              } else {
                _goNext();
              }
            },
            child: isText
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        story['caption'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: story['media_url'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: List.generate(_stories.length, (i) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, _) {
                                double value = 0;
                                if (i < _currentIndex) {
                                  value = 1;
                                } else if (i == _currentIndex) {
                                  value = _progressController.value;
                                }
                                return FractionallySizedBox(
                                  widthFactor: value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surface,
                        backgroundImage: widget.userAvatarUrl != null
                            ? CachedNetworkImageProvider(widget.userAvatarUrl!)
                            : null,
                        child: widget.userAvatarUrl == null
                            ? Text(widget.userName.substring(0, 1).toUpperCase())
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            if (createdAt != null)
                              Text(
                                DateFormat('dd/MM HH:mm').format(createdAt),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.more_vert, color: Colors.white),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GlassCaptionField(
                          controller: _replyController,
                          hintText: 'Responder',
                          onSubmitted: (_) => _sendReply(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _sendingReply ? null : _sendReply,
                        icon: _sendingReply
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Encaminhar em breve.')),
                          );
                        },
                        icon: const Icon(Icons.forward_outlined, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: _toggleLike,
                        icon: Icon(
                          _liked ? Icons.favorite : Icons.favorite_border,
                          color: _liked ? AppColors.error : Colors.white,
                        ),
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
}
