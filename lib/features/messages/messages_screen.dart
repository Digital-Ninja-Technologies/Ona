import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/coming_soon_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Messages',
      icon: LucideIcons.messageCircle,
      message: 'Chat with travel agents and other travelers here soon.',
    );
  }
}
