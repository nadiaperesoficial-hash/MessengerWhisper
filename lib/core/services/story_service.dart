import 'dart:io';
import 'package:supabase/supabase.dart' as raw_supabase;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

class StoryService {
  final SupabaseClient _client = Supabase.instance.client;

  final raw_supabase.SupabaseClient _clientB = raw_supabase.SupabaseClient(
    Env.supabaseBUrl,
    Env.supabaseBAnonKey,
  );

  Future<String> uploadStoryImage(File file) async {
    final ext = file.path.split('.').last.toLowerCase();

    final response = await _client.functions.invoke(
      'hyper-worker',
      body: {'fileExt': ext, 'folder': 'stories'},
    );

    if (response.status != 200) {
      throw Exception('Falha ao preparar upload (${response.status}): ${response.data}');
    }

    final data = response.data;
    final path = data is Map ? data['path'] as String? : null;
    final token = data is Map ? data['token'] as String? : null;
    final publicUrl = data is Map ? data['publicUrl'] as String? : null;

    if (path == null || token == null || publicUrl == null) {
      throw Exception('Resposta inesperada da função: $data');
    }

    final bytes = await file.readAsBytes();
    await _clientB.storage.from('media').uploadToSignedUrl(path, token, bytes);

    return publicUrl;
  }

  Future<void> createImageStory({
    required String mediaUrl,
    String? caption,
    required Duration duration,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('stories').insert({
      'user_id': userId,
      'media_url': mediaUrl,
      'caption': caption,
      'type': 'image',
      'expires_at': DateTime.now().toUtc().add(duration).toIso8601String(),
    });
  }

  Future<void> createTextStory({
    required String text,
    required String backgroundColorHex,
    required Duration duration,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('stories').insert({
      'user_id': userId,
      'media_url': '',
      'caption': text,
      'type': 'text',
      'background_color': backgroundColorHex,
      'expires_at': DateTime.now().toUtc().add(duration).toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchGroupedStories() {
    return _withRetryOnClockSkew(() => _fetchGroupedStoriesInternal());
  }

  Future<List<Map<String, dynamic>>> _fetchGroupedStoriesInternal() async {
    try {
      final myId = _client.auth.currentUser!.id;

      final rows = await _client
          .from('stories')
          .select('*, profiles!stories_user_id_fkey(id, display_name, avatar_url)')
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(rows);
      if (list.isEmpty) return [];

      final storyIds = list.map((s) => s['id'] as String).toList();
      final views = await _client
          .from('story_views')
          .select('story_id')
          .eq('viewer_id', myId)
          .inFilter('story_id', storyIds);
      final viewedIds = List<Map<String, dynamic>>.from(views)
          .map((v) => v['story_id'] as String)
          .toSet();

      final Map<String, Map<String, dynamic>> grouped = {};

      for (final story in list) {
        final userId = story['user_id'] as String;
        final storyId = story['id'] as String;
        final isSeen = viewedIds.contains(storyId);

        if (!grouped.containsKey(userId)) {
          grouped[userId] = {
            'user_id': userId,
            'name': story['profiles']['display_name'] ?? 'Usuário',
            'avatar_url': story['profiles']['avatar_url'],
            'latest_media_url': story['media_url'],
            'latest_type': story['type'],
            'latest_created_at': story['created_at'],
            'count': 1,
            'all_seen': isSeen,
          };
        } else {
          grouped[userId]!['count'] = (grouped[userId]!['count'] as int) + 1;
          if (!isSeen) grouped[userId]!['all_seen'] = false;
        }
      }

      return grouped.values.toList();
    } on PostgrestException catch (e) {
      throw Exception('Erro ao buscar stories: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchStoriesForUser(String userId) async {
    final rows = await _client
        .from('stories')
        .select('*, profiles!stories_user_id_fkey(id, display_name, avatar_url)')
        .eq('user_id', userId)
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> markStoryAsViewed(String storyId) async {
    final myId = _client.auth.currentUser!.id;
    try {
      await _client.from('story_views').insert({
        'story_id': storyId,
        'viewer_id': myId,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
    }
  }

  Future<bool> isLikedByMe(String storyId) async {
    final myId = _client.auth.currentUser!.id;
    final rows = await _client
        .from('story_likes')
        .select()
        .eq('story_id', storyId)
        .eq('user_id', myId);
    return (rows as List).isNotEmpty;
  }

  Future<void> likeStory(String storyId) async {
    final myId = _client.auth.currentUser!.id;
    await _client.from('story_likes').insert({
      'story_id': storyId,
      'user_id': myId,
    });
  }

  Future<void> unlikeStory(String storyId) async {
    final myId = _client.auth.currentUser!.id;
    await _client
        .from('story_likes')
        .delete()
        .eq('story_id', storyId)
        .eq('user_id', myId);
  }

  Future<T> _withRetryOnClockSkew<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST303') {
        await Future.delayed(const Duration(seconds: 2));
        try {
          await _client.auth.refreshSession();
        } catch (_) {}
        return await action();
      }
      rethrow;
    }
  }
}
