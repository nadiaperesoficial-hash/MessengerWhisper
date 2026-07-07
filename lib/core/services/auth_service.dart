import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

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

  /// Login com e-mail ou username + senha. Se o texto digitado não tiver
  /// "@", trata como username e resolve o e-mail correspondente primeiro.
  Future<AuthResponse> signIn({
    required String identifier,
    required String password,
  }) async {
    String email = identifier.trim();

    if (!email.contains('@')) {
      final result = await _client.rpc(
        'get_email_for_username',
        params: {'p_username': email.toLowerCase()},
      );
      if (result == null) {
        throw const AuthException('Usuário não encontrado.');
      }
      email = result as String;
    }

    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<void> sendPasswordResetCode({required String email}) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

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
