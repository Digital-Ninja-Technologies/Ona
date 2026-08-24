import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class _EtiquetteCategory {
  const _EtiquetteCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.dos,
    required this.donts,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> dos;
  final List<String> donts;
}

const _categories = [
  _EtiquetteCategory(
    title: 'Greetings & Gestures',
    icon: LucideIcons.handshake,
    color: AppColors.primary,
    dos: [
      'Learn basic greetings in the local language',
      'Observe and mirror local greeting customs',
      "Smile - it's universal!",
      'Be aware of personal space preferences',
    ],
    donts: [
      "Don't assume handshakes are always appropriate",
      'Avoid overly enthusiastic gestures',
      "Don't point with fingers (use open hand)",
      'Be careful with thumbs up - offensive in some cultures',
    ],
  ),
  _EtiquetteCategory(
    title: 'Dining Customs',
    icon: LucideIcons.users,
    color: AppColors.orange,
    dos: [
      'Wait to be seated in restaurants',
      'Try a bit of everything offered',
      'Keep both hands visible at the table (not in lap)',
      'Finish your plate to show appreciation',
    ],
    donts: [
      "Don't start eating before others",
      'Avoid talking with your mouth full',
      "Don't leave chopsticks standing upright in rice",
      "Don't be afraid to ask about local customs",
    ],
  ),
  _EtiquetteCategory(
    title: 'Dress Code & Modesty',
    icon: LucideIcons.thumbsUp,
    color: AppColors.green,
    dos: [
      'Dress modestly when visiting religious sites',
      'Cover shoulders and knees in conservative areas',
      'Remove shoes when entering homes (in many cultures)',
      'Check dress codes for restaurants/venues',
    ],
    donts: [
      "Don't wear revealing clothing in conservative countries",
      'Avoid overly casual beach wear in cities',
      "Don't wear shoes inside homes without permission",
      'Avoid offensive slogans or imagery on clothing',
    ],
  ),
  _EtiquetteCategory(
    title: 'Social Interactions',
    icon: LucideIcons.thumbsDown,
    color: AppColors.primaryDark,
    dos: [
      'Be patient and polite always',
      'Ask before taking photos of people',
      'Learn about tipping customs',
      'Respect queuing culture',
    ],
    donts: [
      "Don't raise your voice or get angry publicly",
      'Avoid discussing sensitive topics (politics, religion)',
      "Don't make assumptions about customs",
      'Never disrespect local traditions or beliefs',
    ],
  ),
];

class EtiquetteScreen extends StatefulWidget {
  const EtiquetteScreen({super.key});

  @override
  State<EtiquetteScreen> createState() => _EtiquetteScreenState();
}

class _EtiquetteScreenState extends State<EtiquetteScreen> {
  String? _expanded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cultural Etiquette')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Respect local customs and avoid cultural faux pas',
              style: AppTheme.poppins(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            for (final category in _categories)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() {
                        _expanded = _expanded == category.title
                            ? null
                            : category.title;
                      }),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: category.color,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Icon(category.icon, color: Colors.white),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                category.title,
                                style: AppTheme.fredoka(fontSize: 15),
                              ),
                            ),
                            Icon(
                              _expanded == category.title
                                  ? LucideIcons.chevronUp
                                  : LucideIcons.chevronDown,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_expanded == category.title)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "✅ Do's",
                              style: AppTheme.fredoka(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            for (final item in category.dos) _Bullet(item),
                            const SizedBox(height: 12),
                            Text(
                              "❌ Don'ts",
                              style: AppTheme.fredoka(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            for (final item in category.donts) _Bullet(item),
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

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: AppTheme.poppins()),
          Expanded(child: Text(text, style: AppTheme.poppins(fontSize: 13))),
        ],
      ),
    );
  }
}
