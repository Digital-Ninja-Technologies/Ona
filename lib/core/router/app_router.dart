import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/agents/agent_detail_screen.dart';
import '../../features/agents/agents_screen.dart';
import '../../features/ai_assistant/ai_assistant_screen.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/sign_up_screen.dart';
import '../../features/booking/booking_flow_screen.dart';
import '../../features/booking/booking_success_screen.dart';
import '../../features/community/community_screen.dart';
import '../../features/community/create_post_screen.dart';
import '../../features/community/post_comments_screen.dart';
import '../../features/destination/destination_detail_screen.dart';
import '../../features/essentials/currency_converter_screen.dart';
import '../../features/essentials/emergency_contacts_screen.dart';
import '../../features/essentials/essentials_screen.dart';
import '../../features/essentials/etiquette_screen.dart';
import '../../features/essentials/packing_checklist_screen.dart';
import '../../features/essentials/safety_tips_screen.dart';
import '../../features/experience/experience_detail_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/itineraries/itineraries_screen.dart';
import '../../features/itineraries/itinerary_create_screen.dart';
import '../../features/itineraries/itinerary_detail_screen.dart';
import '../../features/messages/chat_screen.dart';
import '../../features/messages/messages_screen.dart';
import '../../features/onboarding/interests_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/reviews/reviews_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/shell/tab_shell.dart';
import '../../features/wishlist/wishlist_screen.dart';
import '../data/reviews_repository.dart';

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
      GoRoute(
        path: '/destination/:id',
        builder: (context, state) =>
            DestinationDetailScreen(destinationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/experience/:id',
        builder: (context, state) =>
            ExperienceDetailScreen(experienceId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking-flow',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return BookingFlowScreen(
            experienceId: args['experienceId'] as String,
          );
        },
      ),
      GoRoute(
        path: '/booking-success/:bookingId',
        builder: (context, state) =>
            BookingSuccessScreen(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/reviews',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return ReviewsScreen(
            target: args['target'] as ReviewTarget,
            title: args['title'] as String,
          );
        },
      ),
      GoRoute(
        path: '/travel-agent/:id',
        builder: (context, state) =>
            AgentDetailScreen(agentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) =>
            ChatScreen(conversationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/community/create',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/community/:id/comments',
        builder: (context, state) =>
            PostCommentsScreen(postId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/itinerary-create',
        builder: (context, state) => const ItineraryCreateScreen(),
      ),
      GoRoute(
        path: '/itinerary/:id',
        builder: (context, state) =>
            ItineraryDetailScreen(itineraryId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/ai-assistant',
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: '/essentials',
        builder: (context, state) => const EssentialsScreen(),
      ),
      GoRoute(
        path: '/essentials/currency-converter',
        builder: (context, state) => const CurrencyConverterScreen(),
      ),
      GoRoute(
        path: '/essentials/safety-tips',
        builder: (context, state) => const SafetyTipsScreen(),
      ),
      GoRoute(
        path: '/essentials/emergency-contacts',
        builder: (context, state) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: '/essentials/etiquette',
        builder: (context, state) => const EtiquetteScreen(),
      ),
      GoRoute(
        path: '/essentials/packing-checklist',
        builder: (context, state) => const PackingChecklistScreen(),
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
