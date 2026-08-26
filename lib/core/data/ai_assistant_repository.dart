import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';

class AiAssistantReply {
  const AiAssistantReply({required this.text, required this.interactionId});

  final String text;
  final String? interactionId;
}

class AiAssistantRepository {
  AiAssistantRepository(this._ref);

  final Ref _ref;

  /// Sends one chat turn to the `ai-assistant` Supabase Edge Function, which
  /// proxies to the Gemini API using a server-side secret. Gemini tracks
  /// conversation state server-side, so only the new [message] and the
  /// [previousInteractionId] from the prior turn (null on the first turn)
  /// need to be sent — not the full history. Throws if the function hasn't
  /// been deployed / configured with GEMINI_API_KEY.
  Future<AiAssistantReply> sendMessage(
    String message, {
    String? previousInteractionId,
  }) async {
    final client = _ref.read(supabaseProvider);
    final response = await client.functions.invoke(
      'ai-assistant',
      body: {
        'message': message,
        'previousInteractionId': previousInteractionId,
      },
    );
    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    if (data is! Map || data['reply'] is! String) {
      throw Exception('Unexpected response from ai-assistant.');
    }
    return AiAssistantReply(
      text: data['reply'] as String,
      interactionId: data['interactionId'] as String?,
    );
  }
}

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) {
  return AiAssistantRepository(ref);
});
