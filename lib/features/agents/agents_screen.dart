import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/agents_repository.dart';
import '../../core/models/travel_agent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

const _ratingFilters = [null, 4.5, 4.0];

class AgentsScreen extends ConsumerWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentsListProvider);
    final minRating = ref.watch(agentMinRatingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Travel Agents')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search agents by name or specialty',
                      prefixIcon: Icon(LucideIcons.search),
                    ),
                    onChanged: (value) =>
                        ref.read(agentSearchQueryProvider.notifier).state =
                            value,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _ratingFilters.map((rating) {
                      final label = rating == null
                          ? 'All'
                          : '$rating+ ★';
                      final selected = minRating == rating;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (_) =>
                              ref.read(agentMinRatingProvider.notifier).state =
                                  rating,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(agentsListProvider),
                child: agentsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(
                      'Could not load travel agents.',
                      style: AppTheme.poppins(color: AppColors.error),
                    ),
                  ),
                  data: (agents) => agents.isEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No travel agents found.',
                                      style: AppTheme.poppins(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: agents.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) =>
                              _AgentCard(agent: agents[index]),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({required this.agent});

  final TravelAgent agent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/travel-agent/${agent.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child: agent.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: agent.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(color: AppColors.background),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          agent.businessName,
                          style: AppTheme.fredoka(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (agent.isVerified)
                        const Icon(
                          LucideIcons.badgeCheck,
                          size: 16,
                          color: AppColors.verified,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.star,
                        size: 14,
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        agent.rating?.toStringAsFixed(1) ?? '—',
                        style: AppTheme.poppins(fontSize: 12),
                      ),
                      if (agent.yearsExperience != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          '${agent.yearsExperience} yrs experience',
                          style: AppTheme.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (agent.bio != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      agent.bio!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (agent.specialties.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: agent.specialties
                          .take(3)
                          .map(
                            (specialty) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                specialty,
                                style: AppTheme.poppins(fontSize: 11),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
