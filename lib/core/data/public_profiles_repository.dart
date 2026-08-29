import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/auth_controller.dart';
import '../models/public_profile.dart';

/// Batch-fetches public profiles (name/avatar only) for a set of user ids,
/// used to enrich community posts, comments, and conversations without
/// relying on PostgREST relationship embedding across the `public_profiles`
/// view (which isn't backed by a real foreign key).
Future<Map<String, PublicProfile>> fetchPublicProfiles(
  SupabaseClient client,
  Iterable<String> userIds,
) async {
  final ids = userIds.toSet().toList();
  if (ids.isEmpty) return {};
  final response = await client
      .from('public_profiles')
      .select()
      .inFilter('id', ids);
  final profiles = (response as List)
      .map((row) => PublicProfile.fromJson(row as Map<String, dynamic>))
      .toList();
  return {for (final profile in profiles) profile.id: profile};
}

PublicProfile profileOrFallback(
  Map<String, PublicProfile> profiles,
  String id,
) {
  return profiles[id] ?? PublicProfile(id: id);
}

/// One user's public profile (name, photo, follower/following counts) —
/// used by [UserProfileScreen]. Falls back to a bare [PublicProfile] (as
/// [profileOrFallback] does) if the row can't be found.
final userProfileProvider = FutureProvider.autoDispose
    .family<PublicProfile, String>((ref, userId) async {
      final client = ref.watch(supabaseProvider);
      final profiles = await fetchPublicProfiles(client, [userId]);
      return profileOrFallback(profiles, userId);
    });
