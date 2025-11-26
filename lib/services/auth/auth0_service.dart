import 'package:auth0_flutter/auth0_flutter.dart';
import '../../core/config/app_config.dart';
import '../../models/user/app_user.dart';

class Auth0Service {
  late final Auth0 _auth0;
  
  Auth0Service() {
    _auth0 = Auth0(
      AppConfig.auth0Domain,
      AppConfig.auth0ClientId,
    );
  }
  
  Future<AppUser?> login() async {
    try {
      print('Auth0Service: Starting login...');
      
      final credentials = await _auth0.webAuthentication(scheme: "playstream").login();
      
      print('Auth0Service: Login successful, user: ${credentials.user.sub}');
      
      final userProfile = credentials.user;
      
      // Check if user has admin role from Auth0 metadata
      final roles = userProfile.customClaims?['roles'] as List?;
      final isAdmin = roles?.contains('admin') ?? false;
      
      final user = AppUser(
        id: userProfile.sub,
        email: userProfile.email ?? '',
        name: userProfile.name,
        picture: userProfile.pictureUrl?.toString(),
        role: isAdmin ? UserRole.admin : UserRole.normal,
      );
      
      return user;
    } catch (e, stackTrace) {
      print('Auth0Service: Login error: $e - stack: $stackTrace');
      return null;
    }
  }
  
  Future<void> logout() async {
    try {
      await _auth0.webAuthentication(scheme: 'playstream').logout();
    } catch (e) {
      print('Logout error: $e');
    }
  }
  
  Future<Credentials?> getCredentials() async {
    try {
      return await _auth0.credentialsManager.credentials();
    } catch (e) {
      print('Get credentials error: $e');
      return null;
    }
  }
}
