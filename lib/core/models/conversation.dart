import 'public_profile.dart';

/// A conversation enriched with the other participant's public profile and
/// a preview of the most recent message — everything the conversations
/// list needs, assembled client-side by [ConversationsRepository].
class Conversation {
  const Conversation({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.lastMessageAt,
  });

  final String id;
  final PublicProfile otherUser;
  final String? lastMessage;
  final DateTime? lastMessageAt;
}
