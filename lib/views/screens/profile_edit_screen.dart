import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user/user_profile.dart';
import '../widgets/profile_avatar.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  final UserProfile? profile;

  const ProfileEditScreen({super.key, this.profile});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late TextEditingController _nameController;
  late String _selectedColor;
  late String _selectedIcon;

  final List<String> _colors = [
    '#E50914', // Red
    '#0080FF', // Blue
    '#FFB800', // Yellow
    '#00C853', // Green
    '#9C27B0', // Purple
    '#FF5722', // Orange
    '#00BCD4', // Cyan
    '#FF4081', // Pink
  ];

  final List<String> _icons = [
    '😊', '😎', '🤓', '😇', '🥳', '🤩', '😺', '🐶',
    '🦊', '🐼', '🐨', '🦁', '🐯', '🦄', '🐸', '🐙',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.name ?? '');
    _selectedColor = widget.profile?.avatarColor ?? _colors[0];
    _selectedIcon = widget.profile?.avatarIcon ?? _icons[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.profile == null ? 'Add Profile' : 'Edit Profile',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Preview
            Center(
              child: ProfileAvatar(
                profile: UserProfile(
                  id: '',
                  name: _nameController.text.isEmpty ? 'User' : _nameController.text,
                  avatarColor: _selectedColor,
                  avatarIcon: _selectedIcon,
                  createdAt: DateTime.now(),
                  lastUsed: DateTime.now(),
                ),
                size: 120,
              ),
            ),
            const SizedBox(height: 32),

            // Name input
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFE50914)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Color selection
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose Color',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _parseColor(color),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Icon selection
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose Icon',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _icons.map((icon) {
                final isSelected = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Color(0xFFE50914), width: 3)
                          : Border.all(color: Colors.white30),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Delete button (only for existing profiles)
            if (widget.profile != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _deleteProfile,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Delete Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFFE50914);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    final isNewProfile = widget.profile == null;

    // For new profiles, require authentication
    if (isNewProfile) {
      final authState = ref.read(authControllerProvider);
      final isAuthenticated = authState.value != null;
      
      if (!isAuthenticated) {
        // Save profile data temporarily
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_profile_name', _nameController.text.trim());
        await prefs.setString('pending_profile_color', _selectedColor);
        await prefs.setString('pending_profile_icon', _selectedIcon);
        
        // Show message and trigger auth
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to create a profile'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Trigger authentication
        await ref.read(authControllerProvider.notifier).login();
        
        // After login attempt, check if successful
        final newAuthState = ref.read(authControllerProvider);
        if (newAuthState.value == null && mounted) {
          // Auth failed, clear pending data
          await prefs.remove('pending_profile_name');
          await prefs.remove('pending_profile_color');
          await prefs.remove('pending_profile_icon');
          return;
        }
        
        // If we reach here, auth succeeded, but the callback screen will handle profile creation
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }
    }

    final profile = UserProfile(
      id: widget.profile?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      avatarColor: _selectedColor,
      avatarIcon: _selectedIcon,
      createdAt: widget.profile?.createdAt ?? DateTime.now(),
      lastUsed: widget.profile?.lastUsed ?? DateTime.now(),
    );
    
    if (isNewProfile) {
      await ref.read(profileControllerProvider.notifier).createProfile(profile);
      // Auto-select the newly created profile
      await ref.read(profileControllerProvider.notifier).selectProfile(profile.id);
    } else {
      await ref.read(profileControllerProvider.notifier).updateProfile(profile);
    }

    if (mounted) {
      ref.invalidate(profilesProvider);
      
      // If this was a new profile, navigate to home
      if (isNewProfile) {
        Navigator.pop(context);
        context.go('/home');
      } else {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _deleteProfile() async{
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Profile?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete this profile and all its data.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.profile != null) {
      await ref.read(profileControllerProvider.notifier).deleteProfile(widget.profile!.id);
      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(profilesProvider);
      }
    }
  }
}

// Profile Management Screen
class ProfileManageScreen extends ConsumerWidget {
  final List<UserProfile> profiles;

  const ProfileManageScreen({super.key, required this.profiles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Profiles',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 24,
            children: profiles.map((profile) {
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileEditScreen(profile: profile),
                    ),
                  ).then((_) => ref.invalidate(profilesProvider));
                },
                child: SizedBox(
                  width: 140,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          ProfileAvatar(
                            profile: profile,
                            size: 140,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
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
            }).toList(),
          ),
        ),
      ),
    );
  }
}
