import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/auth_controller.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/public_profile.dart';
import 'public_profiles_repository.dart';

class MessagesRepository {
  MessagesRepository(this._ref);

  final Ref _ref;

  String get _userId {
    final userId = _ref.read(supabaseProvider).auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot access messages without a signed-in user.');
    }
    return userId;
  }

  Future<List<Conversation>> fetchConversations() async {
    final client = _ref.read(supabaseProvider);
    final me = _userId;
    final rows = await client
        .from('conversations')
        .select()
        .or('user1_id.eq.$me,user2_id.eq.$me');

    final conversationRows = List<Map<String, dynamic>>.from(rows as List);
    if (conversationRows.isEmpty) return [];

    final otherUserIds = conversationRows.map((row) {
      final user1 = row['user1_id'] as String;
      final user2 = row['user2_id'] as String;
      return user1 == me ? user2 : user1;
    }).toSet();

    final profiles = await fetchPublicProfiles(client, otherUserIds);

    final conversationIds = conversationRows
        .map((row) => row['id'] as String)
        .toList();
    final messageRows = await client
        .from('messages')
        .select()
        .inFilter('conversation_id', conversationIds)
        .order('created_at', ascending: false);

    final lastMessageByConversation = <String, Map<String, dynamic>>{};
    for (final row in List<Map<String, dynamic>>.from(messageRows as List)) {
      final conversationId = row['conversation_id'] as String;
      lastMessageByConversation.putIfAbsent(conversationId, () => row);
    }

    // Conversations I've hidden ("deleted") from my own inbox — reappear
    // automatically once a newer message arrives, so hidden_at is compared
    // against the conversation's latest message time below rather than
    // just excluding the id outright.
    final hiddenRows = await client
        .from('conversation_hidden')
        .select('conversation_id, hidden_at')
        .eq('user_id', me)
        .inFilter('conversation_id', conversationIds);
    final hiddenAtByConversation = <String, DateTime>{
      for (final row in List<Map<String, dynamic>>.from(hiddenRows as List))
        row['conversation_id'] as String: DateTime.parse(
          row['hidden_at'] as String,
        ),
    };

    // Which of the other participants I follow back — determines whether
    // their conversation is a "request" (see Conversation.isRequest).
    final followingRows = await client
        .from('follows')
        .select('followed_id')
        .eq('follower_id', me)
        .inFilter('followed_id', otherUserIds.toList());
    final followedIds = List<Map<String, dynamic>>.from(followingRows as List)
        .map((row) => row['followed_id'] as String)
        .toSet();

    // A block in either direction removes the conversation from view
    // entirely, like Twitter.
    final blockedEitherWayRows = await client
        .from('blocks')
        .select('blocker_id, blocked_id')
        .or(
          'blocker_id.eq.$me,blocked_id.eq.$me',
        );
    final blockedUserIds = <String>{};
    for (final row in List<Map<String, dynamic>>.from(
      blockedEitherWayRows as List,
    )) {
      final blockerId = row['blocker_id'] as String;
      final blockedId = row['blocked_id'] as String;
      blockedUserIds.add(blockerId == me ? blockedId : blockerId);
    }

    final conversations = <Conversation>[];
    for (final row in conversationRows) {
      final id = row['id'] as String;
      final user1 = row['user1_id'] as String;
      final user2 = row['user2_id'] as String;
      final otherUserId = user1 == me ? user2 : user1;
      if (blockedUserIds.contains(otherUserId)) continue;

      final lastMessageRow = lastMessageByConversation[id];
      final lastMessageAt = lastMessageRow != null
          ? DateTime.parse(lastMessageRow['created_at'] as String)
          : DateTime.parse(row['created_at'] as String);

      final hiddenAt = hiddenAtByConversation[id];
      if (hiddenAt != null && !hiddenAt.isBefore(lastMessageAt)) {
        continue;
      }

      final lastMessageSenderId = lastMessageRow?['sender_id'] as String?;
      final myLastReadAt = user1 == me
          ? (row['user1_last_read_at'] as String?)
          : (row['user2_last_read_at'] as String?);
      final isUnread =
          lastMessageSenderId != null &&
          lastMessageSenderId != me &&
          (myLastReadAt == null ||
              lastMessageAt.isAfter(DateTime.parse(myLastReadAt)));

      conversations.add(
        Conversation(
          id: id,
          otherUser: profileOrFallback(profiles, otherUserId),
          lastMessage: lastMessageRow?['content'] as String?,
          lastMessageAt: lastMessageAt,
          lastMessageSenderId: lastMessageSenderId,
          isUnread: isUnread,
          isRequest: !followedIds.contains(otherUserId),
        ),
      );
    }

    conversations.sort((a, b) {
      final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return conversations;
  }

  /// Marks a conversation as read for the signed-in user via a
  /// security-definer RPC (rather than a generic UPDATE policy) so a client
  /// can only ever touch their own read-marker column.
  Future<void> markConversationRead(String conversationId) async {
    final client = _ref.read(supabaseProvider);
    await client.rpc(
      'mark_conversation_read',
      params: {'p_conversation_id': conversationId},
    );
  }

  /// Hides a conversation from the signed-in user's own inbox — one-sided,
  /// like Twitter's "Delete conversation": it reappears if the other person
  /// sends a new message.
  Future<void> deleteConversation(String conversationId) async {
    final client = _ref.read(supabaseProvider);
    await client.from('conversation_hidden').upsert({
      'conversation_id': conversationId,
      'user_id': _userId,
      'hidden_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Searches the signed-in user's conversations by the other person's name
  /// or by message content anywhere in the conversation's history (not just
  /// the last message) — used by the unified search screen. Empty for a
  /// blank [query] rather than returning everything.
  Future<List<Conversation>> searchConversations(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final conversations = await fetchConversations();
    final lowerQuery = q.toLowerCase();
    final nameMatches = conversations
        .where((c) => c.otherUser.displayName.toLowerCase().contains(lowerQuery))
        .toList();

    final remaining = conversations
        .where((c) => !nameMatches.any((match) => match.id == c.id))
        .toList();
    if (remaining.isEmpty) return nameMatches;

    final client = _ref.read(supabaseProvider);
    final remainingIds = remaining.map((c) => c.id).toList();
    final messageRows = await client
        .from('messages')
        .select('conversation_id')
        .inFilter('conversation_id', remainingIds)
        .ilike('content', '%$q%');
    final matchingIds = List<Map<String, dynamic>>.from(messageRows as List)
        .map((row) => row['conversation_id'] as String)
        .toSet();

    final contentMatches = remaining.where((c) => matchingIds.contains(c.id));
    return [...nameMatches, ...contentMatches];
  }

  Future<String> getOrCreateConversation(String otherUserId) async {
    final client = _ref.read(supabaseProvider);
    final me = _userId;

    final existing = await client
        .from('conversations')
        .select('id')
        .or(
          'and(user1_id.eq.$me,user2_id.eq.$otherUserId),'
          'and(user1_id.eq.$otherUserId,user2_id.eq.$me)',
        )
        .maybeSingle();
    if (existing != null) return existing['id'] as String;

    try {
      final created = await client
          .from('conversations')
          .insert({'user1_id': me, 'user2_id': otherUserId})
          .select('id')
          .single();
      return created['id'] as String;
    } on PostgrestException catch (e) {
      // Unique-violation: another request created the same pair between
      // our check above and this insert. Re-select rather than error.
      if (e.code == '23505') {
        final row = await client
            .from('conversations')
            .select('id')
            .or(
              'and(user1_id.eq.$me,user2_id.eq.$otherUserId),'
              'and(user1_id.eq.$otherUserId,user2_id.eq.$me)',
            )
            .single();
        return row['id'] as String;
      }
      rethrow;
    }
  }

  Future<PublicProfile> fetchOtherUser(String otherUserId) async {
    final client = _ref.read(supabaseProvider);
    final profiles = await fetchPublicProfiles(client, [otherUserId]);
    return profileOrFallback(profiles, otherUserId);
  }

  Future<PublicProfile> fetchConversationOtherUser(
    String conversationId,
  ) async {
    final client = _ref.read(supabaseProvider);
    final me = _userId;
    final conversation = await client
        .from('conversations')
        .select()
        .eq('id', conversationId)
        .single();
    final user1 = conversation['user1_id'] as String;
    final user2 = conversation['user2_id'] as String;
    return fetchOtherUser(user1 == me ? user2 : user1);
  }

  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    final client = _ref.read(supabaseProvider);
    final response = await client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');
    return (response as List)
        .map((row) => ChatMessage.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final client = _ref.read(supabaseProvider);
    await client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': _userId,
      'content': content,
    });
  }
}

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository(ref);
});

