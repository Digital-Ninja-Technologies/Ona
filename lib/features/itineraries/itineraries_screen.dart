import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/coming_soon_screen.dart';

class ItinerariesScreen extends StatelessWidget {
  const ItinerariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Itineraries',
      icon: LucideIcons.map,
      message:
          'Create and manage AI-generated or manual trip itineraries here soon.',
    );
  }
}
