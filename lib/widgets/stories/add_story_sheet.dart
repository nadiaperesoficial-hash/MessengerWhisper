import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../screens/stories/story_preview_screen.dart';

/// Sheet simples: "Tirar Foto" ou "Escolher da Galeria".
/// Ao escolher, chama o image_picker nativo direto e, com a foto em mãos,
/// navega para a tela de preview do story.
Future<void> showAddStorySheet(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.textPrimary),
              title: const Text('Tirar Foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.textPrimary),
              title: const Text('Escolher da Galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      );
    },
  );

  if (source == null) return;
  if (!context.mounted) return;

  final picker = ImagePicker();
  final picked = await picker.pickImage(source: source, imageQuality: 85);
  if (picked == null) return;
  if (!context.mounted) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => StoryPreviewScreen(imageFile: File(picked.path)),
    ),
  );
}
