import 'dart:ui';
import 'package:flutter/material.dart';

class GlassMessageBar extends StatelessWidget {
  const GlassMessageBar({
    super.key,
    required this.controller,
    required this.hasText,
    required this.isRecording,
    required this.onEmoji,
    required this.onCamera,
    required this.onGallery,
    required this.onGif,
    required this.onSend,
    required this.onMicStart,
    required this.onMicEnd,
    this.emojiActive = false,
  });

  final TextEditingController controller;
  final bool hasText;
  final bool isRecording;
  final bool emojiActive;
  final VoidCallback onEmoji;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onGif;
  final VoidCallback onSend;
  final ValueChanged<LongPressStartDetails> onMicStart;
  final ValueChanged<LongPressEndDetails> onMicEnd;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  emojiActive ? Icons.keyboard_outlined : Icons.emoji_emotions_outlined,
                  color: const Color(0xFF3A3A3A),
                ),
                onPressed: onEmoji,
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF3A3A3A)),
                onPressed: onCamera,
              ),
              IconButton(
                icon: const Icon(Icons.photo_outlined, color: Color(0xFF3A3A3A)),
                onPressed: onGallery,
              ),
              IconButton(
                icon: const Icon(Icons.gif_box_outlined, color: Color(0xFF3A3A3A)),
                onPressed: onGif,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: 5,
                  minLines: 1,
                  style: const TextStyle(color: Color(0xFF2C2C2C), fontSize: 15),
                  cursorColor: const Color(0xFF2C2C2C),
                  decoration: const InputDecoration(
                    hintText: 'Mensagem',
                    hintStyle: TextStyle(color: Color(0xFF6B6B6B)),
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              GestureDetector(
                onLongPressStart: hasText ? null : onMicStart,
                onLongPressEnd: hasText ? null : onMicEnd,
                onTap: hasText ? onSend : null,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: CircleAvatar(
                    radius: 19,
                    backgroundColor:
                        isRecording ? const Color(0xFFE23744) : const Color(0xFF00C300),
                    child: Icon(
                      hasText ? Icons.send : Icons.mic,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
