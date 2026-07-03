// lib/core/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// 1. Cadastro: cria a conta e dispara o e-mail com o código de 6 dígitos
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName},
    );
  }

  /// 2. Confirma o código recebido por e-mail após o cadastro
  Future<AuthResponse> verifySignUpCode({
    required String email,
    required String code,
  }) async {
    final response = await _client.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.signup,
    );
    return response;
  }

  /// Login normal com e-mail e senha (depois que a conta já foi verificada)
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return response;
  }

  /// 1. Esqueci senha: dispara e-mail com código de 6 dígitos
  Future<void> sendPasswordResetCode({required String email}) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  /// 2. Confirma o código de recuperação (abre uma sessão temporária)
  Future<AuthResponse> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    final response = await _client.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.recovery,
    );
    return response;
  }

  /// 3. Define a nova senha (chamado logo após verifyPasswordResetCode)
  Future<UserResponse> updatePassword({required String newPassword}) async {
    final response = await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    return response;
  }

  Future<void> resendSignUpCode({required String email}) async {
    await _client.auth.resend(type: OtpType.signup, email: email.trim());
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  bool get isLoggedIn => currentUser != null;
}
