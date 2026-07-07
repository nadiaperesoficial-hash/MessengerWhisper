import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/services/chat_service.dart';
import '../core/services/story_service.dart';
import '../core/theme/app_theme.dart';
import '../widgets/stories/add_story_sheet.dart';
import 'chat/chat_screen.dart';
import 'new_chat_screen.dart';
import 'stories/story_viewer_screen.dart';

class Home extends StatefulWidget {
  final String listType;
  Home(this.listType, {super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _storyService = StoryService();
  final _chatService = ChatService();
  late Future<List<Map<String, dynamic>>> _storiesFuture;
  late Future<List<Map<String, dynamic>>> _chatsFuture;

  @override
  void initState() {
    super.initState();
    _reloadStories();
    _reloadChats();
  }

  void _reloadStories() {
    _storiesFuture = _storyService.fetchGroupedStories();
  }

  void _reloadChats() {
    _chatsFuture = _chatService.fetchMyChats();
  }

  Future<void> _refreshStories() async {
    setState(_reloadStories);
  }

  Future<void> _refreshChats() async {
    setState(_reloadChats);
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    return DateFormat('h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Whisper',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            fontFamily: 'Roboto',
          ),
        ),
        titleSpacing: 16.0,
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.search, color: AppColors.textPrimary), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: AppColors.textPrimary), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.lineGreen,
        child: const Icon(Icons.chat, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewChatScreen()),
          );
          _refreshChats();
        },
      ),
      body: Column(
        children: <Widget>[
          const Padding(padding: EdgeInsets.fromLTRB(0.0, 3.0, 0.0, 8.0)),
          SizedBox(
            height: 108.0,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _storiesFuture,
              builder: (context, snapshot) {
                final stories = snapshot.data ?? [];

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: stories.length + 1,
                  itemBuilder: (context, position) {
                    if (position == 0) {
                      return _AddStoryTile(onAdded: _refreshStories);
                    }
                    final story = stories[position - 1];
                    return _StoryTile(
                      name: story['name'] ?? 'Usuário',
                      profileImageUrl: story['avatar_url'],
                      seen: story['all_seen'] == true,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoryViewerScreen(
                              userId: story['user_id'],
                              userName: story['name'] ?? 'Usuário',
                              userAvatarUrl: story['avatar_url'],
                            ),
                          ),
                        );
                        _refreshStories();
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshChats,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _chatsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          '${snapshot.error}',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    );
                  }
                  final chats = snapshot.data ?? [];
                  if (chats.isEmpty) {
                    return ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Nenhuma conversa ainda.\nToque no botão verde pra começar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, position) {
                      final chat = chats[position];
                      final name = chat['other_user_name'] ?? 'Usuário';
                      final avatar = chat['other_user_avatar'];
                      final lastType = chat['last_message_type'];
                      final lastContent = lastType == 'image'
                          ? '📷 Foto'
                          : lastType == 'gif'
                              ? '🎞️ GIF'
                              : (chat['last_message_content'] ?? 'Diga oi 👋');
                      final lastTime = _formatTime(chat['last_message_at']);

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                        child: Card(
                          elevation: 1.0,
                          color: const Color(0xFFFFFFFF),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.surface,
                              backgroundImage: avatar != null
                                  ? CachedNetworkImageProvider(avatar)
                                  : null,
                              child: avatar == null
                                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                                  : null,
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  lastTime,
                                  style: const TextStyle(color: Colors.grey, fontSize: 14.0),
                                ),
                              ],
                            ),
                            subtitle: Container(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Text(
                                lastContent,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey, fontSize: 15.0),
                              ),
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    chatId: chat['chat_id'],
                                    otherUserName: name,
                                    otherUserAvatarUrl: avatar,
                                  ),
                                ),
                              );
                              _refreshChats();
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddStoryTile extends StatelessWidget {
  const _AddStoryTile({required this.onAdded});
  final VoidCallback onAdded;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showAddStorySheet(context);
        onAdded();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 68,
          child: Column(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.surface,
                    child: Icon(Icons.person, color: AppColors.textSecondary, size: 28),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.lineGreen,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: const Icon(Icons.add, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Seu story',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({
    required this.name,
    required this.profileImageUrl,
    required this.seen,
    required this.onTap,
  });

  final String name;
  final String? profileImageUrl;
  final bool seen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 68,
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: seen
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2ECC71),
                            Color(0xFF00C300),
                          ],
                        ),
                  color: seen ? AppColors.border : null,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: CircleAvatar(
                    backgroundColor: AppColors.surface,
                    backgroundImage: profileImageUrl != null
                        ? CachedNetworkImageProvider(profileImageUrl!)
                        : null,
                    child: profileImageUrl == null
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
