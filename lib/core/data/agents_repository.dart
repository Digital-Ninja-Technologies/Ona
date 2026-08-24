import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../models/travel_agent.dart';

class AgentsRepository {
  AgentsRepository(this._ref);

  final Ref _ref;

  Future<List<TravelAgent>> fetchAgents({
    String? search,
    double? minRating,
    int limit = 50,
  }) async {
    final client = _ref.read(supabaseProvider);
    var query = client.from('travel_agents').select();
    if (search != null && search.trim().isNotEmpty) {
      query = query.or('business_name.ilike.%$search%,bio.ilike.%$search%');
    }
    if (minRating != null) {
      query = query.gte('rating', minRating);
    }
    final response = await query
        .order('rating', ascending: false)
        .limit(limit);
    return (response as List)
        .map((row) => TravelAgent.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<TravelAgent> fetchAgent(String id) async {
    final client = _ref.read(supabaseProvider);
    final response = await client
        .from('travel_agents')
        .select()
        .eq('id', id)
        .single();
    return TravelAgent.fromJson(response);
  }
}

final agentsRepositoryProvider = Provider<AgentsRepository>((ref) {
  return AgentsRepository(ref);
});

final agentSearchQueryProvider = StateProvider<String>((ref) => '');
final agentMinRatingProvider = StateProvider<double?>((ref) => null);

final agentsListProvider = FutureProvider.autoDispose<List<TravelAgent>>((
  ref,
) {
  final search = ref.watch(agentSearchQueryProvider);
  final minRating = ref.watch(agentMinRatingProvider);
  return ref
      .watch(agentsRepositoryProvider)
      .fetchAgents(search: search, minRating: minRating);
});

final agentDetailProvider = FutureProvider.family<TravelAgent, String>((
  ref,
  id,
) {
  return ref.watch(agentsRepositoryProvider).fetchAgent(id);
});
