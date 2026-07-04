import 'package:flutter/material.dart';
import '../../core/services/story_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/stories/duration_sheet.dart';

class TextStoryScreen extends StatefulWidget {
  const TextStoryScreen({super.key});

  @override
  State<TextStoryScreen> createState() => _TextStoryScreenState();
}

class _TextStoryScreenState extends State<TextStoryScreen> {
  final _storyService = StoryService();
  final _textController = TextEditingController();
  Duration _duration = const Duration(hours: 24);
  bool _publishing = false;

  final List<Color> _colors = const [
    AppColors.primary,
    Color(0xFF1C1C28),
    Color(0xFFE23744),
    Color(0xFF0F9D58),
    Color(0xFFAA46BB),
  ];
  late Color _selectedColor = _colors.first;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_textController.text.trim().isEmpty) return;
    setState(() => _publishing = true);
    try {
      await _storyService.createTextStory(
        text: _textController.text.trim(),
        backgroundColorHex:
            '#${_selectedColor.value.toRadixString(16).substring(2)}',
        duration: _duration,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível publicar o story.'),
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
      backgroundColor: _selectedColor,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                DurationPickerButton(
                  duration: _duration,
                  onChanged: (d) => setState(() => _duration = d),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'Digite algo...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _colors.map((c) {
                  final selected = c == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: selected ? 34 : 28,
                      height: selected ? 34 : 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: selected ? 3 : 1.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _publishing ? null : _publish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _selectedColor,
                    minimumSize: const Size(0, 52),
                  ),
                  child: _publishing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: _selectedColor, strokeWidth: 2),
                        )
                      : const Text('Publicar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
