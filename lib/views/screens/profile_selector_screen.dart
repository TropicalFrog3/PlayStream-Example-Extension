import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/profile_controller.dart';
import '../../models/user/user_profile.dart';
import '../widgets/profile_avatar.dart';
import 'profile_edit_screen.dart';

class ProfileSelectorScreen extends ConsumerWidget {
  const ProfileSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: profilesAsync.when(
          data: (profiles) => _buildContent(context, ref, profiles),
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFE50914)),
          ),
          error: (error, _) => Center(
            child: Text(
              'Error loading profiles',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<UserProfile> profiles,
  ) {
    return Column(
      children: [
        // Header with logo and manage button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PLAYSTREAM',
                style: TextStyle(
                  color: Color(0xFFE50914),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              if (profiles.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileManageScreen(profiles: profiles),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.edit, color: Colors.white, size: 20),
                      SizedBox(width: 4),
                      Text(
                        'Manage',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Main content
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Who's Watching?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Profile grid
                  _buildProfileGrid(context, ref, profiles),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileGrid(
    BuildContext context,
    WidgetRef ref,
    List<UserProfile> profiles,
  ) {
    final canAddMore = profiles.length < 5;
    
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 24,
      children: [
        ...profiles.map((profile) => _buildProfileCard(
          context,
          ref,
          profile,
        )),
        if (canAddMore) _buildAddProfileCard(context, ref),
      ],
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    return InkWell(
      onTap: () async {
        await ref.read(profileControllerProvider.notifier).selectProfile(profile.id);
        if (context.mounted) {
          context.go('/home');
        }
      },
      child: SizedBox(
        width: 140,
        child: Column(
          children: [
            ProfileAvatar(
              profile: profile,
              size: 140,
            ),
            const SizedBox(height: 12),
            Text(
              profile.name,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProfileCard(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileEditScreen(),
          ),
        );
      },
      child: SizedBox(
        width: 140,
        child: Column(
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.white30, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white70,
                size: 60,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add Profile',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
