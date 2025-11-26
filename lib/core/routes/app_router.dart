import 'package:go_router/go_router.dart';
import 'package:playstream/views/screens/login_screen.dart';
import '../../views/screens/home_screen.dart';
import '../../views/screens/movie_details_screen.dart';
import '../../views/screens/show_details_screen.dart';
import '../../views/screens/list_details_screen.dart';
import '../../views/screens/player_screen.dart';
import '../../views/screens/profile_screen.dart';
import '../../views/screens/search_screen.dart';
import '../../views/screens/watchlist_screen.dart';
import '../../views/screens/admin_screen.dart';
import '../../views/screens/lists_screen.dart';
import '../../views/screens/extension_screen.dart';
import '../../views/screens/onboarding/onboarding_flow.dart';
import '../../views/screens/profile_selector_screen.dart';
import '../../services/onboarding_service.dart';
import '../../models/trakt/trakt_list.dart';

class AppRouter {
  static final _onboardingService = OnboardingService();

  static final router = GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) async {
      final completed = await _onboardingService.isOnboardingCompleted();
      final isOnboarding = state.matchedLocation == '/onboarding';
      
      if (!completed && !isOnboarding) {
        return '/onboarding';
      }
      
      // After onboarding, redirect to profile selector
      if (completed && state.matchedLocation == '/onboarding') {
        return '/profiles';
      }
      
      return null;
    },
    errorBuilder: (context, state) {
      // For errors, redirect to profiles
      return const ProfileSelectorScreen();
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingFlow(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profiles',
        builder: (context, state) => const ProfileSelectorScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/movie/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return MovieDetailsScreen(slug: slug);
        },
      ),
      GoRoute(
        path: '/show/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return ShowDetailsScreen(slug: slug);
        },
      ),
      GoRoute(
        path: '/list',
        builder: (context, state) {
          final list = state.extra as TraktList;
          return ListDetailsScreen(list: list);
        },
      ),
      GoRoute(
        path: '/player',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PlayerScreen(
            title: extra['title'] as String,
            videoUrl: extra['videoUrl'] as String,
          );
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/watchlist',
        builder: (context, state) => const WatchlistScreen(),
      ),
      GoRoute(
        path: '/lists',
        builder: (context, state) => const ListsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/extensions',
        builder: (context, state) => const ExtensionScreen(),
      ),
    ],
  );
}
