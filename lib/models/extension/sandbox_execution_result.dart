import 'console_log_entry.dart';

/// Model representing the result of a sandbox extension execution
/// 
/// Encapsulates both the output from the extension method and any
/// console logs captured during execution.
class SandboxExecutionResult {
  /// The output returned by the extension method
  /// Can be any type (Map, List, String, etc.)
  final dynamic output;

  /// List of console log entries captured during execution
  final List<ConsoleLogEntry> consoleLogs;

  /// Whether the execution was successful
  final bool success;

  /// Error message if execution failed
  final String? errorMessage;

  /// Timestamp when the execution completed
  final DateTime timestamp;

  SandboxExecutionResult({
    required this.output,
    required this.consoleLogs,
    required this.success,
    this.errorMessage,
    required this.timestamp,
  });

  /// Create a successful execution result
  factory SandboxExecutionResult.success({
    required dynamic output,
    required List<ConsoleLogEntry> consoleLogs,
  }) {
    return SandboxExecutionResult(
      output: output,
      consoleLogs: consoleLogs,
      success: true,
      errorMessage: null,
      timestamp: DateTime.now(),
    );
  }

  /// Create a failed execution result
  factory SandboxExecutionResult.failure({
    required String errorMessage,
    List<ConsoleLogEntry>? consoleLogs,
  }) {
    return SandboxExecutionResult(
      output: null,
      consoleLogs: consoleLogs ?? [],
      success: false,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
    );
  }

  /// Create SandboxExecutionResult from JSON
  factory SandboxExecutionResult.fromJson(Map<String, dynamic> json) {
    return SandboxExecutionResult(
      output: json['output'],
      consoleLogs: (json['logs'] as List<dynamic>?)
              ?.map((log) => ConsoleLogEntry.fromJson(log as Map<String, dynamic>))
              .toList() ??
          [],
      success: json['success'] as bool? ?? false,
      errorMessage: json['error'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Convert SandboxExecutionResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'output': output,
      'logs': consoleLogs.map((log) => log.toJson()).toList(),
      'success': success,
      'error': errorMessage,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Get formatted output as string
  String getFormattedOutput() {
    if (!success && errorMessage != null) {
      return 'ERROR: $errorMessage';
    }
    
    if (output == null) {
      return 'No output';
    }

    // If output is already a string, return it
    if (output is String) {
      return output;
    }

    // Otherwise, convert to JSON string for display
    try {
      return output.toString();
    } catch (e) {
      return 'Unable to format output: $e';
    }
  }
}
