import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoryService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> uploadStoryImage(File file) async {
    final userId = _client.auth.currentUser!.id;
    final ext = file.path.split('.').last;
    final path = '$userId/stories/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('media').upload(path, file);
    return _client.storage.from('media').getPublicUrl(path);
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
      'expires_at': DateTime.now().add(duration).toIso8601String(),
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
      'expires_at': DateTime.now().add(duration).toIso8601String(),
    });
  }

  /// Retorna as stories não expiradas, agrupadas por usuário (a mais recente primeiro em cada grupo).
  Future<List<Map<String, dynamic>>> fetchGroupedStories() async {
    final rows = await _client
        .from('stories')
        .select('*, profiles!inner(id, display_name, avatar_url)')
        .gt('expires_at', DateTime.now().toIso8601String())
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
  }
}
