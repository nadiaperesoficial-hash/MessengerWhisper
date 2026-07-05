import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCaptionField extends StatelessWidget {
  const GlassCaptionField({
    super.key,
    required this.controller,
    this.hintText = 'Adicionar legenda...',
    this.enabled = true,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.20),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            onSubmitted: onSubmitted,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.white70),
              // Força ignorar o tema global (filled/fillColor do app),
              // senão o campo fica com fundo branco sólido por cima do blur.
              filled: false,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}
