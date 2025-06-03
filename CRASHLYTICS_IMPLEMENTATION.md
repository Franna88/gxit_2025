# Firebase Crashlytics Implementation

This document outlines how Firebase Crashlytics has been implemented in the app.

## Configuration Files

### Android Configuration

1. The Crashlytics Gradle plugin is included in:
   - `android/build.gradle.kts` - Plugin dependency
   - `android/settings.gradle.kts` - Plugin declaration
   - `android/app/build.gradle` - Plugin application and native dependencies

### Flutter Configuration

1. The Crashlytics Flutter package is included in `pubspec.yaml`:
   ```yaml
   dependencies:
     firebase_crashlytics: ^4.0.1
   ```

## Implementation Details

### Initialization

Firebase Crashlytics is initialized in `main.dart`:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
await crashlyticsService.initializeCrashlytics();
```

### Error Handling

1. **Flutter Errors**: All Flutter framework errors are automatically reported to Crashlytics
2. **Zone Errors**: All uncaught Dart errors are reported via the `runZonedGuarded` handler
3. **Manual Error Reporting**: Errors can be manually reported using the `CrashlyticsService`

### CrashlyticsService API

The `CrashlyticsService` class (`lib/services/crashlytics_service.dart`) provides the following methods:

- `initializeCrashlytics({String? userId})` - Initialize Crashlytics with optional user ID
- `setUserIdentifier(String userId)` - Set user ID for crash reports
- `setCustomKey(String key, dynamic value)` - Add custom key/value data to crash reports
- `logError(dynamic error, StackTrace? stackTrace, {...})` - Report non-fatal errors
- `log(String message)` - Add custom log messages to crash reports
- `testCrashlytics()` - Force a crash for testing
- `testNonFatalError()` - Report a non-fatal error for testing

## Testing Crashlytics

You can test Crashlytics functionality using the built-in test button in the app:

1. Open the app and navigate to the Home screen
2. Tap the red warning icon in the app bar
3. Choose one of the test options:
   - **Test Non-Fatal Error**: Reports a non-fatal error to Crashlytics
   - **Force Crash**: Deliberately crashes the app to test crash reporting

## Crashlytics Dashboard

Crashes will be reported to the Firebase Console. To view them:

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click on "Crashlytics" in the left sidebar
4. View and analyze crash reports 