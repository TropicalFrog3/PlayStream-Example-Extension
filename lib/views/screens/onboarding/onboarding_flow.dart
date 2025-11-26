import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'welcome_screen.dart';
import 'content_selection_screen.dart';
import 'episode_tracking_screen.dart';
import 'tmdb_info_screen.dart';
import 'personal_lists_screen.dart';
import 'notifications_screen.dart';

final onboardingPageProvider = StateProvider<int>((ref) => 0);
final selectedContentProvider = StateProvider<Set<String>>((ref) => {});

class OnboardingFlow extends ConsumerWidget {
  const OnboardingFlow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(onboardingPageProvider);

    final screens = [
      const WelcomeScreen(),
      const ContentSelectionScreen(),
      const EpisodeTrackingScreen(),
      const TmdbInfoScreen(),
      const PersonalListsScreen(),
      const NotificationsScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: screens[currentPage],
      ),
    );
  }
}
