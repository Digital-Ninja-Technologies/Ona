import 'public_profile.dart';

enum NotificationType { follow, like, comment, repost, quote }

NotificationType _typeFromString(String value) {
  return NotificationType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => NotificationType.like,
  );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.actor,
    required this.type,
    this.postId,
    this.commentId,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final PublicProfile actor;
  final NotificationType type;
  final String? postId;
  final String? commentId;
  final bool read;
  final DateTime createdAt;

  /// The notification's message body, e.g. "Traveler liked your post".
  String get message {
    final name = actor.displayName;
    return switch (type) {
      NotificationType.follow => '$name followed you',
      NotificationType.like => '$name liked your post',
      NotificationType.comment => '$name commented on your post',
      NotificationType.repost => '$name reposted your post',
      NotificationType.quote => '$name quoted your post',
    };
  }

  factory AppNotification.fromJson(
    Map<String, dynamic> json, {
    required PublicProfile actor,
  }) {
    return AppNotification(
      id: json['id'] as String,
      actor: actor,
      type: _typeFromString(json['type'] as String),
      postId: json['post_id'] as String?,
      commentId: json['comment_id'] as String?,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
