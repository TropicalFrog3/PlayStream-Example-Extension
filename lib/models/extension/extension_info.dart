import 'package:hive/hive.dart';

part 'extension_info.g.dart';

/// Model representing an available extension from GitHub repository
@HiveType(typeId: 10)
class ExtensionInfo {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String version;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String downloadUrl;

  @HiveField(5)
  final String iconUrl;

  @HiveField(6)
  final int size; // in bytes

  @HiveField(7)
  final DateTime updatedAt;

  ExtensionInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.downloadUrl,
    required this.iconUrl,
    required this.size,
    required this.updatedAt,
  });

  factory ExtensionInfo.fromJson(Map<String, dynamic> json) {
    return ExtensionInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String,
      downloadUrl: json['downloadUrl'] as String,
      iconUrl: json['iconUrl'] as String,
      size: json['size'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'description': description,
      'downloadUrl': downloadUrl,
      'iconUrl': iconUrl,
      'size': size,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
