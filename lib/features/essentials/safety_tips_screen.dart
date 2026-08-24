import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class _SafetyCategory {
  const _SafetyCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.tips,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> tips;
}

const _categories = [
  _SafetyCategory(
    title: 'General Safety',
    icon: LucideIcons.shield,
    color: AppColors.primary,
    tips: [
      'Keep copies of important documents in multiple places',
      'Share your itinerary with family or friends',
      'Register with your embassy when traveling abroad',
      'Keep emergency contacts saved in your phone',
      'Stay aware of your surroundings at all times',
      'Avoid displaying expensive jewelry or electronics',
    ],
  ),
  _SafetyCategory(
    title: 'Health & Medical',
    icon: LucideIcons.heart,
    color: AppColors.error,
    tips: [
      'Get travel insurance with medical coverage',
      'Pack a basic first-aid kit',
      'Research required vaccinations for your destination',
      'Bring enough prescription medications',
      'Drink bottled or purified water in developing countries',
      'Know the location of nearby hospitals and clinics',
    ],
  ),
  _SafetyCategory(
    title: 'Transportation',
    icon: LucideIcons.car,
    color: AppColors.green,
    tips: [
      'Use licensed taxis or ride-sharing apps',
      'Keep car doors locked and windows up',
      "Don't accept rides from strangers",
      'Sit in the back seat when using taxis',
      'Avoid traveling alone at night',
      'Research safe transportation options before arrival',
    ],
  ),
  _SafetyCategory(
    title: 'Accommodation',
    icon: Icons.home_outlined,
    color: AppColors.primaryDark,
    tips: [
      'Use hotel safes for valuables and documents',
      'Check door locks and windows upon arrival',
      'Know the emergency exits in your accommodation',
      "Don't share your room number with strangers",
      'Read reviews before booking accommodations',
      'Keep your room key secure at all times',
    ],
  ),
  _SafetyCategory(
    title: 'Money & Valuables',
    icon: LucideIcons.briefcase,
    color: AppColors.orange,
    tips: [
      'Use ATMs inside banks or shopping centers',
      'Notify your bank of travel plans',
      'Carry multiple payment methods',
      'Use a money belt or hidden pouch',
      "Don't carry all cash in one place",
      'Be cautious of card skimmers at ATMs',
    ],
  ),
  _SafetyCategory(
    title: 'Weather & Nature',
    icon: LucideIcons.sun,
    color: AppColors.yellow,
    tips: [
      'Check weather forecasts regularly',
      'Pack appropriate clothing for the climate',
      'Stay hydrated in hot weather',
      'Use sunscreen with high SPF',
      'Know what to do in case of natural disasters',
      'Respect local wildlife and keep distance',
    ],
  ),
];

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety Tips')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Stay safe while exploring the world',
              style: AppTheme.poppins(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            for (final category in _categories)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: category.color,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            category.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          category.title,
                          style: AppTheme.fredoka(fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final tip in category.tips)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('•  ', style: AppTheme.poppins()),
                            Expanded(
                              child: Text(
                                tip,
                                style: AppTheme.poppins(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
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
