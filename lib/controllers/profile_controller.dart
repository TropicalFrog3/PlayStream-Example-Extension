import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user/user_profile.dart';
import '../services/profile_service.dart';

final profileServiceProvider = Provider((ref) => ProfileService.instance);

final profilesProvider = FutureProvider<List<UserProfile>>((ref) async {
  final service = ref.watch(profileServiceProvider);
  return await service.getAllProfiles();
});

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final service = ref.watch(profileServiceProvider);
  return await service.getCurrentProfile();
});

class ProfileController extends StateNotifier<AsyncValue<UserProfile?>> {
  final ProfileService _profileService;
  
  ProfileController(this._profileService) : super(const AsyncValue.loading()) {
    _loadCurrentProfile();
  }
  
  Future<void> _loadCurrentProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _profileService.getCurrentProfile();
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> selectProfile(String profileId) async {
    await _profileService.setCurrentProfile(profileId);
    await _loadCurrentProfile();
  }
  
  Future<void> createProfile(UserProfile profile) async {
    await _profileService.createProfile(profile);
  }
  
  Future<void> updateProfile(UserProfile profile) async {
    await _profileService.updateProfile(profile);
    if (state.value?.id == profile.id) {
      state = AsyncValue.data(profile);
    }
  }
  
  Future<void> deleteProfile(String profileId) async {
    await _profileService.deleteProfile(profileId);
    await _loadCurrentProfile();
  }
}

final profileControllerProvider = 
    StateNotifierProvider<ProfileController, AsyncValue<UserProfile?>>((ref) {
  final service = ref.watch(profileServiceProvider);
  return ProfileController(service);
});
