import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/agents/agents_screen.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/sign_up_screen.dart';
import '../../features/community/community_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/itineraries/itineraries_screen.dart';
import '../../features/messages/messages_screen.dart';
import '../../features/onboarding/interests_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/shell/tab_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isSignedIn =
          authState.valueOrNull?.session != null ||
          ref.read(currentUserProvider) != null;
      final goingToAuthOrOnboarding =
          state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation.startsWith('/onboarding');

      if (state.matchedLocation == '/') {
        return isSignedIn ? '/tabs/home' : '/onboarding/welcome';
      }
      if (!isSignedIn && !goingToAuthOrOnboarding) {
        return '/onboarding/welcome';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SizedBox.shrink()),
      GoRoute(
        path: '/onboarding/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/interests',
        builder: (context, state) => const InterestsScreen(),
      ),
      GoRoute(
        path: '/auth/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/tabs/search',
        builder: (context, state) => const SearchScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return TabShell(location: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(
            path: '/tabs/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/tabs/agents',
            builder: (context, state) => const AgentsScreen(),
          ),
          GoRoute(
            path: '/tabs/itineraries',
            builder: (context, state) => const ItinerariesScreen(),
          ),
          GoRoute(
            path: '/tabs/messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/tabs/community',
            builder: (context, state) => const CommunityScreen(),
          ),
          GoRoute(
            path: '/tabs/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
