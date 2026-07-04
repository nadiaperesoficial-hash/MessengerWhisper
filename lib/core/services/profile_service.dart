import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Lista todos os perfis exceto o do usuário logado (pra tela de Contatos e Nova Conversa)
  Future<List<Map<String, dynamic>>> fetchContacts() async {
    final currentUserId = _client.auth.currentUser?.id;
    final response = await _client
        .from('profiles')
        .select()
        .neq('id', currentUserId ?? '')
        .order('display_name');
    return List<Map<String, dynamic>>.from(response);
  }
}
