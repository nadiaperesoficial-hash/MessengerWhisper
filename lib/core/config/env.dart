class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const supabaseBUrl = String.fromEnvironment('SUPABASE_B_URL');
  static const supabaseBAnonKey = String.fromEnvironment('SUPABASE_B_ANON_KEY');
  static const agoraAppId = String.fromEnvironment('AGORA_APP_ID');
  static const giphyApiKey = String.fromEnvironment('GIPHY_API_KEY');

  static bool get isValid =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      agoraAppId.isNotEmpty &&
      giphyApiKey.isNotEmpty;
}