final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((
  ref,
) {
  return ref.watch(messagesRepositoryProvider).fetchConversations();
});

/// The Messages screen's Twitter-style dropdown filter.
enum MessageFilter { all, read, unread, requests }

final messageFilterProvider = StateProvider<MessageFilter>(
  (ref) => MessageFilter.all,
);

/// [conversationsProvider], filtered by [messageFilterProvider] — "All" and
/// "Read"/"Unread" only ever show conversations that aren't requests, since
/// on Twitter, requests are a separate bucket you haven't accepted into your
/// main inbox yet.
final filteredConversationsProvider = Provider.autoDispose<
  AsyncValue<List<Conversation>>
>((ref) {
  final filter = ref.watch(messageFilterProvider);
  final conversationsAsync = ref.watch(conversationsProvider);
  return conversationsAsync.whenData((conversations) {
    switch (filter) {
      case MessageFilter.all:
        return conversations.where((c) => !c.isRequest).toList();
      case MessageFilter.read:
        return conversations
            .where((c) => !c.isRequest && !c.isUnread)
            .toList();
      case MessageFilter.unread:
        return conversations
            .where((c) => !c.isRequest && c.isUnread)
            .toList();
      case MessageFilter.requests:
        return conversations.where((c) => c.isRequest).toList();
    }
  });
});

final chatMessagesProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, conversationId) {
      return ref
          .watch(messagesRepositoryProvider)
          .fetchMessages(conversationId);
    });

final chatOtherUserProvider = FutureProvider.autoDispose
    .family<PublicProfile, String>((ref, conversationId) {
      return ref
          .watch(messagesRepositoryProvider)
          .fetchConversationOtherUser(conversationId);
    });
