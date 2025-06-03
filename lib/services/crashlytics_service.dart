import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// A service class for managing Firebase Crashlytics functionality
class CrashlyticsService {
  /// Initialize Crashlytics with custom user identifiers
  Future<void> initializeCrashlytics({String? userId}) async {
    // Only enable Crashlytics in non-debug mode by default
    final bool shouldEnable = !kDebugMode;

    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(shouldEnable);

    // Set user ID if provided
    if (userId != null && userId.isNotEmpty) {
      await setUserIdentifier(userId);
    }

    print(
        'Crashlytics initialized: collection ${shouldEnable ? 'enabled' : 'disabled'}');
  }

  /// Set a user identifier for crash reports
  Future<void> setUserIdentifier(String userId) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  /// Log a custom key/value pair to crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    await FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  /// Log a non-fatal error or exception
  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object>? information,
    bool fatal = false,
  }) async {
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      information: information ?? const [],
      fatal: fatal,
    );
  }

  /// Log a message to Crashlytics
  Future<void> log(String message) async {
    await FirebaseCrashlytics.instance.log(message);
  }

  /// Test Crashlytics by forcing a crash
  Future<void> testCrashlytics() async {
    // First log some custom info
    await log('Testing Crashlytics...');
    await setCustomKey('test_mode', true);

    // Force a crash
    FirebaseCrashlytics.instance.crash();
  }

  /// Test non-fatal error reporting
  Future<void> testNonFatalError() async {
    try {
      // Generate a test error
      final List<String> emptyList = [];
      // This will throw an exception
      final String element = emptyList[10];
      print(element); // This line won't execute
    } catch (e, stack) {
      // Log the error to Crashlytics
      await logError(
        e,
        stack,
        reason: 'Test non-fatal error',
        information: ['This is a test error'],
        fatal: false,
      );

      // Also print to console for debugging
      print('Non-fatal error reported to Crashlytics: $e');
    }
  }
}
