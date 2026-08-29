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
    final response = await query.order('rating', ascending: false).limit(limit);
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

  /// The signed-in user's own agent listing, if they've registered as one.
  Future<TravelAgent?> fetchMyAgentProfile() async {
    final client = _ref.read(supabaseProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;
    final response = await client
        .from('travel_agents')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (response == null) return null;
    return TravelAgent.fromJson(response);
  }

  /// Emails a "Register as an Agent" submission to the Ona team via the
  /// `submit-agent-application` Edge Function, for review — it does not
  /// write to `travel_agents` directly, so nothing shows up on the public
  /// agent page until the application is approved.
  Future<void> submitAgentApplication({
    required String businessName,
    String? bio,
    List<String> specialties = const [],
    List<String> languages = const [],
    int? yearsExperience,
    String? imageUrl,
  }) async {
    final client = _ref.read(supabaseProvider);
    final user = client.auth.currentUser!;
    final response = await client.functions.invoke(
      'submit-agent-application',
      body: {
        'businessName': businessName,
        'bio': bio,
        'specialties': specialties,
        'languages': languages,
        'yearsExperience': yearsExperience,
        'imageUrl': imageUrl,
        'applicantEmail': user.email,
        'applicantId': user.id,
      },
    );
    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
  }
}

final agentsRepositoryProvider = Provider<AgentsRepository>((ref) {
  return AgentsRepository(ref);
});

final agentSearchQueryProvider = StateProvider<String>((ref) => '');
final agentMinRatingProvider = StateProvider<double?>((ref) => null);

final agentsListProvider = FutureProvider.autoDispose<List<TravelAgent>>((ref) {
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

final myAgentProfileProvider = FutureProvider.autoDispose<TravelAgent?>((
  ref,
) {
  ref.watch(currentUserProvider);
  return ref.watch(agentsRepositoryProvider).fetchMyAgentProfile();
});
