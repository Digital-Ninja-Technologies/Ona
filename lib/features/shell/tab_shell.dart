import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _tabRoutes = [
  '/tabs/home',
  '/tabs/agents',
  '/tabs/itineraries',
  '/tabs/messages',
  '/tabs/community',
  '/tabs/profile',
];

const _tabItems = [
  BottomNavigationBarItem(icon: Icon(LucideIcons.compass), label: 'Explore'),
  BottomNavigationBarItem(icon: Icon(LucideIcons.userCheck), label: 'Agents'),
  BottomNavigationBarItem(icon: Icon(LucideIcons.map), label: 'Itineraries'),
  BottomNavigationBarItem(
    icon: Icon(LucideIcons.messageCircle),
    label: 'Messages',
  ),
  BottomNavigationBarItem(icon: Icon(LucideIcons.users), label: 'Community'),
  BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
];

/// Bottom-tab shell matching the original app's six visible tabs
/// (Search is reachable from Home but isn't a bottom-tab destination).
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
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: _tabItems,
        onTap: (index) => context.go(_tabRoutes[index]),
      ),
    );
  }
}
