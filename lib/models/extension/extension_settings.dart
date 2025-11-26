/// Model representing configuration settings for an extension provider
class ExtensionSettings {
  final String extensionId;
  final Map<String, dynamic> configuration;
  final List<String> availableServers;
  final String? preferredServer;

  ExtensionSettings({
    required this.extensionId,
    required this.configuration,
    required this.availableServers,
    this.preferredServer,
  });

  factory ExtensionSettings.fromJson(Map<String, dynamic> json) {
    return ExtensionSettings(
      extensionId: json['extensionId'] as String,
      configuration: Map<String, dynamic>.from(json['configuration'] as Map? ?? {}),
      availableServers: (json['availableServers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      preferredServer: json['preferredServer'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'extensionId': extensionId,
      'configuration': configuration,
      'availableServers': availableServers,
      'preferredServer': preferredServer,
    };
  }

  ExtensionSettings copyWith({
    String? extensionId,
    Map<String, dynamic>? configuration,
    List<String>? availableServers,
    String? preferredServer,
  }) {
    return ExtensionSettings(
      extensionId: extensionId ?? this.extensionId,
      configuration: configuration ?? this.configuration,
      availableServers: availableServers ?? this.availableServers,
      preferredServer: preferredServer ?? this.preferredServer,
    );
  }
}
