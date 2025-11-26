/// Enum representing different log levels for console output
enum LogLevel {
  debug,
  info,
  warn,
  error;

  /// Get the display prefix for this log level
  String get prefix {
    switch (this) {
      case LogLevel.debug:
        return '[DBG]';
      case LogLevel.info:
        return '[INFO]';
      case LogLevel.warn:
        return '[WARN]';
      case LogLevel.error:
        return '[ERR]';
    }
  }

  /// Parse log level from string
  static LogLevel fromString(String level) {
    switch (level.toLowerCase()) {
      case 'debug':
      case 'dbg':
        return LogLevel.debug;
      case 'info':
        return LogLevel.info;
      case 'warn':
      case 'warning':
        return LogLevel.warn;
      case 'error':
      case 'err':
        return LogLevel.error;
      default:
        return LogLevel.info;
    }
  }
}

/// Model representing a single console log entry from extension execution
class ConsoleLogEntry {
  final String message;
  final LogLevel level;
  final DateTime timestamp;

  ConsoleLogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
  });

  /// Get formatted timestamp in YYYY-MM-DD HH:MM:SS format
  String get formattedTimestamp {
    return '${timestamp.year}-'
        '${timestamp.month.toString().padLeft(2, '0')}-'
        '${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  /// Get the log level prefix
  String get levelPrefix => level.prefix;

  /// Create ConsoleLogEntry from JSON
  factory ConsoleLogEntry.fromJson(Map<String, dynamic> json) {
    return ConsoleLogEntry(
      message: json['message'] as String,
      level: LogLevel.fromString(json['level'] as String),
      timestamp: json['timestamp'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert ConsoleLogEntry to JSON
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'level': level.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return '$formattedTimestamp $levelPrefix $message';
  }
}
