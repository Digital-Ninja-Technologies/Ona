import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/auth_controller.dart';
import '../models/public_profile.dart';

/// Thrown by [ProfileRepository.updateUsername] when the chosen username is
/// already taken (case-insensitively) by another account.
class UsernameTakenException implements Exception {
  const UsernameTakenException();
}

/// The signed-in user's own profile row (name + photo) — as opposed to
/// public_profiles_repository.dart, which fetches *other* users' public
/// info for display in community posts, comments, and chat.
class ProfileRepository {
  ProfileRepository(this._ref);

  final Ref _ref;

  String get _userId {
    final userId = _ref.read(supabaseProvider).auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot access a profile without a signed-in user.');
    }
    return userId;
  }

  Future<PublicProfile> fetchMyProfile() async {
    final client = _ref.read(supabaseProvider);
    final row = await client
        .from('profiles')
        .select(
          'id, name, username, profile_image, followers_count, following_count',
        )
        .eq('id', _userId)
        .single();
    return PublicProfile.fromJson(row);
  }

  Future<void> updateName(String name) async {
    final client = _ref.read(supabaseProvider);
    await client.from('profiles').update({'name': name}).eq('id', _userId);
  }

  /// Sets the signed-in user's @handle. Throws [UsernameTakenException] if
  /// it collides (case-insensitively) with an existing one — see the unique
  /// index in 0009_usernames.sql.
  Future<void> updateUsername(String username) async {
    final client = _ref.read(supabaseProvider);
    try {
      await client
          .from('profiles')
          .update({'username': username})
          .eq('id', _userId);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const UsernameTakenException();
      rethrow;
    }
  }

  Future<void> updateProfileImage(String imageUrl) async {
    final client = _ref.read(supabaseProvider);
    await client
        .from('profiles')
        .update({'profile_image': imageUrl})
        .eq('id', _userId);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref);
});

final myProfileProvider = FutureProvider.autoDispose<PublicProfile>((ref) {
  return ref.watch(profileRepositoryProvider).fetchMyProfile();
});
