import 'public_profile.dart';

/// A conversation enriched with the other participant's public profile and
/// a preview of the most recent message — everything the conversations
/// list needs, assembled client-side by [MessagesRepository].
class Conversation {
  const Conversation({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.isUnread = false,
    this.isRequest = false,
  });

  final String id;
  final PublicProfile otherUser;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;

  /// True if the last message was from [otherUser] and hasn't been read yet.
  final bool isUnread;

  /// True if the signed-in user doesn't follow [otherUser] back — Twitter's
  /// "message request" bucket, regardless of who sent the last message.
  final bool isRequest;
}
