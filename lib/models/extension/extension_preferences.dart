import 'package:hive/hive.dart';

part 'extension_preferences.g.dart';

/// Model for storing user preferences for an extension
@HiveType(typeId: 12)
class ExtensionPreferences {
  @HiveField(0)
  final String extensionId;

  @HiveField(1)
  final Map<String, String> serverPreferences; // contentId -> serverId

  @HiveField(2)
  final DateTime? lastUpdateCheck;

  @HiveField(3)
  final int consecutiveFailures;

  @HiveField(4)
  final DateTime? lastFailureTime;

  @HiveField(5)
  final bool isProblematic;

  ExtensionPreferences({
    required this.extensionId,
    required this.serverPreferences,
    this.lastUpdateCheck,
    this.consecutiveFailures = 0,
    this.lastFailureTime,
    this.isProblematic = false,
  });

  ExtensionPreferences copyWith({
    String? extensionId,
    Map<String, String>? serverPreferences,
    DateTime? lastUpdateCheck,
    int? consecutiveFailures,
    DateTime? lastFailureTime,
    bool? isProblematic,
  }) {
    return ExtensionPreferences(
      extensionId: extensionId ?? this.extensionId,
      serverPreferences: serverPreferences ?? this.serverPreferences,
      lastUpdateCheck: lastUpdateCheck ?? this.lastUpdateCheck,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      lastFailureTime: lastFailureTime ?? this.lastFailureTime,
      isProblematic: isProblematic ?? this.isProblematic,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'extensionId': extensionId,
      'serverPreferences': serverPreferences,
      'lastUpdateCheck': lastUpdateCheck?.toIso8601String(),
      'consecutiveFailures': consecutiveFailures,
      'lastFailureTime': lastFailureTime?.toIso8601String(),
      'isProblematic': isProblematic,
    };
  }

  factory ExtensionPreferences.fromJson(Map<String, dynamic> json) {
    return ExtensionPreferences(
      extensionId: json['extensionId'] as String,
      serverPreferences: Map<String, String>.from(json['serverPreferences'] as Map),
      lastUpdateCheck: json['lastUpdateCheck'] != null
          ? DateTime.parse(json['lastUpdateCheck'] as String)
          : null,
      consecutiveFailures: json['consecutiveFailures'] as int? ?? 0,
      lastFailureTime: json['lastFailureTime'] != null
          ? DateTime.parse(json['lastFailureTime'] as String)
          : null,
      isProblematic: json['isProblematic'] as bool? ?? false,
    );
  }
}
