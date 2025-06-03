# Android Configuration Fix

## Changes Made Based on Elmos Furniture Project

We've updated the Android configuration files to match a working project (Elmos Furniture), which has successfully been deployed to the Google Play Store with Android 14 (SDK 34) compatibility.

### 1. Updated build.gradle:
- Set `compileSdk` to 35 (latest available)
- Set `targetSdk` to 34 (Android 14)
- Added `multiDexEnabled = true` for handling large app sizes
- Removed all Play Core libraries which were causing compatibility issues
- Added proper multidex support

```gradle
dependencies {
    // Use AndroidX libraries
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.core:core:1.12.0'
    
    // Multidex support
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

### 2. Updated ProGuard Rules:
- Simplified to only include essential rules based on the working project
- Removed all Play Core specific rules that were causing conflicts
- Kept basic Flutter, Firebase, and serialization rules

```proguard
# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep all native methods
-keepclasseswithmembers class * {
    native <methods>;
}

# Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Serializable
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <fields>;
    !private <methods>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
```

### 3. Updated gradle.properties:
- Simplified to only include essential properties
- Increased memory allocation for Gradle to handle larger builds
- Removed unnecessary properties that could potentially cause conflicts

```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true
```

## Why This Works

The Elmos Furniture project has a simpler and more standard Android configuration that avoids many common pitfalls:

1. It doesn't rely on the deprecated Play Core library, which has compatibility issues with Android 14
2. It uses multidex support for handling large apps
3. It has simplified ProGuard rules that don't interfere with Android 14's stricter requirements
4. It uses a clean gradle.properties file with only essential configurations

This approach aligns with Google's recommended practices for Android 14 compatibility and should resolve the issues with the app crashing on startup in the Google Play Store. 