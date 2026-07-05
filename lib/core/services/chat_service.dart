import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> getOrCreateOneToOneChat(String otherUserId) async {
    final myId = _client.auth.currentUser!.id;

    final myChats =
        await _client.from('chat_participants').select('chat_id').eq('user_id', myId);
    final myChatIds = (myChats as List).map((e) => e['chat_id'] as String).toList();

    if (myChatIds.isNotEmpty) {
      final shared = await _client
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', otherUserId)
          .inFilter('chat_id', myChatIds);
      if ((shared as List).isNotEmpty) {
        return shared.first['chat_id'] as String;
      }
    }

    final newChat =
        await _client.from('chats').insert({'is_group': false, 'created_by': myId}).select().single();
    final chatId = newChat['id'] as String;

    await _client.from('chat_participants').insert([
      {'chat_id': chatId, 'user_id': myId},
      {'chat_id': chatId, 'user_id': otherUserId},
    ]);

    return chatId;
  }

  Future<void> sendTextMessage(String chatId, String content) async {
    final myId = _client.auth.currentUser!.id;
    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': myId,
      'content': content,
      'type': 'text',
    });
  }

  Future<List<Map<String, dynamic>>> fetchMyChats() async {
    return _withRetryOnClockSkew(() => _fetchMyChatsInternal());
  }

  Future<List<Map<String, dynamic>>> _fetchMyChatsInternal() async {
    final myId = _client.auth.currentUser!.id;

    final myParticipations =
        await _client.from('chat_participants').select('chat_id').eq('user_id', myId);
    final chatIds =
        List<Map<String, dynamic>>.from(myParticipations).map((e) => e['chat_id'] as String).toList();

    if (chatIds.isEmpty) return [];

    final results = <Map<String, dynamic>>[];

    for (final chatId in chatIds) {
      final others = await _client
          .from('chat_participants')
          .select('user_id, profiles!inner(id, display_name, avatar_url)')
          .eq('chat_id', chatId)
          .neq('user_id', myId);

      if ((others as List).isEmpty) continue;
      final other = others.first;

      final lastMessage = await _client
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      results.add({
        'chat_id': chatId,
        'other_user_id': other['profiles']['id'],
        'other_user_name': other['profiles']['display_name'] ?? 'Usuário',
        'other_user_avatar': other['profiles']['avatar_url'],
        'last_message_content': lastMessage?['content'],
        'last_message_type': lastMessage?['type'],
        'last_message_at': lastMessage?['created_at'],
      });
    }

    results.sort((a, b) {
      final aTime = a['last_message_at'] ?? '';
      final bTime = b['last_message_at'] ?? '';
      return bTime.compareTo(aTime);
    });

    return results;
  }

  /// Tenta de novo automaticamente se o servidor rejeitar o token por
  /// diferença momentânea de horário (erro PGRST303), renovando a sessão
  /// antes de repetir a chamada — sem mostrar erro pro usuário nesse caso.
  Future<T> _withRetryOnClockSkew<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST303') {
        await Future.delayed(const Duration(seconds: 2));
        try {
          await _client.auth.refreshSession();
        } catch (_) {
          // Ignora falha de refresh, tenta a ação de novo mesmo assim.
        }
        return await action();
      }
      rethrow;
    }
  }
}
