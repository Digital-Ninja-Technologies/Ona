import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class _EssentialTool {
  const _EssentialTool({
    required this.icon,
    required this.title,
    required this.description,
    this.route,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? route;
}

const _tools = [
  _EssentialTool(
    icon: LucideIcons.circleDollarSign,
    title: 'Currency Converter',
    description: 'Convert between currencies with live rates',
    route: '/essentials/currency-converter',
  ),
  _EssentialTool(
    icon: LucideIcons.shield,
    title: 'Safety Tips',
    description: 'Travel safety advice by category',
    route: '/essentials/safety-tips',
  ),
  _EssentialTool(
    icon: LucideIcons.phone,
    title: 'Emergency Contacts',
    description: 'Police, ambulance, fire, and embassy numbers',
    route: '/essentials/emergency-contacts',
  ),
  _EssentialTool(
    icon: LucideIcons.handshake,
    title: 'Cultural Etiquette',
    description: "Do's and don'ts for respectful travel",
    route: '/essentials/etiquette',
  ),
  _EssentialTool(
    icon: LucideIcons.listChecks,
    title: 'Packing Checklist',
    description: 'Check off items as you pack',
    route: '/essentials/packing-checklist',
  ),
  _EssentialTool(
    icon: LucideIcons.fileText,
    title: 'Visa Requirements',
    description: 'Check visa needs for your destination',
  ),
  _EssentialTool(
    icon: LucideIcons.wifi,
    title: 'Local SIM Cards',
    description: 'Staying connected on the road',
  ),
  _EssentialTool(
    icon: LucideIcons.utensilsCrossed,
    title: 'Local Food Guide',
    description: 'Must-try dishes and dining tips',
  ),
];

class EssentialsScreen extends StatelessWidget {
  const EssentialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Travel Essentials')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Everything you need to know before and during your trip',
              style: AppTheme.poppins(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            for (final tool in _tools)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (tool.route != null) {
                      context.push(tool.route!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(tool.icon, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tool.title,
                                style: AppTheme.fredoka(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tool.description,
                                style: AppTheme.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
