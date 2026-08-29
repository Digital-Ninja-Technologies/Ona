/// A minimal, publicly-visible slice of a user's profile (from the
/// `public_profiles` view) — just enough to show a name/avatar in
/// community posts, comments, conversations, and chat, plus the follow
/// counts shown on a user's profile.
class PublicProfile {
  const PublicProfile({
    required this.id,
    this.name,
    this.username,
    this.profileImage,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  final String id;
  final String? name;
  final String? username;
  final String? profileImage;
  final int followersCount;
  final int followingCount;

  String get displayName =>
      (name != null && name!.trim().isNotEmpty) ? name! : 'Traveler';

  /// The @handle shown wherever a user's identity appears in the community
  /// feed (posts, comments, quote embeds) — falls back to [displayName] for
  /// accounts that haven't set a username yet.
  String get handle =>
      (username != null && username!.trim().isNotEmpty)
          ? '@${username!}'
          : displayName;

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    return PublicProfile(
      id: json['id'] as String,
      name: json['name'] as String?,
      username: json['username'] as String?,
      profileImage: json['profile_image'] as String?,
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
    );
  }
}
