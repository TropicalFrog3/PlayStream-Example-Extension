import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import '../models/user/app_user.dart';
import '../services/auth/auth0_service.dart';
import '../services/trakt/trakt_client.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<AppUser?>>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  final Ref _ref;
  final Auth0Service _auth0Service = Auth0Service();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  AuthController(this._ref) : super(const AsyncValue.loading()) {
    _loadUser();
  }
  
  Future<void> _loadUser() async {
    try {
      final box = await Hive.openBox<AppUser>('user');
      final user = box.get('current_user');
      
      if (user != null) {
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> login() async {
    print('AuthController: Starting login...');
    state = const AsyncValue.loading();
    
    try {
      final user = await _auth0Service.login();
      print('AuthController: Auth0Service returned user: ${user?.email}');
      
      if (user != null) {
        print('AuthController: Saving user to Hive...');
        final box = await Hive.openBox<AppUser>('user');
        await box.put('current_user', user);
        print('AuthController: User saved to Hive');
        state = AsyncValue.data(user);
        print('AuthController: State updated with user');
      } else {
        print('AuthController: No user returned from Auth0Service');
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      print('AuthController: Login error: $e');
      print('AuthController: Stack trace: $stack');
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> logout() async {
    try {
      await _auth0Service.logout();
      
      final box = await Hive.openBox<AppUser>('user');
      await box.delete('current_user');
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> connectTrakt(String accessToken, String refreshToken, DateTime expiry) async {
    final currentUser = state.value;
    if (currentUser == null) return;
    
    final updatedUser = currentUser.copyWith(
      traktAccessToken: accessToken,
      traktRefreshToken: refreshToken,
      traktTokenExpiry: expiry,
    );
    
    final box = await Hive.openBox<AppUser>('user');
    await box.put('current_user', updatedUser);
    
    state = AsyncValue.data(updatedUser);
  }
  
  Future<void> disconnectTrakt() async {
    final currentUser = state.value;
    if (currentUser == null) return;
    
    final updatedUser = currentUser.copyWith(
      traktAccessToken: null,
      traktRefreshToken: null,
      traktTokenExpiry: null,
    );
    
    final box = await Hive.openBox<AppUser>('user');
    await box.put('current_user', updatedUser);
    
    state = AsyncValue.data(updatedUser);
  }
}
