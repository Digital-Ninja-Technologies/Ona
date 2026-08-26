import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/agents_repository.dart';
import '../../core/data/messages_repository.dart';
import '../../core/data/reviews_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_view.dart';
import '../auth/auth_controller.dart';

class AgentDetailScreen extends ConsumerStatefulWidget {
  const AgentDetailScreen({super.key, required this.agentId});

  final String agentId;

  @override
  ConsumerState<AgentDetailScreen> createState() => _AgentDetailScreenState();
}

class _AgentDetailScreenState extends ConsumerState<AgentDetailScreen> {
  bool _startingChat = false;

  Future<void> _startChat(String? agentUserId) async {
    final me = ref.read(currentUserProvider);
    if (me == null) {
      context.push('/auth/signin');
      return;
    }
    if (agentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This agent has not linked a chat account yet.'),
        ),
      );
      return;
    }
    setState(() => _startingChat = true);
    try {
      final conversationId = await ref
          .read(messagesRepositoryProvider)
          .getOrCreateConversation(agentUserId);
      if (mounted) context.push('/chat/$conversationId');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not start chat.')));
      }
    } finally {
      if (mounted) setState(() => _startingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentAsync = ref.watch(agentDetailProvider(widget.agentId));

    return Scaffold(
      body: agentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: 'Could not load this agent.',
          onRetry: () => ref.invalidate(agentDetailProvider(widget.agentId)),
        ),
        data: (agent) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: AppColors.background,
              leading: Padding(
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  child: IconButton(
                    icon: const Icon(
                      LucideIcons.arrowLeft,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: agent.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: agent.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(color: AppColors.surface),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            agent.businessName,
                            style: AppTheme.fredoka(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (agent.isVerified)
                          const Icon(
                            LucideIcons.badgeCheck,
                            color: AppColors.verified,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.star,
                          size: 16,
                          color: AppColors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          agent.rating?.toStringAsFixed(1) ?? '—',
                          style: AppTheme.poppins(fontWeight: FontWeight.w600),
                        ),
                        if (agent.yearsExperience != null) ...[
                          const SizedBox(width: 12),
                          const Icon(
                            LucideIcons.award,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${agent.yearsExperience} years',
                            style: AppTheme.poppins(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (agent.languages.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.languages,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              agent.languages.join(', '),
                              style: AppTheme.poppins(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (agent.bio != null) ...[
                      const SizedBox(height: 20),
                      Text('About', style: AppTheme.fredoka(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        agent.bio!,
                        style: AppTheme.poppins(color: AppColors.textSecondary),
                      ),
                    ],
                    if (agent.specialties.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Specialties',
                        style: AppTheme.fredoka(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: agent.specialties
                            .map(
                              (specialty) => Chip(
                                label: Text(
                                  specialty,
                                  style: AppTheme.poppins(fontSize: 13),
                                ),
                                backgroundColor: AppColors.surface,
                                side: BorderSide.none,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => context.push(
                        '/reviews',
                        extra: {
                          'target': ReviewTarget.agent(widget.agentId),
                          'title': agent.businessName,
                        },
                      ),
                      child: const Text('Reviews'),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: agentAsync.maybeWhen(
        data: (agent) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _startingChat ? null : () => _startChat(agent.userId),
              icon: const Icon(LucideIcons.messageCircle),
              label: Text(_startingChat ? 'Starting chat...' : 'Message Agent'),
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}
