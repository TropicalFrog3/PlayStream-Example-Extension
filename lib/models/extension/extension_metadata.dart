import 'package:hive/hive.dart';

part 'extension_metadata.g.dart';

/// Model representing an installed extension with local metadata
@HiveType(typeId: 11)
class ExtensionMetadata {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String version;

  @HiveField(3)
  final String apkPath;

  @HiveField(4)
  final bool isEnabled;

  @HiveField(5)
  final DateTime installedAt;

  @HiveField(6)
  final Map<String, dynamic> settings;

  ExtensionMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.apkPath,
    required this.isEnabled,
    required this.installedAt,
    required this.settings,
  });

  ExtensionMetadata copyWith({
    String? id,
    String? name,
    String? version,
    String? apkPath,
    bool? isEnabled,
    DateTime? installedAt,
    Map<String, dynamic>? settings,
  }) {
    return ExtensionMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      apkPath: apkPath ?? this.apkPath,
      isEnabled: isEnabled ?? this.isEnabled,
      installedAt: installedAt ?? this.installedAt,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'apkPath': apkPath,
      'isEnabled': isEnabled,
      'installedAt': installedAt.toIso8601String(),
      'settings': settings,
    };
  }

  factory ExtensionMetadata.fromJson(Map<String, dynamic> json) {
    return ExtensionMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      apkPath: json['apkPath'] as String,
      isEnabled: json['isEnabled'] as bool,
      installedAt: DateTime.parse(json['installedAt'] as String),
      settings: Map<String, dynamic>.from(json['settings'] as Map),
    );
  }
}
