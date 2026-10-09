class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://smyvqoudgbfqxdnwcxer.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_ScATXmM-3lsJOy5FJGxYvA_tzqjaqG7',
  );

  static bool get isConfigured =>
      url.startsWith('https://') &&
      publishableKey.startsWith('sb_publishable_');
}
