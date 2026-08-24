import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../models/itinerary.dart';

class ItinerariesRepository {
  ItinerariesRepository(this._ref);

  final Ref _ref;

  String get _userId {
    final userId = _ref.read(supabaseProvider).auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot access itineraries without a signed-in user.');
    }
    return userId;
  }

  Future<List<Itinerary>> fetchItineraries() async {
    final client = _ref.read(supabaseProvider);
    final response = await client
        .from('itineraries')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((row) => Itinerary.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<String> createItinerary({
    required String title,
    String? description,
    String? destinationId,
    String? destinationName,
    required int durationDays,
    String? budget,
    bool isAiGenerated = false,
    List<ItineraryDay> days = const [],
  }) async {
    final client = _ref.read(supabaseProvider);
    final response = await client
        .from('itineraries')
        .insert({
          'user_id': _userId,
          'title': title,
          'description': description,
          'destination_id': destinationId,
          'destination_name': destinationName,
          'duration_days': durationDays,
          'budget': budget,
          'is_ai_generated': isAiGenerated,
          'days': days.map((day) => day.toJson()).toList(),
        })
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<void> deleteItinerary(String id) async {
    final client = _ref.read(supabaseProvider);
    await client.from('itineraries').delete().eq('id', id);
  }

  /// Calls the `generate-itinerary` Supabase Edge Function, which proxies to
  /// the Anthropic API using a server-side secret. Throws if the function
  /// hasn't been deployed / configured with ANTHROPIC_API_KEY.
  Future<ItineraryDraft> generateItinerary({
    required String destination,
    required int days,
    required String budget,
  }) async {
    final client = _ref.read(supabaseProvider);
    final response = await client.functions.invoke(
      'generate-itinerary',
      body: {'destination': destination, 'days': days, 'budget': budget},
    );
    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected response from generate-itinerary.');
    }
    return ItineraryDraft.fromJson(data);
  }
}

final itinerariesRepositoryProvider = Provider<ItinerariesRepository>((ref) {
  return ItinerariesRepository(ref);
});

final itinerariesProvider = FutureProvider.autoDispose<List<Itinerary>>((ref) {
  return ref.watch(itinerariesRepositoryProvider).fetchItineraries();
});
