import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/coming_soon_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Community',
      icon: LucideIcons.users,
      message:
          'Read and share stories, tips, and questions from other travelers here soon.',
    );
  }
}
