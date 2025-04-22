# TestFlight Deployment Guide for GXIT

This guide outlines the steps needed to deploy the GXIT app to TestFlight for iOS testing.

## Prerequisites

1. Make sure you have:
   - An Apple Developer account
   - Xcode installed on your Mac
   - A valid Apple Developer certificate
   - Access to App Store Connect

## Preparing the App

1. Verify that the bundle identifier is properly set:
   - Changed from `com.example.gxit2025` to `com.gxit.app` in:
     - iOS/Runner.xcodeproj/project.pbxproj
     - iOS/Runner/GoogleService-Info.plist

2. Verify app version:
   - The marketing version is set to 1.2.4 (matching pubspec.yaml)
   - The build number is 7 (from pubspec.yaml's `version: 1.2.4+7`)

3. Required iOS permissions have been added:
   - NSContactsUsageDescription
   - NSLocationWhenInUseUsageDescription
   - NSLocationAlwaysAndWhenInUseUsageDescription

## Building for TestFlight

1. Open the project in Xcode:
   ```
   cd ios
   open Runner.xcworkspace
   ```

2. Select the "Runner" project in the project navigator.

3. In the "General" tab, ensure:
   - The correct Bundle Identifier is set (com.gxit.app)
   - The Version is set (1.2.4)
   - The Build is set (7)
   - A valid provisioning profile is selected

4. In the "Signing & Capabilities" tab:
   - Ensure "Automatically manage signing" is checked
   - Select your Team from the dropdown

5. Archive the build:
   - Select a real iOS device or "Any iOS Device (arm64)" as the build target
   - Select Product > Archive from the menu

6. Once the archive is complete, the Organizer window will open:
   - Click "Distribute App"
   - Select "App Store Connect"
   - Follow the prompts to upload your build

## Distributing via TestFlight

1. After uploading, go to [App Store Connect](https://appstoreconnect.apple.com/).

2. Navigate to your app > TestFlight.

3. Wait for the build to finish processing (can take 15-30 minutes).

4. Once processing is complete:
   - Add test information (what to test, notes)
   - Add external testers or testing groups

5. External testers will receive an email invitation to test the app.

## Common Issues

1. **Missing Permissions**: Ensure all permission descriptions are present in Info.plist.

2. **Firestore Configuration**: If Firebase/Firestore isn't working, verify the GoogleService-Info.plist has the correct bundle ID.

3. **Signing Issues**: Try:
   - Xcode > Clean Build Folder
   - Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
   - Check your certificate is valid

4. **Rejected by App Store**: Common reasons include:
   - Using example/test bundle identifiers (com.example.*)
   - Missing privacy permissions
   - Crashes during App Store review

## Resources

- [TestFlight Overview](https://developer.apple.com/testflight/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios) 