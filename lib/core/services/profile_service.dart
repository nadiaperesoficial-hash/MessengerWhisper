import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchContacts() async {
    final currentUserId = _client.auth.currentUser?.id;
    final response = await _client
        .from('profiles')
        .select()
        .neq('id', currentUserId ?? '')
        .order('display_name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> fetchMyProfile() async {
    final userId = _client.auth.currentUser!.id;
    final response =
        await _client.from('profiles').select().eq('id', userId).single();
    return response;
  }

  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    final userId = _client.auth.currentUser!.id;
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (updates.isEmpty) return;
    await _client.from('profiles').update(updates).eq('id', userId);
  }

  Future<String> uploadAvatar(File file) async {
    final userId = _client.auth.currentUser!.id;
    final ext = file.path.split('.').last;
    final path = '$userId/avatar.$ext';
    await _client.storage
        .from('media')
        .upload(path, file, fileOptions: const FileOptions(upsert: true));
    return _client.storage.from('media').getPublicUrl(path);
  }

  /// Apaga todos os dados do usuário (perfil, mensagens, stories, curtidas).
  /// A conta de login em si (auth.users) continua existindo — só o app
  /// desloga em seguida. Remoção completa exige ação manual no painel
  /// do Supabase ou uma Edge Function (não incluída nessa etapa).
  Future<void> deleteAllMyData() async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('story_likes').delete().eq('user_id', userId);
    await _client.from('stories').delete().eq('user_id', userId);
    await _client.from('messages').delete().eq('sender_id', userId);
    await _client.from('calls').delete().eq('caller_id', userId);
    await _client
        .from('chats')
        .update({'created_by': null}).eq('created_by', userId);
    await _client.from('chat_participants').delete().eq('user_id', userId);
    await _client.from('profiles').delete().eq('id', userId);
  }
}
