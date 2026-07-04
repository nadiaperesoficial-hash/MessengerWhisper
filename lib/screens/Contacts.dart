import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/services/profile_service.dart';
import '../core/theme/app_theme.dart';

class Contacts extends StatefulWidget {
  Contacts(this.listType, {super.key});
  final String listType;

  @override
  State<Contacts> createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  final _profileService = ProfileService();
  late Future<List<Map<String, dynamic>>> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _contactsFuture = _profileService.fetchContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Contatos',
          style: TextStyle(color: Colors.white),
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
              final status = c['status'] ?? 'offline';
              return Card(
                elevation: 1.0,
                color: Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surface,
                    backgroundImage: avatar != null
                        ? CachedNetworkImageProvider(avatar)
                        : null,
                    child: avatar == null
                        ? Text(name.substring(0, 1).toUpperCase())
                        : null,
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    status == 'online' ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: status == 'online' ? Colors.green : Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
