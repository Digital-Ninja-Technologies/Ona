import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';

const _tabRoutes = [
  '/tabs/home',
  '/tabs/agents',
  '/tabs/itineraries',
  '/tabs/messages',
  '/tabs/community',
  '/tabs/profile',
];

const _tabIcons = [
  LucideIcons.compass,
  LucideIcons.userCheck,
  LucideIcons.map,
  LucideIcons.messageCircle,
  LucideIcons.users,
  LucideIcons.user,
];

/// Bottom-tab shell matching the original app's six visible tabs
/// (Search is reachable from Home but isn't a bottom-tab destination).
///
/// Icon-only, no labels or selection pill — an Instagram-style tab bar.
class TabShell extends StatelessWidget {
  const TabShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  int get _currentIndex {
    final index = _tabRoutes.indexWhere((route) => location.startsWith(route));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;
    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                for (var i = 0; i < _tabIcons.length; i++)
                  Expanded(
                    child: _TabIconButton(
                      icon: _tabIcons[i],
                      selected: i == currentIndex,
                      onTap: () => context.go(_tabRoutes[i]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabIconButton extends StatelessWidget {
  const _TabIconButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      containedInkWell: true,
      highlightShape: BoxShape.circle,
      child: Center(
        child: Icon(
          icon,
          size: 26,
          color: selected ? AppColors.text : AppColors.textSecondary,
        ),
      ),
    );
  }
}
