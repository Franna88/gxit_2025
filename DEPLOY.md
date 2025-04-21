# Social Buzz App Deployment Guide

## Building the App

1. Make sure you have Flutter and Android SDK installed and configured
2. Run the build script:
   ```bash
   chmod +x distribute.sh
   ./distribute.sh
   ```
3. This will generate:
   - APK: `build/app/outputs/flutter-apk/app-release.apk`
   - App Bundle: `build/app/outputs/bundle/release/app-release.aab`

## Manual Distribution Options

### Option 1: Direct APK Distribution

1. Share the APK file with testers via:
   - Email attachment
   - File sharing service (Google Drive, Dropbox)
   - Internal app testing platform

2. Installation instructions for testers:
   - Download the APK file
   - Enable "Install from Unknown Sources" in Settings
   - Open the APK file to install

### Option 2: Google Play Internal Testing

1. Create a Google Play Developer account if you don't have one
2. Create a new app in the Google Play Console
3. Set up the app listing with required information:
   - App name: Social Buzz
   - Short description
   - Full description
   - Screenshots and graphics
   
4. Upload the App Bundle (.aab file) to the Internal Testing track
5. Add test users by email address
6. Create a release and roll it out to internal testing
7. Testers will receive an email with a link to join the testing program

### Option 3: Firebase App Distribution (Alternative)

If you decide to use Firebase App Distribution later:

1. Set up Firebase project and link to your app
2. Install Firebase CLI: `npm install -g firebase-tools`
3. Login to Firebase: `firebase login`
4. Add tester emails to `firebase-app-distribution.yaml`
5. Run the Firebase distribution command:
   ```
   firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
     --app YOUR_FIREBASE_APP_ID \
     --groups "internal-testers,beta-testers" \
     --release-notes-file ./firebase-app-distribution.yaml
   ```

## Generating a Keystore for Signing

For production releases, create a proper keystore:

```bash
keytool -genkey -v -keystore android/app/keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Then update the placeholder values in `android/app/build.gradle.kts` with your actual keystore details.

## Testing Requirements

Ask testers to provide the following information:
- Device model
- Android version
- Any crash reports or screenshots of issues
- Steps to reproduce bugs 