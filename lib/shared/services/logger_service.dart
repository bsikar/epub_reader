import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// A centralized logging service for the application.
///
/// Provides consistent logging across all features with different log levels:
/// - debug: Development-only logs
/// - info: General information
/// - warning: Warning messages
/// - error: Error messages with optional stack traces
///
/// Usage:
/// ```dart
/// final logger = getIt<LoggerService>();
/// logger.info('User opened book', data: {'bookId': bookId});
/// logger.error('Failed to import EPUB', error: e, stackTrace: stackTrace);
/// ```
@singleton
class LoggerService {
  static const String _tag = 'EpubReader';

  /// Log a debug message (only visible in debug mode)
  void debug(
    String message, {
    Map<String, dynamic>? data,
    String? feature,
  }) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, data: data, feature: feature);
    }
  }

  /// Log an informational message
  void info(
    String message, {
    Map<String, dynamic>? data,
    String? feature,
  }) {
    _log(LogLevel.info, message, data: data, feature: feature);
  }

  /// Log a warning message
  void warning(
    String message, {
    Map<String, dynamic>? data,
    String? feature,
  }) {
    _log(LogLevel.warning, message, data: data, feature: feature);
  }

  /// Log an error message
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? feature,
  }) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
      feature: feature,
    );
  }

  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? feature,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final featureTag = feature != null ? '[$feature]' : '';
    final levelTag = '[${level.name.toUpperCase()}]';

    final buffer = StringBuffer();
    buffer.write('$timestamp $_tag $levelTag $featureTag $message');

    if (data != null && data.isNotEmpty) {
      buffer.write(' | Data: ${data.toString()}');
    }

    if (error != null) {
      buffer.write(' | Error: ${error.toString()}');
    }

    if (stackTrace != null) {
      buffer.write('\nStack trace:\n${stackTrace.toString()}');
    }

    final logMessage = buffer.toString();

    // In debug mode, use debugPrint for better visibility
    if (kDebugMode) {
      debugPrint(logMessage);
    } else {
      // In release mode, you could send to a logging service
      // For now, just print to console
      print(logMessage);
    }

    // TODO: Optionally send to analytics/crash reporting service
    // Example: FirebaseCrashlytics, Sentry, etc.
  }

  /// Log the start of a feature/operation
  void logFeatureStart(String feature, String operation) {
    info('Starting $operation', feature: feature);
  }

  /// Log the end of a feature/operation
  void logFeatureEnd(String feature, String operation, {bool success = true}) {
    if (success) {
      info('Completed $operation', feature: feature);
    } else {
      warning('Failed $operation', feature: feature);
    }
  }

  /// Log a user action
  void logUserAction(String action, {Map<String, dynamic>? data}) {
    info('User action: $action', data: data);
  }

  /// Log performance metrics
  void logPerformance(
    String operation,
    Duration duration, {
    String? feature,
    Map<String, dynamic>? data,
  }) {
    final performanceData = {
      'duration_ms': duration.inMilliseconds,
      ...?data,
    };
    info(
      'Performance: $operation took ${duration.inMilliseconds}ms',
      data: performanceData,
      feature: feature,
    );
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
}
