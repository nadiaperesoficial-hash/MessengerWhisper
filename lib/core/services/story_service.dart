import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'media_upload_service.dart';

class StoryService {
  final SupabaseClient _client = Supabase.instance.client;
  final MediaUploadService _mediaUploadService = MediaUploadService();

  Future<String> uploadStoryImage(File file) async {
    return _mediaUploadService.uploadImage(file, folder: 'stories');
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

  Future<int> debugCountStoriesNoJoin() async {
    final rows = await _client
        .from('stories')
        .select('id')
        .gt('expires_at', DateTime.now().toUtc().toIso8601String());
    return (rows as List).length;
  }

  Future<int> debugCountStoriesWithJoin() async {
    final rows = await _client
        .from('stories')
        .select('id, profiles!stories_user_id_fkey(id)')
        .gt('expires_at', DateTime.now().toUtc().toIso8601String());
    return (rows as List).length;
  }

  Future<List<Map<String, dynamic>>> fetchGroupedStories() async {
    try {
      final rows = await _client
          .from('stories')
          .select('*, profiles!stories_user_id_fkey(id, display_name, avatar_url)')
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(rows);
      final Map<String, Map<String, dynamic>> grouped = {};

      for (final story in list) {
        final userId = story['user_id'] as String;
        if (!grouped.containsKey(userId)) {
          grouped[userId] = {
            'user_id': userId,
            'name': story['profiles']['display_name'] ?? 'Usuário',
            'avatar_url': story['profiles']['avatar_url'],
            'latest_media_url': story['media_url'],
            'latest_type': story['type'],
            'latest_created_at': story['created_at'],
            'count': 1,
          };
        } else {
          grouped[userId]!['count'] = (grouped[userId]!['count'] as int) + 1;
        }
      }

      return grouped.values.toList();
    } catch (e) {
      throw Exception('Erro ao buscar stories: $e');
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
}
