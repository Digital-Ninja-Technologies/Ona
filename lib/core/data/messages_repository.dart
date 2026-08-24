import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    final conversations = conversationRows.map((row) {
      final id = row['id'] as String;
      final user1 = row['user1_id'] as String;
      final user2 = row['user2_id'] as String;
      final otherUserId = user1 == me ? user2 : user1;
      final lastMessageRow = lastMessageByConversation[id];
      return Conversation(
        id: id,
        otherUser: profileOrFallback(profiles, otherUserId),
        lastMessage: lastMessageRow?['content'] as String?,
        lastMessageAt: lastMessageRow != null
            ? DateTime.parse(lastMessageRow['created_at'] as String)
            : DateTime.parse(row['created_at'] as String),
      );
    }).toList();

    conversations.sort((a, b) {
      final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return conversations;
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

    final created = await client
        .from('conversations')
        .insert({'user1_id': me, 'user2_id': otherUserId})
        .select('id')
        .single();
    return created['id'] as String;
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
