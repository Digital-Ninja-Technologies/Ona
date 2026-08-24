import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../models/destination.dart';

class BookingsRepository {
  BookingsRepository(this._ref);

  final Ref _ref;

  String get _userId {
    final userId = _ref.read(supabaseProvider).auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot access bookings without a signed-in user.');
    }
    return userId;
  }

  Future<String> createBooking({
    required String experienceId,
    required DateTime bookingDate,
    required int numParticipants,
    required double totalPrice,
    required double commissionAmount,
    String paymentStatus = 'pending',
  }) async {
    final client = _ref.read(supabaseProvider);
    final response = await client
        .from('bookings')
        .insert({
          'user_id': _userId,
          'experience_id': experienceId,
          'booking_date': bookingDate.toIso8601String().split('T').first,
          'num_participants': numParticipants,
          'total_price': totalPrice,
          'commission_amount': commissionAmount,
          'payment_status': paymentStatus,
        })
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<bool> isSaved(String destinationId) async {
    final client = _ref.read(supabaseProvider);
    final response = await client
        .from('saved_destinations')
        .select('destination_id')
        .eq('user_id', _userId)
        .eq('destination_id', destinationId)
        .maybeSingle();
    return response != null;
  }

  Future<bool> toggleSaved(String destinationId) async {
    final client = _ref.read(supabaseProvider);
    final alreadySaved = await isSaved(destinationId);
    if (alreadySaved) {
      await client
          .from('saved_destinations')
          .delete()
          .eq('user_id', _userId)
          .eq('destination_id', destinationId);
      return false;
    } else {
      await client.from('saved_destinations').insert({
        'user_id': _userId,
        'destination_id': destinationId,
      });
      return true;
    }
  }

  Future<List<Destination>> fetchSavedDestinations() async {
    final client = _ref.read(supabaseProvider);
    final response = await client
        .from('saved_destinations')
        .select('destinations(*)')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map(
          (row) =>
              Destination.fromJson(row['destinations'] as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> removeSavedDestination(String destinationId) async {
    final client = _ref.read(supabaseProvider);
    await client
        .from('saved_destinations')
        .delete()
        .eq('user_id', _userId)
        .eq('destination_id', destinationId);
  }
}

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  return BookingsRepository(ref);
});

final isDestinationSavedProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, destinationId) {
      return ref.watch(bookingsRepositoryProvider).isSaved(destinationId);
    });

final savedDestinationsProvider = FutureProvider.autoDispose<List<Destination>>(
  (ref) {
    return ref.watch(bookingsRepositoryProvider).fetchSavedDestinations();
  },
);

/// Destination ids with a wishlist toggle currently in flight — mirrors
/// [likeTogglingProvider] to stop a fast double-tap from racing two writes
/// for the same destination and hitting the saved_destinations primary key.
final saveTogglingProvider = StateProvider<Set<String>>((ref) => {});
