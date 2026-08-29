import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/agents/agent_detail_screen.dart';
import '../../features/agents/agents_screen.dart';
import '../../features/agents/register_agent_screen.dart';
import '../../features/ai_assistant/ai_assistant_screen.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/reset_password_screen.dart';
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
import '../../features/itineraries/itinerary_preview_screen.dart';
import '../../features/messages/chat_screen.dart';
import '../../features/messages/messages_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/interests_screen.dart';
import '../../features/onboarding/username_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/place/place_detail_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/profile/user_profile_screen.dart';
import '../../features/reviews/reviews_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/shell/tab_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/wishlist/wishlist_screen.dart';
import '../data/reviews_repository.dart';
import '../models/community_post.dart';
import '../models/itinerary.dart';
import '../models/place_suggestion.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final isSignedIn = ref.watch(isSignedInProvider);
  final isPasswordRecovery = ref.watch(isPasswordRecoveryProvider);
  final needsUsername = ref.watch(needsUsernameProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final goingToAuthOrOnboarding =
          state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation.startsWith('/onboarding');

      if (state.matchedLocation == '/splash') {
        return null;
      }
      if (isPasswordRecovery &&
          state.matchedLocation != '/auth/reset-password') {
        return '/auth/reset-password';
      }
      // Fires for every sign-in method (email, Google, Apple) and for
      // pre-existing accounts from before usernames existed — /interests is
      // exempt so a fresh email signup still runs interests -> username in
      // order, instead of this cutting the chain short.
      if (isSignedIn &&
          needsUsername &&
          state.matchedLocation != '/onboarding/username' &&
          state.matchedLocation != '/onboarding/interests') {
        return '/onboarding/username';
      }
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
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/interests',
        builder: (context, state) => const InterestsScreen(),
      ),
      GoRoute(
        path: '/onboarding/username',
        builder: (context, state) => const UsernameScreen(),
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
        path: '/auth/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
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
        redirect: (context, state) {
          final args = state.extra;
          if (args is! Map || args['experienceId'] is! String) {
            return '/tabs/home';
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra as Map;
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
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/user/:id',
        builder: (context, state) =>
            UserProfileScreen(userId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/place-detail',
        redirect: (context, state) {
          if (state.extra is! PlaceSuggestion) return '/tabs/home';
          return null;
        },
        builder: (context, state) =>
            PlaceDetailScreen(place: state.extra as PlaceSuggestion),
      ),
      GoRoute(
        path: '/reviews',
        redirect: (context, state) {
          final args = state.extra;
          if (args is! Map ||
              args['target'] is! ReviewTarget ||
              args['title'] is! String) {
            return '/tabs/home';
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra as Map;
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
        path: '/agent/register',
        builder: (context, state) => const RegisterAgentRoute(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) =>
            ChatScreen(conversationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/community/create',
        builder: (context, state) {
          final args = state.extra;
          return CreatePostScreen(
            quotedPost: args is CommunityPost ? args : null,
          );
        },
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
        path: '/itinerary-preview',
        redirect: (context, state) {
          final args = state.extra;
          if (args is! Map ||
              args['draft'] is! ItineraryDraft ||
              args['destinationName'] is! String ||
              args['durationDays'] is! int ||
              args['budget'] is! String) {
            return '/tabs/itineraries';
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra as Map;
          return ItineraryPreviewScreen(
            draft: args['draft'] as ItineraryDraft,
            destinationName: args['destinationName'] as String,
            durationDays: args['durationDays'] as int,
            budget: args['budget'] as String,
          );
        },
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
