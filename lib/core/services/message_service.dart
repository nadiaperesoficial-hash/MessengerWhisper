import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_db_service.dart';

class MessageService {
  final SupabaseClient _client = Supabase.instance.client;
  final LocalDbService _localDb = LocalDbService();

  RealtimeChannel? _channel;

  Future<List<Map<String, dynamic>>> loadLocalHistory(String chatId) {
    return _localDb.fetchMessages(chatId);
  }

  Future<void> sendTextMessage(String chatId, String content) async {
    final myId = _client.auth.currentUser!.id;
    final inserted = await _client
        .from('messages')
        .insert({
          'chat_id': chatId,
          'sender_id': myId,
          'content': content,
          'type': 'text',
          'delivered_to': [myId],
        })
        .select()
        .single();
    await _localDb.insertMessage(inserted);
  }

  Future<String> uploadChatImage(File file) async {
    final userId = _client.auth.currentUser!.id;
    final ext = file.path.split('.').last;
    final path = '$userId/chats/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from('media').upload(path, file);
    return _client.storage.from('media').getPublicUrl(path);
  }

  Future<void> sendImageMessage(String chatId, String mediaUrl) async {
    final myId = _client.auth.currentUser!.id;
    final inserted = await _client
        .from('messages')
        .insert({
          'chat_id': chatId,
          'sender_id': myId,
          'type': 'image',
          'media_url': mediaUrl,
          'delivered_to': [myId],
        })
        .select()
        .single();
    await _localDb.insertMessage(inserted);
  }

  Future<void> markChatAsRead(String chatId) async {
    final myId = _client.auth.currentUser!.id;
    await _client.rpc('mark_chat_read', params: {
      'p_chat_id': chatId,
      'p_user_id': myId,
    });
  }

  void subscribeToChat(
    String chatId, {
    required void Function(Map<String, dynamic>) onNewMessage,
    required void Function(String messageId) onMessageRead,
  }) {
    _channel = _client.channel('messages-$chatId');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) async {
            final row = payload.newRecord;
            await _handleIncomingMessage(chatId, row);
            onNewMessage(row);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) async {
            final row = payload.newRecord;
            final myId = _client.auth.currentUser!.id;
            final readBy = List<String>.from(row['read_by'] ?? []);
            if (row['sender_id'] == myId && readBy.isNotEmpty) {
              final readAt = DateTime.now().toIso8601String();
              await _localDb.markMessageRead(row['id'], readAt);
              onMessageRead(row['id']);
            }
          },
        )
        .subscribe();
  }

  Future<void> _handleIncomingMessage(String chatId, Map<String, dynamic> row) async {
    final myId = _client.auth.currentUser!.id;
    if (row['sender_id'] == myId) return;

    await _localDb.insertMessage(row);

    final delivered = List<String>.from(row['delivered_to'] ?? []);
    final readBy = List<String>.from(row['read_by'] ?? []);
    if (!delivered.contains(myId)) delivered.add(myId);
    if (!readBy.contains(myId)) readBy.add(myId);

    await _client
        .from('messages')
        .update({'delivered_to': delivered, 'read_by': readBy}).eq('id', row['id']);

    await _tryDeleteIfFullyDelivered(chatId, row['id'], delivered);
  }

  Future<void> _tryDeleteIfFullyDelivered(
      String chatId, String messageId, List<String> deliveredTo) async {
    final participants =
        await _client.from('chat_participants').select('user_id').eq('chat_id', chatId);
    final participantIds =
        List<Map<String, dynamic>>.from(participants).map((p) => p['user_id'] as String).toList();

    final messageRow =
        await _client.from('messages').select('sender_id').eq('id', messageId).maybeSingle();
    if (messageRow == null) return;

    final senderId = messageRow['sender_id'] as String;
    final recipients = participantIds.where((id) => id != senderId).toList();
    final allDelivered = recipients.every((id) => deliveredTo.contains(id));

    if (allDelivered) {
      await _client.from('messages').delete().eq('id', messageId);
    }
  }

  void unsubscribe() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
      _channel = null;
    }
  }
}
