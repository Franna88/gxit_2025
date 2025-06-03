# Android 14 Compatibility Fix

## Issue
The app was crashing at startup in the Google Play Store due to compatibility issues with Android 14 (SDK 34). Google Play Console reported:

> Your bundle targets SDK 34, but uses a Play Core library that cannot be used with that version. Your current com.google.android.play.core:1.10.3 library is incompatible with targetSdkVersion 34 (Android 14), which introduces a backwards-incompatible change to broadcast receivers and may cause app crashes.

## Changes Made

### 1. Completely Replaced Play Core with Modern Play Libraries
We removed the deprecated Play Core library entirely and replaced it with its successor libraries that are fully compatible with Android 14:

```gradle
// Use Play In-App Update and Play In-App Review
implementation 'com.google.android.play:app-update:2.1.0'
implementation 'com.google.android.play:review:2.0.1'

// Add Play Core Split Compat libraries that Flutter needs
implementation 'com.google.android.play:core-common:2.0.3'
implementation 'com.google.android.play:feature-delivery:2.1.0'
implementation 'com.google.android.play:asset-delivery:2.1.0'
```

### 2. Updated ProGuard Rules
Added comprehensive ProGuard rules to ensure proper functionality:

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

# Split compatibility classes needed by Flutter
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.assetpacks.** { *; }

# Warning suppressions for missing classes
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
```

## Why This Works

### Google's Play Library Evolution
Google has split the monolithic Play Core library into several modular libraries:

1. **Play In-App Update**: For app update functionality
2. **Play In-App Review**: For app rating/review functionality
3. **Feature Delivery**: For on-demand modules and deferred components
4. **Asset Delivery**: For downloading large assets on demand

### Android 14 Compatibility
Android 14 introduced stricter requirements for broadcast receivers, which the old Play Core library didn't handle correctly. The new modular libraries are designed with Android 14 compatibility in mind.

### Flutter Requirements
Flutter's deferred components system depends on certain Play Core split compatibility classes. We've added the necessary libraries and ProGuard rules to ensure these dependencies are properly satisfied.

### Avoiding Duplicate Classes
By completely removing the original Play Core library and using only the modular components, we avoid duplicate class issues that would occur if both versions were included.

## Future Maintenance
The modular approach Google has taken with these libraries means:

1. Better compatibility with future Android versions
2. Smaller app size by only including what you need
3. Independent versioning of different Play features
4. Better maintainability as each library can be updated separately

This fix should ensure long-term compatibility with Android 14 and future Android versions. 