import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Retorna o id de uma conversa 1:1 existente com esse contato, ou cria uma nova.
  Future<String> getOrCreateOneToOneChat(String otherUserId) async {
    final myId = _client.auth.currentUser!.id;

    final myChats = await _client
        .from('chat_participants')
        .select('chat_id')
        .eq('user_id', myId);

    final myChatIds =
        (myChats as List).map((e) => e['chat_id'] as String).toList();

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

    final newChat = await _client
        .from('chats')
        .insert({'is_group': false, 'created_by': myId})
        .select()
        .single();

    final chatId = newChat['id'] as String;

    await _client.from('chat_participants').insert([
      {'chat_id': chatId, 'user_id': myId},
      {'chat_id': chatId, 'user_id': otherUserId},
    ]);

    return chatId;
  }

  /// Envia uma mensagem de texto simples numa conversa já existente.
  Future<void> sendTextMessage(String chatId, String content) async {
    final myId = _client.auth.currentUser!.id;
    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': myId,
      'content': content,
      'type': 'text',
    });
  }
}
