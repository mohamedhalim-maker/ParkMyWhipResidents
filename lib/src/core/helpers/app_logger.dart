import 'dart:developer' as developer;

/// Centralized logging utility for the app.
/// Uses dart:developer log function for better debugging experience.
class AppLogger {
  AppLogger._();

  /// Log an informational message
  static void info(String message, {String? name}) {
    developer.log(
      message,
      name: name ?? 'INFO',
      level: 800, // INFO level
    );
  }

  /// Log a debug message
  static void debug(String message, {String? name}) {
    developer.log(
      message,
      name: name ?? 'DEBUG',
      level: 500, // FINE level
    );
  }

  /// Log a warning message
  static void warning(String message, {String? name}) {
    developer.log(
      message,
      name: name ?? 'WARNING',
      level: 900, // WARNING level
    );
  }

  /// Log an error message with optional error and stack trace
  static void error(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name ?? 'ERROR',
      level: 1000, // SEVERE level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log deep link related messages
  static void deepLink(String message) {
    developer.log(message, name: 'DeepLink');
  }

  /// Log authentication related messages
  static void auth(String message) {
    developer.log(message, name: 'Auth');
  }

  /// Log navigation related messages
  static void navigation(String message) {
    developer.log(message, name: 'Navigation');
  }
}
