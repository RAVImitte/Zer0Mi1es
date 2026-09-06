abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => envIsConfigured(supabaseUrl, supabaseAnonKey);
}

bool envIsConfigured(String url, String key) {
  if (url.isEmpty || key.isEmpty) return false;
  if (url.contains('placeholder')) return false;
  return true;
}
