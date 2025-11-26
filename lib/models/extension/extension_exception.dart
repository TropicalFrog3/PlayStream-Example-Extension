/// Enum representing different types of extension errors
enum ExtensionErrorType {
  networkError,
  downloadFailed,
  installationFailed,
  invalidProvider,
  providerNotFound,
  methodCallFailed,
  timeout,
}

/// Exception class for extension-related errors
class ExtensionException implements Exception {
  final ExtensionErrorType type;
  final String message;
  final String? extensionId;
  final dynamic originalError;
  final StackTrace? stackTrace;

  ExtensionException({
    required this.type,
    required this.message,
    this.extensionId,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('ExtensionException: $message');
    if (extensionId != null) {
      buffer.write(' (Extension: $extensionId)');
    }
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    return buffer.toString();
  }

  /// Creates a network error exception
  factory ExtensionException.networkError(String message, {String? extensionId, dynamic originalError}) {
    return ExtensionException(
      type: ExtensionErrorType.networkError,
      message: message,
      extensionId: extensionId,
      originalError: originalError,
    );
  }

  /// Creates a download failed exception
  factory ExtensionException.downloadFailed(String message, {String? extensionId, dynamic originalError}) {
    return ExtensionException(
      type: ExtensionErrorType.downloadFailed,
      message: message,
      extensionId: extensionId,
      originalError: originalError,
    );
  }

  /// Creates an installation failed exception
  factory ExtensionException.installationFailed(String message, {String? extensionId, dynamic originalError}) {
    return ExtensionException(
      type: ExtensionErrorType.installationFailed,
      message: message,
      extensionId: extensionId,
      originalError: originalError,
    );
  }

  /// Creates an invalid provider exception
  factory ExtensionException.invalidProvider(String message, {String? extensionId, dynamic originalError}) {
    return ExtensionException(
      type: ExtensionErrorType.invalidProvider,
      message: message,
      extensionId: extensionId,
      originalError: originalError,
    );
  }

  /// Creates a provider not found exception
  factory ExtensionException.providerNotFound(String extensionId) {
    return ExtensionException(
      type: ExtensionErrorType.providerNotFound,
      message: 'Provider not found for extension: $extensionId',
      extensionId: extensionId,
    );
  }

  /// Creates a method call failed exception
  factory ExtensionException.methodCallFailed(String message, {String? extensionId, dynamic originalError}) {
    return ExtensionException(
      type: ExtensionErrorType.methodCallFailed,
      message: message,
      extensionId: extensionId,
      originalError: originalError,
    );
  }

  /// Creates a timeout exception
  factory ExtensionException.timeout(String message, {String? extensionId}) {
    return ExtensionException(
      type: ExtensionErrorType.timeout,
      message: message,
      extensionId: extensionId,
    );
  }
}
