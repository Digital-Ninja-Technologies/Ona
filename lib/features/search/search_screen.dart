import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/destinations_repository.dart';
import '../../core/data/itineraries_repository.dart';
import '../../core/data/messages_repository.dart';
import '../../core/models/conversation.dart';
import '../../core/models/destination.dart';
import '../../core/models/itinerary.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/destination_card.dart';
import '../../core/widgets/error_view.dart';

/// Results from every searchable corner of the app for one query — the
/// destinations database, the signed-in user's own saved itineraries, and
/// their agent conversations (by agent name or anything said in the chat).
class UnifiedSearchResults {
  const UnifiedSearchResults({
    required this.destinations,
    required this.itineraries,
    required this.conversations,
  });

  final List<Destination> destinations;
  final List<Itinerary> itineraries;
  final List<Conversation> conversations;

  bool get isEmpty =>
      destinations.isEmpty && itineraries.isEmpty && conversations.isEmpty;
}

final searchQueryProvider = StateProvider<String>((ref) => '');

final unifiedSearchResultsProvider =
    FutureProvider.autoDispose<UnifiedSearchResults>((ref) async {
      final query = ref.watch(searchQueryProvider);
      if (query.trim().isEmpty) {
        return const UnifiedSearchResults(
          destinations: [],
          itineraries: [],
          conversations: [],
        );
      }

      final results = await Future.wait([
        ref
            .watch(destinationsRepositoryProvider)
            .fetchDestinations(search: query, limit: 20),
        ref.watch(itinerariesRepositoryProvider).searchItineraries(query),
        ref.watch(messagesRepositoryProvider).searchConversations(query),
      ]);

      return UnifiedSearchResults(
        destinations: results[0] as List<Destination>,
        itineraries: results[1] as List<Itinerary>,
        conversations: results[2] as List<Conversation>,
      );
    });

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(unifiedSearchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'Search destinations, itineraries, chats...',
            prefixIcon: Icon(LucideIcons.search, size: 18),
          ),
        ),
      ),
      body: SafeArea(
        child: query.trim().isEmpty
            ? const _EmptySearchState()
            : resultsAsync.when(
                data: (results) => results.isEmpty
                    ? Center(
                        child: Text(
                          'No results for "$query"',
                          style: AppTheme.poppins(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (results.destinations.isNotEmpty) ...[
                            _SectionHeader('Destinations'),
                            ...results.destinations.map(
                              (destination) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: DestinationCard(
                                  destination: destination,
                                  width: double.infinity,
                                  onTap: () => context.push(
                                    '/destination/${destination.id}',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (results.itineraries.isNotEmpty) ...[
                            _SectionHeader('Your Itineraries'),
                            ...results.itineraries.map(
                              (itinerary) => _ItineraryResultTile(
                                itinerary: itinerary,
                                onTap: () =>
                                    context.push('/itinerary/${itinerary.id}'),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (results.conversations.isNotEmpty) ...[
                            _SectionHeader('Agent Conversations'),
                            ...results.conversations.map(
                              (conversation) => _ConversationResultTile(
                                conversation: conversation,
                                onTap: () => context.push(
                                  '/chat/${conversation.id}',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorView(
                  message: 'Search failed. Try again.',
                  onRetry: () => ref.invalidate(unifiedSearchResultsProvider),
                ),
              ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: AppTheme.fredoka(fontSize: 16)),
    );
  }
}

class _ItineraryResultTile extends StatelessWidget {
  const _ItineraryResultTile({required this.itinerary, required this.onTap});

  final Itinerary itinerary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.map, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(itinerary.title, style: AppTheme.fredoka(fontSize: 15)),
                    if (itinerary.destinationName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        itinerary.destinationName!,
                        style: AppTheme.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationResultTile extends StatelessWidget {
  const _ConversationResultTile({
    required this.conversation,
    required this.onTap,
  });

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primary,
        child: Text(
          conversation.otherUser.displayName[0].toUpperCase(),
          style: AppTheme.fredoka(color: Colors.white, fontSize: 16),
        ),
      ),
      title: Text(
        conversation.otherUser.displayName,
        style: AppTheme.fredoka(fontSize: 15),
      ),
      subtitle: Text(
        conversation.lastMessage ?? 'Say hello!',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.poppins(color: AppColors.textSecondary),
      ),
      onTap: onTap,
    );
  }
}

/// Shown before the user has typed a location/query — an icon-badge
/// illustration (matching the onboarding slides' visual language) plus a
/// short explanation of everything this search covers, so an empty screen
/// doesn't read as broken while there's nothing to show yet.
class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.mapPin,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Where to?',
              style: AppTheme.fredoka(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Search destinations, your saved itineraries, or your agent '
              'conversations — all in one place.',
              textAlign: TextAlign.center,
              style: AppTheme.poppins(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
