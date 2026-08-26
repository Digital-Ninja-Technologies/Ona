import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/ai_assistant_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class _Message {
  const _Message({required this.role, required this.content});

  final String role; // 'user' | 'assistant'
  final String content;
}

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  // Only sent as a fallback payload if Gemini's quota is hit and the
  // function falls back to Groq, which needs full context resent each turn.
  static const _maxFallbackHistoryMessages = 20;

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [
    const _Message(
      role: 'assistant',
      content:
          "Hi! I'm your Ọ̀nà travel assistant. I can help you discover "
          "destinations, plan itineraries, find restaurants and hotels, "
          "and answer travel questions. Where would you like to explore?",
    ),
  ];
  bool _sending = false;
  String? _lastInteractionId;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(_Message(role: 'user', content: text));
      _sending = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final history = _messages.length > _maxFallbackHistoryMessages
          ? _messages.sublist(_messages.length - _maxFallbackHistoryMessages)
          : _messages;
      final reply = await ref
          .read(aiAssistantRepositoryProvider)
          .sendMessage(
            text,
            previousInteractionId: _lastInteractionId,
            history: history
                .map((m) => {'role': m.role, 'content': m.content})
                .toList(),
          );
      setState(() {
        _messages.add(_Message(role: 'assistant', content: reply.text));
        _lastInteractionId = reply.interactionId ?? _lastInteractionId;
      });
    } catch (_) {
      setState(
        () => _messages.add(
          const _Message(
            role: 'assistant',
            content:
                "I'm having trouble connecting right now. Please try again "
                "in a moment.",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.sparkles,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text('Ọ̀nà AI', style: AppTheme.fredoka(fontSize: 18)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _messages.length) {
                    return const _TypingBubble();
                  }
                  return _ChatBubble(message: _messages[index]);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Ask about destinations, plans, tips...',
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(LucideIcons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _Message message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final color = isUser ? Colors.white : AppColors.text;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _MarkdownLite(text: message.content, color: color),
      ),
    );
  }
}

/// Renders the small markdown subset the AI assistant actually produces —
/// `### headers`, `**bold**`, and `* ` / `- ` bullets — as styled text
/// instead of showing the raw syntax. Not a general markdown renderer; the
/// app has no other markdown surface to justify pulling in a package for it.
class _MarkdownLite extends StatelessWidget {
  const _MarkdownLite({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      final headerMatch = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(trimmed);
      if (headerMatch != null) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 4, bottom: 4),
            child: Text(
              headerMatch.group(2)!,
              style: AppTheme.fredoka(fontSize: 15, color: color),
            ),
          ),
        );
        continue;
      }

      final bulletMatch = RegExp(r'^[*-]\s+(.*)$').firstMatch(trimmed);
      if (bulletMatch != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: AppTheme.poppins(color: color)),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: _parseInlineBold(
                        bulletMatch.group(1)!,
                        AppTheme.poppins(color: color),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      widgets.add(
        Text.rich(
          TextSpan(children: _parseInlineBold(line, AppTheme.poppins(color: color))),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  /// Splits `**bold**` runs out of [text] into bold/regular [TextSpan]s.
  List<InlineSpan> _parseInlineBold(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var cursor = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start), style: baseStyle));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(fontWeight: FontWeight.w700),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }
    return spans;
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          height: 14,
          width: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
