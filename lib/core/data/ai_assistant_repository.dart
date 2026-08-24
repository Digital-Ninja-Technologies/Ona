import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';

class AiAssistantRepository {
  AiAssistantRepository(this._ref);

  final Ref _ref;

  /// [history] is the full conversation so far, oldest first, as
  /// `{'role': 'user' | 'assistant', 'content': '...'}` maps. Calls the
  /// `ai-assistant` Supabase Edge Function, which proxies to the Anthropic
  /// API using a server-side secret. Throws if the function hasn't been
  /// deployed / configured with ANTHROPIC_API_KEY.
  Future<String> sendMessage(List<Map<String, String>> history) async {
    final client = _ref.read(supabaseProvider);
    final response = await client.functions.invoke(
      'ai-assistant',
      body: {'messages': history},
    );
    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    if (data is! Map || data['reply'] is! String) {
      throw Exception('Unexpected response from ai-assistant.');
    }
    return data['reply'] as String;
  }
}

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) {
  return AiAssistantRepository(ref);
});
