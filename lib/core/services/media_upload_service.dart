import 'dart:io';
import 'package:supabase/supabase.dart' as raw_supabase;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

class MediaUploadService {
  final SupabaseClient _client = Supabase.instance.client;

  final raw_supabase.SupabaseClient _clientB = raw_supabase.SupabaseClient(
    Env.supabaseBUrl,
    Env.supabaseBAnonKey,
  );

  Future<String> uploadImage(File file, {required String folder}) async {
    final ext = file.path.split('.').last.toLowerCase();

    final response = await _client.functions.invoke(
      'hyper-worker',
      body: {'fileExt': ext, 'folder': folder},
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
}
