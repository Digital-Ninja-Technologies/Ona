import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../models/review.dart';
import 'public_profiles_repository.dart';

/// Identifies exactly one of a destination, experience, or agent that a
/// review targets — used both to fetch and to submit reviews.
class ReviewTarget {
  const ReviewTarget.destination(String id)
    : destinationId = id,
      experienceId = null,
      agentId = null;

  const ReviewTarget.experience(String id)
    : destinationId = null,
      experienceId = id,
      agentId = null;

  const ReviewTarget.agent(String id)
    : destinationId = null,
      experienceId = null,
      agentId = id;

  final String? destinationId;
  final String? experienceId;
  final String? agentId;

  @override
  bool operator ==(Object other) =>
      other is ReviewTarget &&
      other.destinationId == destinationId &&
      other.experienceId == experienceId &&
      other.agentId == agentId;

  @override
  int get hashCode => Object.hash(destinationId, experienceId, agentId);
}

class ReviewsRepository {
  ReviewsRepository(this._ref);

  final Ref _ref;

  Future<List<Review>> fetchReviews(ReviewTarget target) async {
    final client = _ref.read(supabaseProvider);
    var query = client.from('reviews').select();
    if (target.destinationId != null) {
      query = query.eq('destination_id', target.destinationId!);
    } else if (target.experienceId != null) {
      query = query.eq('experience_id', target.experienceId!);
    } else if (target.agentId != null) {
      query = query.eq('agent_id', target.agentId!);
    }
    final rows = await query.order('created_at', ascending: false);
    final reviewRows = List<Map<String, dynamic>>.from(rows as List);
    if (reviewRows.isEmpty) return [];
    final authorIds = reviewRows.map((row) => row['user_id'] as String);
    final profiles = await fetchPublicProfiles(client, authorIds);
    return reviewRows
        .map(
          (row) => Review.fromJson(
            row,
            author: profileOrFallback(profiles, row['user_id'] as String),
          ),
        )
        .toList();
  }

  Future<void> addReview({
    required ReviewTarget target,
    required int rating,
    required String comment,
    List<String> images = const [],
  }) async {
    final client = _ref.read(supabaseProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot submit a review without a signed-in user.');
    }
    await client.from('reviews').insert({
      'user_id': userId,
      'destination_id': target.destinationId,
      'experience_id': target.experienceId,
      'agent_id': target.agentId,
      'rating': rating,
      'comment': comment,
      'images': images,
    });
  }
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(ref);
});

final reviewsProvider = FutureProvider.autoDispose
    .family<List<Review>, ReviewTarget>((ref, target) {
      return ref.watch(reviewsRepositoryProvider).fetchReviews(target);
    });
