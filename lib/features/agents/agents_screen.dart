import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/coming_soon_screen.dart';

class AgentsScreen extends StatelessWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Travel Agents',
      icon: LucideIcons.userCheck,
      message: 'Browse and book verified local travel agents here soon.',
    );
  }
}
