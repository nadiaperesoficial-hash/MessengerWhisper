Future<List<Map<String, dynamic>>> fetchGroupedStories() async {
    try {
      final rows = await _client
          .from('stories')
          .select('*, profiles!inner(id, display_name, avatar_url)')
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
      // Repassa o erro real em vez de engolir e mostrar lista vazia.
      throw Exception('Erro ao buscar stories: $e');
    }
  }
