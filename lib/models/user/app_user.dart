import 'package:hive/hive.dart';

part 'app_user.g.dart';

@HiveType(typeId: 0)
class AppUser {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String email;
  
  @HiveField(2)
  final String? name;
  
  @HiveField(3)
  final String? picture;
  
  @HiveField(4)
  final UserRole role;
  
  @HiveField(5)
  final String? traktAccessToken;
  
  @HiveField(6)
  final String? traktRefreshToken;
  
  @HiveField(7)
  final DateTime? traktTokenExpiry;
  
  AppUser({
    required this.id,
    required this.email,
    this.name,
    this.picture,
    this.role = UserRole.normal,
    this.traktAccessToken,
    this.traktRefreshToken,
    this.traktTokenExpiry,
  });
  
  bool get isAdmin => role == UserRole.admin;
  bool get isTraktConnected => traktAccessToken != null;
  
  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? picture,
    UserRole? role,
    String? traktAccessToken,
    String? traktRefreshToken,
    DateTime? traktTokenExpiry,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      picture: picture ?? this.picture,
      role: role ?? this.role,
      traktAccessToken: traktAccessToken ?? this.traktAccessToken,
      traktRefreshToken: traktRefreshToken ?? this.traktRefreshToken,
      traktTokenExpiry: traktTokenExpiry ?? this.traktTokenExpiry,
    );
  }
}

@HiveType(typeId: 1)
enum UserRole {
  @HiveField(0)
  normal,
  
  @HiveField(1)
  admin,
}
