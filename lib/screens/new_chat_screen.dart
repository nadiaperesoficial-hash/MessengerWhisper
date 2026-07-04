import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/services/profile_service.dart';
import '../core/services/chat_service.dart';
import '../core/theme/app_theme.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _profileService = ProfileService();
  final _chatService = ChatService();
  late Future<List<Map<String, dynamic>>> _contactsFuture;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _contactsFuture = _profileService.fetchContacts();
  }

  Future<void> _startChat(String contactId, String contactName) async {
    setState(() => _opening = true);
    try {
      final chatId = await _chatService.getOrCreateOneToOneChat(contactId);
      if (!mounted) return;
      // A tela de conversa individual ainda não existe no app —
      // por enquanto confirmamos a criação. Próximo passo é construir essa tela.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversa com $contactName pronta (id: $chatId)')),
      );
      Navigator.pop(context);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível iniciar a conversa.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova conversa'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _contactsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum contato encontrado ainda.'));
          }
          final contacts = snapshot.data!;
          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, i) {
              final c = contacts[i];
              final name = c['display_name'] ?? c['email'] ?? 'Usuário';
              final avatar = c['avatar_url'];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.surface,
                  backgroundImage: avatar != null
                      ? CachedNetworkImageProvider(avatar)
                      : null,
                  child: avatar == null
                      ? Text(name.substring(0, 1).toUpperCase())
                      : null,
                ),
                title: Text(name),
                subtitle: Text(c['email'] ?? ''),
                onTap: _opening ? null : () => _startChat(c['id'], name),
              );
            },
          );
        },
      ),
    );
  }
}
