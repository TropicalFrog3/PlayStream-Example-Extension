import 'package:hive_flutter/hive_flutter.dart';
import '../models/user/user_profile.dart';

class ProfileService {
  static const String _boxName = 'user_profiles';
  static const String _currentProfileKey = 'current_profile_id';
  
  static ProfileService? _instance;
  static ProfileService get instance {
    _instance ??= ProfileService._();
    return _instance!;
  }
  
  ProfileService._();
  
  Box<UserProfile>? _profileBox;
  Box? _settingsBox;
  bool _isInitialized = false;
  
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      _profileBox = await Hive.openBox<UserProfile>(_boxName);
    } catch (e) {
      // If there's a schema mismatch, delete the old box and create a new one
      print('Error opening profile box, clearing old data: $e');
      await Hive.deleteBoxFromDisk(_boxName);
      _profileBox = await Hive.openBox<UserProfile>(_boxName);
    }
    
    _settingsBox = await Hive.openBox('settings');
    
    _isInitialized = true;
  }
  
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }
  
  Future<List<UserProfile>> getAllProfiles() async {
    await _ensureInitialized();
    return _profileBox!.values.toList()
      ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
  }
  
  Future<UserProfile?> getCurrentProfile() async {
    await _ensureInitialized();
    final currentId = _settingsBox!.get(_currentProfileKey);
    if (currentId == null) return null;
    return _profileBox!.get(currentId);
  }
  
  Future<void> setCurrentProfile(String profileId) async {
    await _ensureInitialized();
    await _settingsBox!.put(_currentProfileKey, profileId);
    
    // Update last used timestamp
    final profile = _profileBox!.get(profileId);
    if (profile != null) {
      await _profileBox!.put(
        profileId,
        profile.copyWith(lastUsed: DateTime.now()),
      );
    }
  }
  
  Future<void> createProfile(UserProfile profile) async {
    await _ensureInitialized();
    await _profileBox!.put(profile.id, profile);
  }
  
  Future<void> updateProfile(UserProfile profile) async {
    await _ensureInitialized();
    await _profileBox!.put(profile.id, profile);
  }
  
  Future<void> deleteProfile(String profileId) async {
    await _ensureInitialized();
    await _profileBox!.delete(profileId);
    
    // If deleted profile was current, switch to another
    final currentId = _settingsBox!.get(_currentProfileKey);
    if (currentId == profileId) {
      final profiles = await getAllProfiles();
      if (profiles.isNotEmpty) {
        await setCurrentProfile(profiles.first.id);
      }
    }
  }
  
  Future<bool> canAddMoreProfiles() async {
    await _ensureInitialized();
    final profiles = await getAllProfiles();
    return profiles.length < 5; // Max 5 profiles like Netflix
  }
}
