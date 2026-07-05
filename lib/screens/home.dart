import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/services/chat_service.dart';
import '../core/services/story_service.dart';
import '../core/theme/app_theme.dart';
import 'chat/chat_screen.dart';
import 'new_chat_screen.dart';
import 'stories/add_story_screen.dart';
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

  String _formatDay(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    return DateFormat('MMM d').format(date);
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
            height: 220.0,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _storiesFuture,
              builder: (context, snapshot) {
                final stories = snapshot.data ?? [];

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: stories.length + 1,
                  itemBuilder: (context, position) {
                    if (position == 0) {
                      return _AddStoryTile(onAdded: _refreshStories);
                    }
                    final story = stories[position - 1];
                    return _StoryTile(
                      name: story['name'] ?? 'Usuário',
                      profileImageUrl: story['avatar_url'],
                      storyImageUrl: story['latest_type'] == 'image'
                          ? story['latest_media_url']
                          : null,
                      day: _formatDay(story['latest_created_at']),
                      time: _formatTime(story['latest_created_at']),
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
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddStoryScreen()),
        );
        onAdded();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
        child: SizedBox(
          width: 100.0,
          height: 210.0,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                width: 100.0,
                height: 140.0,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5.0, 65.0, 5.0, 0.0),
                child: Container(
                  width: 50.0,
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: AppColors.lineGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.0),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
              const Positioned(
                bottom: 20,
                child: Text(
                  'Tap to\nadd Story',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
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
    required this.storyImageUrl,
    required this.day,
    required this.time,
    required this.onTap,
  });

  final String name;
  final String? profileImageUrl;
  final String? storyImageUrl;
  final String day;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
        child: SizedBox(
          width: 100.0,
          height: 210.0,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  image: storyImageUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(storyImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                width: 100.0,
                height: 140.0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5.0, 85.0, 5.0, 5.0),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5.0, 65.0, 5.0, 0.0),
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.surface,
                  backgroundImage: profileImageUrl != null
                      ? CachedNetworkImageProvider(profileImageUrl!)
                      : null,
                  child: profileImageUrl == null
                      ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5.0, 140.0, 5.0, 0.0),
                child: Center(child: Text(day)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5.0, 172.0, 5.0, 0.0),
                child: Text(time),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
