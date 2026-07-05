import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/services/profile_service.dart';
import '../core/services/chat_service.dart';
import '../core/theme/app_theme.dart';
import 'chat/chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _profileService = ProfileService();
  final _chatService = ChatService();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _allContacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  bool _loading = true;
  bool _opening = false;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadContacts() async {
    final contacts = await _profileService.fetchContacts();
    if (!mounted) return;
    setState(() {
      _allContacts = contacts;
      _filteredContacts = contacts;
      _loading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredContacts = _allContacts);
      return;
    }
    setState(() {
      _filteredContacts = _allContacts.where((c) {
        final name = (c['display_name'] ?? '').toString().toLowerCase();
        final email = (c['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  Future<void> _startChat(String contactId, String contactName, String? contactAvatar) async {
    setState(() => _opening = true);
    try {
      final chatId = await _chatService.getOrCreateOneToOneChat(contactId);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherUserName: contactName,
            otherUserAvatarUrl: contactAvatar,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao iniciar conversa: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nome ou e-mail',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  filled: false,
                ),
              )
            : const Text('Nova conversa'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_searching) {
                  _searchController.clear();
                }
                _searching = !_searching;
              });
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filteredContacts.isEmpty
              ? const Center(child: Text('Nenhum contato encontrado ainda.'))
              : ListView.builder(
                  itemCount: _filteredContacts.length,
                  itemBuilder: (context, i) {
                    final c = _filteredContacts[i];
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
                      onTap: _opening ? null : () => _startChat(c['id'], name, avatar),
                    );
                  },
                ),
    );
  }
}
