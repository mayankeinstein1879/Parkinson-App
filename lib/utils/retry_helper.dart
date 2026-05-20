import 'dart:async';
import 'package:parkinson_insole_app/utils/logger.dart';

/// Provides retry logic with exponential backoff for async operations.
///
/// Usage:
///   final result = await RetryHelper.retry(
///     () => connectToBleDevice(),
///     maxAttempts: 3,
///     delay: Duration(seconds: 2),
///   );
class RetryHelper {
  RetryHelper._();

  /// Retry an async [action] up to [maxAttempts] times.
  ///
  /// - [delay]: initial wait between retries
  /// - [maxDelay]: cap on the delay (prevents infinite backoff growth)
  /// - Uses exponential backoff: delay, delay×2, delay×4…
  static Future<T> retry<T>(
    Future<T> Function() action, {
    int maxAttempts        = 3,
    Duration delay         = const Duration(seconds: 2),
    Duration maxDelay      = const Duration(seconds: 30),
    bool Function(Object)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration currentDelay = delay;

    while (true) {
      attempt++;
      try {
        return await action();
      } catch (e) {
        final canRetry = shouldRetry?.call(e) ?? true;

        if (attempt >= maxAttempts || !canRetry) {
          AppLogger.warn(
            'RetryHelper: failed after $attempt attempts — giving up. Error: $e',
          );
          throw RetryException(
            'Failed after $attempt attempt(s): $e',
            attempts: attempt,
            lastError: e,
          );
        }

        AppLogger.warn(
          'RetryHelper: attempt $attempt/$maxAttempts failed ($e). '
          'Retrying in ${currentDelay.inSeconds}s...',
        );

        await Future.delayed(currentDelay);

        // Exponential backoff — but never exceed maxDelay
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * 2)
              .clamp(0, maxDelay.inMilliseconds),
        );
      }
    }
  }
}

// ── Custom Exception ──────────────────────────────────────────────────────────

class RetryException implements Exception {
  final String message;
  final int attempts;
  final Object? lastError;

  RetryException(this.message, {required this.attempts, this.lastError});

  @override
  String toString() =>
      'RetryException: $message (after $attempts attempt(s))';
}
