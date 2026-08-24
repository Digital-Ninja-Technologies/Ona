import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The custom URL scheme registered natively (Android intent-filter, iOS
/// CFBundleURLTypes) that Supabase redirects back into after a password
/// reset email is followed. Must also be added to the Supabase project's
/// Authentication → URL Configuration → Redirect URLs allowlist.
const passwordResetRedirectUrl = 'ona://reset-callback';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Emits the current auth session, updating on sign-in/sign-out/token
/// refresh/password recovery.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  return authState?.session?.user ?? Supabase.instance.client.auth.currentUser;
});

/// Whether the user is signed in, as a plain bool. Providers that only care
/// about signed-in/signed-out (like the router) should watch this instead
/// of [authStateProvider] directly — Riverpod only notifies watchers when
/// the emitted value actually changes, so this avoids rebuilding on every
/// stream event (e.g. a periodic token refresh) that doesn't flip the
/// signed-in status.
final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  return authState?.session != null ||
      Supabase.instance.client.auth.currentUser != null;
});

/// Whether the most recent auth event was a password-recovery deep link —
/// the router uses this to route to the "set a new password" screen
/// instead of home, even though the recovery link does establish a session.
final isPasswordRecoveryProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  return authState?.event == AuthChangeEvent.passwordRecovery;
});

class AuthController {
  AuthController(this._client);

  final SupabaseClient _client;

  Future<void> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: passwordResetRedirectUrl,
    );
  }

  Future<void> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() => _client.auth.signOut();
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(supabaseProvider));
});
