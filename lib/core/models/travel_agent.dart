class TravelAgent {
  const TravelAgent({
    required this.id,
    this.userId,
    required this.businessName,
    this.bio,
    this.specialties = const [],
    this.languages = const [],
    this.yearsExperience,
    this.rating,
    this.isVerified = false,
    this.imageUrl,
  });

  final String id;
  final String? userId;
  final String businessName;
  final String? bio;
  final List<String> specialties;
  final List<String> languages;
  final int? yearsExperience;
  final double? rating;
  final bool isVerified;
  final String? imageUrl;

  /// Whether this agent has a linked auth account to chat with.
  bool get canChat => userId != null;

  factory TravelAgent.fromJson(Map<String, dynamic> json) {
    return TravelAgent(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      businessName: json['business_name'] as String,
      bio: json['bio'] as String?,
      specialties: List<String>.from(json['specialties'] as List? ?? const []),
      languages: List<String>.from(json['languages'] as List? ?? const []),
      yearsExperience: (json['years_experience'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toDouble(),
      isVerified: json['is_verified'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
    );
  }
}
