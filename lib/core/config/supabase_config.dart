/// Supabase project credentials, injected at build/run time via
/// `--dart-define=SUPABASE_URL=...` and
/// `--dart-define=SUPABASE_PUBLISHABLE_KEY=...`.
///
/// No live Supabase project exists yet for this app — see README.md for
/// setup steps. Until then these default to empty strings and
/// [SupabaseConfig.isConfigured] is false.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
