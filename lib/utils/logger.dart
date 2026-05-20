import 'package:logger/logger.dart';

/// Centralized logging for the Parkinson's Insole App.
///
/// Usage:
///   AppLogger.ble('Connecting to device');
///   AppLogger.telemetry('FOG risk: 72%');
///   AppLogger.error('Parse failed', e, stackTrace);
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: Level.debug,
  );

  // ── Namespaced log methods ─────────────────────────────────────────────────

  /// BLE-specific log (scanning, connection, characteristics)
  static void ble(String message, {Object? error}) {
    if (error != null) {
      _logger.w('[BLE] $message\nError: $error');
    } else {
      _logger.d('[BLE] $message');
    }
  }

  /// Telemetry data log (parsed packets, FOG risk updates)
  static void telemetry(String message) {
    _logger.t('[TELEMETRY] $message');
  }

  /// UI-level log (navigation, state changes)
  static void ui(String message) {
    _logger.d('[UI] $message');
  }

  /// General info log
  static void info(String message) {
    _logger.i('[INFO] $message');
  }

  /// Error log with optional stack trace
  static void error(String message, Object? error, StackTrace? stackTrace) {
    _logger.e('[ERROR] $message', error: error, stackTrace: stackTrace);
  }

  /// Warning log
  static void warn(String message) {
    _logger.w('[WARN] $message');
  }
}
