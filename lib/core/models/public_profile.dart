/// A minimal, publicly-visible slice of a user's profile (from the
/// `public_profiles` view) — just enough to show a name/avatar in
/// community posts, comments, conversations, and chat.
class PublicProfile {
  const PublicProfile({required this.id, this.name, this.profileImage});

  final String id;
  final String? name;
  final String? profileImage;

  String get displayName =>
      (name != null && name!.trim().isNotEmpty) ? name! : 'Traveler';

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    return PublicProfile(
      id: json['id'] as String,
      name: json['name'] as String?,
      profileImage: json['profile_image'] as String?,
    );
  }
}
