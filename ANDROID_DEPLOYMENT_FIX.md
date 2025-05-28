# Android Deployment Issues & Fixes

## Google Play Store Upload Issue

### Problem
When attempting to upload the app bundle to Google Play Store, we encountered the following errors:

1. **Package Name Mismatch**: 
   - Error: "Your APK or Android App Bundle needs to have the package name com.gxit.app"
   - The app was using `com.gxit.gxit_2025` instead of the expected `com.gxit.app`

2. **Play Core Library Incompatibility**:
   - Error: "Your bundle targets SDK 34, but uses a Play Core library that cannot be used with that version"
   - The old Play Core library (1.10.3) is incompatible with Android 14 (SDK 34)
   - Warning about "backwards-incompatible change to broadcast receivers and may cause app crashes"

### Solution

We implemented the following fixes:

1. **Updated Application ID**:
   ```gradle
   defaultConfig {
       applicationId = "com.gxit.app"  // Changed from com.gxit.gxit_2025
   }
   ```

2. **Removed Problematic Play Core Dependencies**:
   - We completely removed the Play Core library dependencies that were causing conflicts
   - Disabled code minification temporarily to avoid class stripping issues:
   ```gradle
   buildTypes {
       release {
           minifyEnabled false
           shrinkResources false
       }
   }
   ```

3. **Added ProGuard Rules**:
   - Created rules to suppress warnings about missing Play Core classes:
   ```
   -dontwarn com.google.android.play.core.common.IntentSenderForResultStarter
   -dontwarn com.google.android.play.core.common.LocalTestingException
   -dontwarn com.google.android.play.core.common.PlayCoreDialogWrapperActivity
   -dontwarn com.google.android.play.core.listener.StateUpdatedListener
   -dontwarn com.google.android.play.core.tasks.OnFailureListener
   -dontwarn com.google.android.play.core.tasks.OnSuccessListener
   -dontwarn com.google.android.play.core.tasks.Task
   ```

## Restoring Play Core Functionality

If you need to restore Play Core functionality (for features like in-app updates, dynamic feature modules, or Play Store reviews), follow these steps:

### Option 1: Use Google Play Services (Recommended)

For apps targeting Android 14 (SDK 34):

1. Add these dependencies to `android/app/build.gradle`:
   ```gradle
   dependencies {
       // For in-app updates
       implementation 'com.google.android.play:app-update:2.1.0'
       
       // For dynamic feature modules
       implementation 'com.google.android.play:feature-delivery:2.1.0'
       
       // For Play Core tasks
       implementation 'com.google.android.gms:play-services-tasks:18.0.2'
       
       // For in-app reviews
       implementation 'com.google.android.play:review:2.0.1'
   }
   ```

2. Add exclusion for duplicate classes:
   ```gradle
   configurations.implementation {
       exclude group: 'com.google.android.play', module: 'core-common'
   }
   ```

3. Keep ProGuard rules in `android/app/proguard-rules.pro`:
   ```
   -keep class com.google.android.play.core.** { *; }
   -keep interface com.google.android.play.core.** { *; }
   ```

### Option 2: Re-enable Minification with ProGuard Rules

If you want to keep minification enabled (for smaller app size):

1. Modify `android/app/build.gradle`:
   ```gradle
   buildTypes {
       release {
           minifyEnabled true
           shrinkResources true
           proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
       }
   }
   ```

2. Ensure all necessary ProGuard rules are in `android/app/proguard-rules.pro`
   
3. Test thoroughly as this approach may still cause issues with some Play Core functionality

## Interactive Version Selection Script

We've also modified the release script to prompt for the version increment type interactively rather than requiring it as a command-line parameter. The relevant changes are in `scripts/release_android.sh`:

```bash
# If no argument provided, ask interactively
echo "Select version update type:"
echo "1) patch: Increases the third number (1.0.0 → 1.0.1)"
echo "2) minor: Increases the second number and resets patch (1.0.1 → 1.1.0)"
echo "3) major: Increases the first number and resets others (1.1.0 → 2.0.0)"
read -p "Enter your choice (1-3): " VERSION_CHOICE

case $VERSION_CHOICE in
  1) VERSION_TYPE="patch" ;;
  2) VERSION_TYPE="minor" ;;
  3) VERSION_TYPE="major" ;;
  *) echo "Invalid choice. Exiting."; exit 1 ;;
esac
```

## Other Notes

1. **App Bundle Location**: After a successful build, the app bundle is located at:
   ```
   build/app/outputs/bundle/release/app-release.aab
   ```

2. **Testing**: After implementing these changes, it's recommended to thoroughly test your app before releasing to production, especially if you need to use Play Core functionality.

3. **Future Updates**: Keep an eye on Google's Play Core library updates as they continue to improve compatibility with Android 14 and beyond. 