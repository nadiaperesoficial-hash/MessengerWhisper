import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaUploadService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> uploadImage(File file, {required String folder}) async {
    final bytes = await file.readAsBytes();
    final base64Data = base64Encode(bytes);
    final ext = file.path.split('.').last.toLowerCase();

    final response = await _client.functions.invoke(
      'hyper-worker',
      body: {
        'base64Data': base64Data,
        'fileExt': ext,
        'folder': folder,
      },
    );

    if (response.status != 200) {
      throw Exception('Falha no upload (${response.status}): ${response.data}');
    }

    final data = response.data;
    final url = data is Map ? data['url'] as String? : null;
    if (url == null) {
      throw Exception('Resposta inesperada da função de upload: $data');
    }
    return url;
  }
}
