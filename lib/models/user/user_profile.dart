import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 2)
class UserProfile {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String avatarColor;
  
  @HiveField(3)
  final String? avatarIcon;
  
  @HiveField(4)
  final DateTime createdAt;
  
  @HiveField(5)
  final DateTime lastUsed;
  
  @HiveField(6)
  final String? traktAccessToken;
  
  @HiveField(7)
  final String? traktRefreshToken;
  
  @HiveField(8)
  final DateTime? traktTokenExpiry;
  
  @HiveField(9)
  final String? traktUsername;
  
  @HiveField(10)
  final DateTime? lastTraktSync;
  
  UserProfile({
    required this.id,
    required this.name,
    required this.avatarColor,
    this.avatarIcon,
    required this.createdAt,
    required this.lastUsed,
    this.traktAccessToken,
    this.traktRefreshToken,
    this.traktTokenExpiry,
    this.traktUsername,
    this.lastTraktSync,
  });
  
  bool get isTraktConnected => traktAccessToken != null && traktUsername != null;
  
  bool get isTraktTokenExpired {
    if (traktTokenExpiry == null) return true;
    return DateTime.now().isAfter(traktTokenExpiry!);
  }
  
  UserProfile copyWith({
    String? id,
    String? name,
    String? avatarColor,
    String? avatarIcon,
    DateTime? createdAt,
    DateTime? lastUsed,
    String? traktAccessToken,
    String? traktRefreshToken,
    DateTime? traktTokenExpiry,
    String? traktUsername,
    DateTime? lastTraktSync,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarColor: avatarColor ?? this.avatarColor,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      traktAccessToken: traktAccessToken ?? this.traktAccessToken,
      traktRefreshToken: traktRefreshToken ?? this.traktRefreshToken,
      traktTokenExpiry: traktTokenExpiry ?? this.traktTokenExpiry,
      traktUsername: traktUsername ?? this.traktUsername,
      lastTraktSync: lastTraktSync ?? this.lastTraktSync,
    );
  }
  
  UserProfile disconnectTrakt() {
    return UserProfile(
      id: id,
      name: name,
      avatarColor: avatarColor,
      avatarIcon: avatarIcon,
      createdAt: createdAt,
      lastUsed: lastUsed,
      traktAccessToken: null,
      traktRefreshToken: null,
      traktTokenExpiry: null,
      traktUsername: null,
      lastTraktSync: null,
    );
  }
}
