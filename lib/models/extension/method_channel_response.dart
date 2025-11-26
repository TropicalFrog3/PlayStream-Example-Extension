/// Response data structure for method channel communication with native code.
/// Wraps the result or error from native extension method calls.
class MethodChannelResponse {
  final bool success;
  final dynamic data;
  final String? errorCode;
  final String? errorMessage;
  final dynamic errorDetails;

  MethodChannelResponse({
    required this.success,
    this.data,
    this.errorCode,
    this.errorMessage,
    this.errorDetails,
  });

  /// Creates a successful response
  factory MethodChannelResponse.success(dynamic data) {
    return MethodChannelResponse(
      success: true,
      data: data,
    );
  }

  /// Creates an error response
  factory MethodChannelResponse.error({
    required String errorCode,
    required String errorMessage,
    dynamic errorDetails,
  }) {
    return MethodChannelResponse(
      success: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
      errorDetails: errorDetails,
    );
  }

  /// Creates a response from a map received from method channel
  factory MethodChannelResponse.fromMap(Map<String, dynamic> map) {
    return MethodChannelResponse(
      success: map['success'] as bool? ?? false,
      data: map['data'],
      errorCode: map['errorCode'] as String?,
      errorMessage: map['errorMessage'] as String?,
      errorDetails: map['errorDetails'],
    );
  }

  /// Converts the response to a map for method channel transmission
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'data': data,
      'errorCode': errorCode,
      'errorMessage': errorMessage,
      'errorDetails': errorDetails,
    };
  }

  /// Returns true if the response represents an error
  bool get isError => !success;

  /// Gets the error description if this is an error response
  String? get errorDescription {
    if (!isError) return null;
    return errorMessage ?? 'Unknown error';
  }
}
