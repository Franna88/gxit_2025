# Android 14 Compatibility Fix

## Issue
The app was crashing at startup in the Google Play Store due to compatibility issues with Android 14 (SDK 34). Google Play Console reported:

> Your bundle targets SDK 34, but uses a Play Core library that cannot be used with that version. Your current com.google.android.play.core:1.10.3 library is incompatible with targetSdkVersion 34 (Android 14), which introduces a backwards-incompatible change to broadcast receivers and may cause app crashes.

## Changes Made

### 1. Replaced Play Core with Modern Play Libraries
We replaced the deprecated Play Core library with its successor libraries that are fully compatible with Android 14:

```gradle
// Use Play In-App Update and Play In-App Review instead
implementation 'com.google.android.play:app-update:2.1.0'
implementation 'com.google.android.play:review:2.0.1'
```

These libraries are the modern replacements for Play Core, and they're designed to be compatible with Android 14.

### 2. Updated ProGuard Rules
Added proper ProGuard rules for the new libraries:

```proguard
# Play In-App Update and Play In-App Review
-keep class com.google.android.play.** { *; }
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-keep class com.google.android.play.core.review.** { *; }

# Important classes for Android 14 compatibility
-keep class com.google.android.play.core.common.PlayCoreDialogWrapperActivity
-keep class com.google.android.play.core.common.IntentSenderForResultStarter
-keep class com.google.android.play.core.listener.StateUpdatedListener
```

## Why This Works
The Google Play Core library has been deprecated in favor of more focused libraries like Play In-App Update and Play In-App Review. These newer libraries:

1. Are fully compatible with Android 14 (SDK 34)
2. Handle broadcast receivers correctly according to Android 14's stricter requirements
3. Are modular, allowing us to include only what we need
4. Are actively maintained by Google with better compatibility guarantees

This approach follows Google's recommended migration path from Play Core to the newer libraries while ensuring full compatibility with Android 14. 