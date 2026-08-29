/// Google Sign-In OAuth client IDs, injected at build/run time via
/// `--dart-define=GOOGLE_WEB_CLIENT_ID=...` and, on iOS,
/// `--dart-define=GOOGLE_IOS_CLIENT_ID=...`.
///
/// The web client ID must also be added under Authentication → Providers →
/// Google → "Authorized Client IDs" in the Supabase dashboard, since that's
/// what Supabase checks the ID token's audience against. See README.md for
/// the full setup.
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const String iosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  static bool get isConfigured => webClientId.isNotEmpty;
}
