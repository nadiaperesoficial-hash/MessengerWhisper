import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Cadastro com e-mail e senha
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName},
    );
    return response;
  }

  /// Login com e-mail e senha
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

  /// Esqueci a senha: envia e-mail com link de redefinição
  Future<void> forgotPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'io.supabase.messengerapp://reset-callback',
    );
  }

  /// Chamado na tela de "nova senha" depois que o usuário abre o link do e-mail
  Future<UserResponse> updatePassword({required String newPassword}) async {
    final response = await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  bool get isLoggedIn => currentUser != null;
}
