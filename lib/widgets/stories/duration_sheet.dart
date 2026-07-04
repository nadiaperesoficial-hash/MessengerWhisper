import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

Future<Duration?> showDurationSheet(BuildContext context, Duration current) {
  return showModalBottomSheet<Duration>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final options = <String, Duration>{
        '6 horas': const Duration(hours: 6),
        '12 horas': const Duration(hours: 12),
        '24 horas': const Duration(hours: 24),
      };

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Escolha por quanto tempo\no story ficará visível.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(height: 1),
            ...options.entries.map((entry) {
              final selected = entry.value == current;
              return ListTile(
                title: Text(entry.key,
                    style: const TextStyle(color: AppColors.textPrimary)),
                trailing: selected
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, entry.value),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
