import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../models/user/user_profile.dart';
import '../../models/user/app_user.dart';
import '../../services/auth/auth0_service.dart';

class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    print('AuthCallbackScreen: Handling callback...');
    
    // Wait for Auth0 SDK to process the callback
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    print('AuthCallbackScreen: Attempting to retrieve credentials...');
    // Try to get credentials from Auth0 credentials manager
    try {
      final auth0Service = Auth0Service();
      final credentials = await auth0Service.getCredentials();
      
      if (credentials != null) {
        print('AuthCallbackScreen: Got credentials from Auth0');
        // Manually create user from credentials
        final userProfile = credentials.user;
        final roles = userProfile.customClaims?['roles'] as List?;
        final isAdmin = roles?.contains('admin') ?? false;
        
        final user = AppUser(
          id: userProfile.sub,
          email: userProfile.email ?? '',
          name: userProfile.name,
          picture: userProfile.pictureUrl?.toString(),
          role: isAdmin ? UserRole.admin : UserRole.normal,
        );
        
        print('AuthCallbackScreen: Saving user to Hive: ${user.email}');
        // Save to Hive
        final box = await Hive.openBox<AppUser>('user');
        await box.put('current_user', user);
        
        // Invalidate auth provider to reload
        ref.invalidate(authControllerProvider);
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print('AuthCallbackScreen: Error getting credentials: $e');
    }
    
    if (!mounted) return;
    
    // Check if user is authenticated
    final authState = ref.read(authControllerProvider);
    print('AuthCallbackScreen: Auth state value: ${authState.value?.email}');
    
    if (authState.value != null) {
      print('AuthCallbackScreen: User authenticated successfully');
      // Successfully authenticated
      // Check if there's a pending profile to create
      final prefs = await SharedPreferences.getInstance();
      final pendingName = prefs.getString('pending_profile_name');
      print('AuthCallbackScreen: Pending profile name: $pendingName');
      
      if (pendingName != null) {
        // Create the pending profile
        final profile = UserProfile(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: pendingName,
          avatarColor: prefs.getString('pending_profile_color') ?? '#E50914',
          avatarIcon: prefs.getString('pending_profile_icon'),
          createdAt: DateTime.now(),
          lastUsed: DateTime.now(),
        );
        
        print('AuthCallbackScreen: Creating profile: ${profile.name}');
        
        // Clear pending data
        await prefs.remove('pending_profile_name');
        await prefs.remove('pending_profile_color');
        await prefs.remove('pending_profile_icon');
        
        // Create and select the profile
        await ref.read(profileControllerProvider.notifier).createProfile(profile);
        await ref.read(profileControllerProvider.notifier).selectProfile(profile.id);
        ref.invalidate(profilesProvider);
        
        print('AuthCallbackScreen: Profile created, navigating to home');
        // Navigate to home
        if (mounted) {
          context.go('/home');
        }
      } else {
        print('AuthCallbackScreen: No pending profile, going to profiles');
        // No pending profile, just go to profiles
        if (mounted) {
          context.go('/profiles');
        }
      }
    } else {
      print('AuthCallbackScreen: Authentication failed or not complete');
      // Authentication failed, clear any pending data and go back to profiles
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_profile_name');
      await prefs.remove('pending_profile_color');
      await prefs.remove('pending_profile_icon');
      
      if (mounted) {
        context.go('/profiles');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFE50914)),
            SizedBox(height: 24),
            Text(
              'Completing sign in...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
