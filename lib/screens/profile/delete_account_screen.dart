import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_theme.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _profileService = ProfileService();
  final _confirmController = TextEditingController();
  bool _deleting = false;

  bool get _canDelete => _confirmController.text.trim().toUpperCase() == 'EXCLUIR';

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      await _profileService.deleteAllMyData();
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível excluir a conta.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Excluir conta')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Essa ação apaga seu perfil, mensagens, stories e curtidas. Não pode ser desfeita.',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 24),
            const Text('Digite EXCLUIR para confirmar:',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'EXCLUIR'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: (_canDelete && !_deleting) ? _delete : null,
                child: _deleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Excluir minha conta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
