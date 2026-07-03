import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/auth/primary_button.dart';
import 'reset_password_screen.dart';

enum OtpFlow { signup, recovery }

class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({
    super.key,
    required this.email,
    required this.flow,
  });

  final String email;
  final OtpFlow flow;

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _authService = AuthService();
  final _codeController = TextEditingController();
  bool _loading = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _resend() async {
    if (widget.flow == OtpFlow.signup) {
      await _authService.resendSignUpCode(email: widget.email);
    } else {
      await _authService.sendPasswordResetCode(email: widget.email);
    }
    _startCooldown();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código reenviado.')),
    );
  }

  Future<void> _handleVerify() async {
    if (_codeController.text.trim().length != 6) {
      _showError('Digite o código de 6 dígitos.');
      return;
    }
    setState(() => _loading = true);

    try {
      if (widget.flow == OtpFlow.signup) {
        await _authService.verifySignUpCode(
          email: widget.email,
          code: _codeController.text.trim(),
        );
        if (!mounted) return;
        // AuthGate detecta a sessão criada e troca pro Dashboard sozinho.
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        await _authService.verifyPasswordResetCode(
          email: widget.email,
          code: _codeController.text.trim(),
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        );
      }
    } on AuthException catch (e) {
      _showError(e.message.contains('expired')
          ? 'Código expirado. Peça um novo.'
          : 'Código inválido.');
    } catch (_) {
      _showError('Não foi possível verificar o código.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ListView(
            children: [
              const Icon(Icons.mark_email_read_outlined,
                  color: AppColors.primary, size: 56),
              const SizedBox(height: 20),
              const Text(
                'Verifique seu e-mail',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enviamos um código de 6 dígitos para ${widget.email}',
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Verificar',
                loading: _loading,
                onPressed: _handleVerify,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _cooldown == 0 ? _resend : null,
                  child: Text(
                    _cooldown == 0
                        ? 'Reenviar código'
                        : 'Reenviar em ${_cooldown}s',
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
