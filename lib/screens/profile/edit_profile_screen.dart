import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentAvatarUrl,
    required this.currentUsername,
    required this.usernameChangedAt,
  });

  final String currentName;
  final String? currentAvatarUrl;
  final String currentUsername;
  final String? usernameChangedAt;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profileService = ProfileService();
  late final _nameController = TextEditingController(text: widget.currentName);
  late final _usernameController = TextEditingController(text: widget.currentUsername);
  File? _newAvatarFile;
  bool _saving = false;

  bool get _canChangeUsername {
    if (widget.usernameChangedAt == null) return true;
    final changedAt = DateTime.tryParse(widget.usernameChangedAt!);
    if (changedAt == null) return true;
    return DateTime.now().difference(changedAt).inDays >= 30;
  }

  int get _daysUntilCanChange {
    if (widget.usernameChangedAt == null) return 0;
    final changedAt = DateTime.tryParse(widget.usernameChangedAt!);
    if (changedAt == null) return 0;
    final elapsed = DateTime.now().difference(changedAt).inDays;
    return (30 - elapsed).clamp(0, 30);
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _newAvatarFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      String? avatarUrl;
      if (_newAvatarFile != null) {
        avatarUrl = await _profileService.uploadAvatar(_newAvatarFile!);
      }
      await _profileService.updateProfile(
        displayName: _nameController.text.trim(),
        avatarUrl: avatarUrl,
      );

      final newUsername = _usernameController.text.trim().toLowerCase();
      if (_canChangeUsername && newUsername != widget.currentUsername) {
        await _profileService.updateUsername(newUsername);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.surface,
                    backgroundImage: _newAvatarFile != null
                        ? FileImage(_newAvatarFile!)
                        : (widget.currentAvatarUrl != null
                            ? CachedNetworkImageProvider(widget.currentAvatarUrl!)
                                as ImageProvider
                            : null),
                    child: _newAvatarFile == null && widget.currentAvatarUrl == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.lineGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Seu nome'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            enabled: _canChangeUsername,
            decoration: InputDecoration(
              hintText: 'Nome de usuário',
              prefixText: '@',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _canChangeUsername
                ? 'Pode trocar 1 vez a cada 30 dias.'
                : 'Você poderá trocar de usuário novamente em $_daysUntilCanChange dia(s).',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
