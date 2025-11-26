import 'package:hive/hive.dart';

part 'cache_entry.g.dart';

/// Model for storing cached data with expiration
@HiveType(typeId: 13)
class CacheEntry<T> {
  @HiveField(0)
  final String key;

  @HiveField(1)
  final dynamic data;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final int expirationMilliseconds;

  CacheEntry({
    required this.key,
    required this.data,
    required this.timestamp,
    required Duration expirationDuration,
  }) : expirationMilliseconds = expirationDuration.inMilliseconds;

  /// Get the expiration duration
  Duration get expirationDuration => Duration(milliseconds: expirationMilliseconds);

  /// Check if the cache entry is still valid
  bool get isValid {
    final age = DateTime.now().difference(timestamp);
    return age < expirationDuration;
  }

  /// Get the age of the cache entry
  Duration get age => DateTime.now().difference(timestamp);

  /// Get the cached data if valid, null otherwise
  T? get validData {
    return isValid ? data as T : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'expirationDuration': expirationDuration.inMilliseconds,
    };
  }

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      key: json['key'] as String,
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp'] as String),
      expirationDuration: Duration(milliseconds: json['expirationDuration'] as int),
    );
  }
}
