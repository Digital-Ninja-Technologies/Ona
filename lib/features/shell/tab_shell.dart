import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/profile_repository.dart';
import '../../core/theme/app_colors.dart';

const _tabRoutes = [
  '/tabs/home',
  '/tabs/agents',
  '/tabs/itineraries',
  '/tabs/messages',
  '/tabs/community',
  '/tabs/profile',
];

/// Outline icon for each of the first five tabs — swapped for its filled
/// counterpart below when that tab is active. The sixth "tab" is the
/// user's own profile photo (see [_ProfileTabButton]), not an icon.
const _tabIconsOutlined = [
  Icons.explore_outlined,
  Icons.support_agent_outlined,
  Icons.map_outlined,
  Icons.chat_bubble_outline,
  Icons.groups_outlined,
];

const _tabIconsFilled = [
  Icons.explore,
  Icons.support_agent,
  Icons.map,
  Icons.chat_bubble,
  Icons.groups,
];

/// Bottom-tab shell matching the original app's six visible tabs
/// (Search is reachable from Home but isn't a bottom-tab destination).
///
/// Instagram-style: icon-only (no labels), outline icons switch to filled
/// when active, and the last tab is the signed-in user's own profile photo
/// rather than a generic icon.
class TabShell extends ConsumerWidget {
  const TabShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  int get _currentIndex {
    final index = _tabRoutes.indexWhere((route) => location.startsWith(route));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _currentIndex;
    final profileImage = ref.watch(myProfileProvider).valueOrNull?.profileImage;

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
                for (var i = 0; i < _tabIconsOutlined.length; i++)
                  Expanded(
                    child: _TabIconButton(
                      icon: i == currentIndex
                          ? _tabIconsFilled[i]
                          : _tabIconsOutlined[i],
                      selected: i == currentIndex,
                      onTap: () => context.go(_tabRoutes[i]),
                    ),
                  ),
                Expanded(
                  child: _ProfileTabButton(
                    imageUrl: profileImage,
                    selected: currentIndex == 5,
                    onTap: () => context.go(_tabRoutes[5]),
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
      containedInkWell: true,
      highlightShape: BoxShape.rectangle,
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

/// The Profile tab — the signed-in user's own photo instead of an icon,
/// with a dark ring when it's the active tab. Falls back to a generic
/// account icon (outline/filled, matching the other tabs) if there's no
/// photo yet.
class _ProfileTabButton extends StatelessWidget {
  const _ProfileTabButton({
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      containedInkWell: true,
      highlightShape: BoxShape.rectangle,
      child: Center(
        child: imageUrl == null
            ? Icon(
                selected ? Icons.account_circle : Icons.account_circle_outlined,
                size: 26,
                color: selected ? AppColors.text : AppColors.textSecondary,
              )
            : Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.text : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Icon(
                        selected
                            ? Icons.account_circle
                            : Icons.account_circle_outlined,
                        size: 22,
                        color: selected
                            ? AppColors.text
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
