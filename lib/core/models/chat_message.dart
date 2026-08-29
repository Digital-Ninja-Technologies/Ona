class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.createdAt,
    this.content,
    this.imageUrl,
    this.replyToId,
    this.editedAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final DateTime createdAt;

  /// Null for an image-only message.
  final String? content;

  /// Non-null when this message carries a shared photo.
  final String? imageUrl;

  /// The message this one is replying to, if any — resolved client-side
  /// against the conversation's already-loaded message list rather than
  /// fetched separately.
  final String? replyToId;

  /// Non-null once the sender has edited this message.
  final DateTime? editedAt;

  bool get isEdited => editedAt != null;

  /// Short text for previews (conversation list, reply quotes) — the
  /// message's own content, or a "📷 Photo" placeholder for an image-only
  /// message.
  String get previewText => content ?? (imageUrl != null ? '📷 Photo' : '');

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      replyToId: json['reply_to_id'] as String?,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
    );
  }
}
