import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/google_auth_config.dart';

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
/// True once the signed-in user still needs to choose a username — gates
/// them into /onboarding/username regardless of how they signed up (email,
/// Google, Apple), and catches accounts created before usernames existed.
/// Read from the cached auth user's metadata rather than a DB round-trip,
/// so it's cheap enough to check on every route change.
final needsUsernameProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final username = user.userMetadata?['username'] as String?;
  return username == null || username.trim().isEmpty;
});

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

  /// Updates the display name Supabase Auth holds on the user (surfaced as
  /// `userMetadata['name']` — see currentUserProvider consumers like the
  /// home screen's greeting). Settings also writes the same name to
  /// `profiles.name` via ProfileRepository.updateName, since that's the
  /// field public_profiles (community posts, comments, chat) reads from —
  /// the two aren't the same underlying column.
  Future<void> updateDisplayName(String name) {
    return _client.auth.updateUser(UserAttributes(data: {'name': name}));
  }

  /// Mirrors the @handle into auth user metadata alongside
  /// ProfileRepository.updateUsername's write to `profiles.username` — this
  /// copy is what [needsUsernameProvider] checks, since it's already loaded
  /// with the session (no extra DB round-trip needed just to gate routing).
  Future<void> updateUsernameMetadata(String username) {
    return _client.auth.updateUser(UserAttributes(data: {'username': username}));
  }

  /// Signs in with Google via the native Google Sign-In SDK, then exchanges
  /// the resulting ID token for a Supabase session.
  ///
  /// Requires [GoogleAuthConfig.webClientId] — see README.md for how to
  /// create it and wire it into the Supabase dashboard.
  Future<AuthResponse> signInWithGoogle() async {
    if (!GoogleAuthConfig.isConfigured) {
      throw const AuthException(
        'Google sign-in is not configured. See README.md.',
      );
    }

    final googleSignIn = GoogleSignIn(
      clientId: GoogleAuthConfig.iosClientId.isNotEmpty
          ? GoogleAuthConfig.iosClientId
          : null,
      serverClientId: GoogleAuthConfig.webClientId,
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw const AuthException(
        'Google sign-in failed: no ID token returned.',
      );
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  /// Signs in with Apple via the native Sign in with Apple flow, then
  /// exchanges the resulting ID token for a Supabase session.
  ///
  /// The raw/hashed nonce pair guards against replay attacks: Apple signs
  /// the hashed nonce into the ID token, and Supabase re-hashes the raw
  /// nonce we send alongside it to confirm they match.
  Future<AuthResponse> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('Apple sign-in failed: no ID token returned.');
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}

String _generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._~';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => charset[random.nextInt(charset.length)],
  ).join();
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(supabaseProvider));
});
