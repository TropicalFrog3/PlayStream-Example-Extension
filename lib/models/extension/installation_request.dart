/// Request data structure for extension installation via method channel
class InstallationRequest {
  final String extensionId;
  final String apkPath;

  InstallationRequest({
    required this.extensionId,
    required this.apkPath,
  });

  /// Converts the request to a map for method channel transmission
  Map<String, dynamic> toMap() {
    return {
      'extensionId': extensionId,
      'apkPath': apkPath,
    };
  }

  /// Creates a request from a map received from method channel
  factory InstallationRequest.fromMap(Map<String, dynamic> map) {
    return InstallationRequest(
      extensionId: map['extensionId'] as String,
      apkPath: map['apkPath'] as String,
    );
  }
}

/// Request data structure for extension uninstallation via method channel
class UninstallationRequest {
  final String extensionId;

  UninstallationRequest({
    required this.extensionId,
  });

  /// Converts the request to a map for method channel transmission
  Map<String, dynamic> toMap() {
    return {
      'extensionId': extensionId,
    };
  }

  /// Creates a request from a map received from method channel
  factory UninstallationRequest.fromMap(Map<String, dynamic> map) {
    return UninstallationRequest(
      extensionId: map['extensionId'] as String,
    );
  }
}
