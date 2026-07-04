import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/services/story_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/stories/duration_sheet.dart';

class StoryPreviewScreen extends StatefulWidget {
  const StoryPreviewScreen({super.key, required this.imageFile});
  final File imageFile;

  @override
  State<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends State<StoryPreviewScreen> {
  final _storyService = StoryService();
  final _captionController = TextEditingController();
  Duration _duration = const Duration(hours: 24);
  bool _publishing = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);
    try {
      final url = await _storyService.uploadStoryImage(widget.imageFile);
      await _storyService.createImageStory(
        mediaUrl: url,
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        duration: _duration,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.file(widget.imageFile, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Novo Story',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 90,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.15)),
                            ),
                            child: TextField(
                              controller: _captionController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Adicionar legenda...',
                                hintStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DurationPickerButton(
                      duration: _duration,
                      onChanged: (d) => setState(() => _duration = d),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 24,
              child: ElevatedButton.icon(
                onPressed: _publishing ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: _publishing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 18),
                label: const Text('Publicar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
