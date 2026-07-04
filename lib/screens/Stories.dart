import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/services/story_service.dart';
import '../core/theme/app_theme.dart';
import 'stories/add_story_screen.dart';
import 'stories/text_story_screen.dart';
import 'stories/story_viewer_screen.dart';

class Stories extends StatefulWidget {
  Stories(this.listType, {super.key});
  final String listType;

  @override
  State<Stories> createState() => _StoriesState();
}

class _StoriesState extends State<Stories> {
  final _storyService = StoryService();
  late Future<List<Map<String, dynamic>>> _storiesFuture;
  String _debugInfo = 'Carregando diagnóstico...';

  @override
  void initState() {
    super.initState();
    _reload();
    _runDiagnostics();
  }

  void _reload() {
    _storiesFuture = _storyService.fetchGroupedStories();
  }

  Future<void> _runDiagnostics() async {
    try {
      final noJoin = await _storyService.debugCountStoriesNoJoin();
      final withJoin = await _storyService.debugCountStoriesWithJoin();
      if (mounted) {
        setState(() {
          _debugInfo = 'DEBUG: sem join = $noJoin | com join = $withJoin';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _debugInfo = 'DEBUG erro: $e';
        });
      }
    }
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _runDiagnostics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Stories'),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'story_text_fab',
            mini: true,
            backgroundColor: AppColors.surface,
            child: const Icon(Icons.edit, color: AppColors.textPrimary),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TextStoryScreen()),
              );
              _refresh();
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'story_camera_fab',
            backgroundColor: AppColors.lineGreen,
            child: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddStoryScreen()),
              );
              _refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _storiesFuture,
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
            final stories = snapshot.data ?? [];
            return ListView(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.yellow[100],
                  padding: const EdgeInsets.all(8),
                  child: Text(_debugInfo, style: const TextStyle(fontSize: 12)),
                ),
                ListTile(
                  leading: Stack(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.surface,
                        child: Icon(Icons.person, color: AppColors.textSecondary),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.lineGreen,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(Icons.add, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  title: const Text('Adicionar Story',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Desaparecerá conforme o tempo escolhido'),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddStoryScreen()),
                    );
                    _refresh();
                  },
                ),
                const Divider(height: 1),
                if (stories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Nenhuma story ainda.')),
                  ),
                ...stories.map((s) {
                  final name = s['name'] ?? 'Usuário';
                  final avatar = s['avatar_url'];
                  final count = s['count'] as int;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.surface,
                      backgroundImage:
                          avatar != null ? CachedNetworkImageProvider(avatar) : null,
                      child: avatar == null
                          ? Text(name.substring(0, 1).toUpperCase())
                          : null,
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$count story${count > 1 ? "s" : ""}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoryViewerScreen(
                            userId: s['user_id'],
                            userName: name,
                            userAvatarUrl: avatar,
                          ),
                        ),
                      );
                    },
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
