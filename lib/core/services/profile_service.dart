import 'dart:io';
import 'package:supabase/supabase.dart' as raw_supabase;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  final raw_supabase.SupabaseClient _clientB = raw_supabase.SupabaseClient(
    Env.supabaseBUrl,
    Env.supabaseBAnonKey,
  );

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

  Future<void> updateUsername(String newUsername) async {
    final userId = _client.auth.currentUser!.id;
    final clean = newUsername.trim().toLowerCase();
    try {
      await _client.from('profiles').update({'username': clean}).eq('id', userId);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Esse nome de usuário já está em uso.');
      }
      throw Exception(e.message);
    }
  }

  Future<String> uploadAvatar(File file) async {
    final ext = file.path.split('.').last.toLowerCase();

    final response = await _client.functions.invoke(
      'hyper-worker',
      body: {'fileExt': ext, 'folder': 'avatars'},
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

  Future<void> deleteAllMyData() async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('story_views').delete().eq('viewer_id', userId);
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
