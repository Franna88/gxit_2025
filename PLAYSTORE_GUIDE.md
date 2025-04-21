# GXIT App - Google Play Store Submission Guide

## App Signing Process

### 1. Generate an Upload Key

The upload key is used to sign your app for Google Play. This is different from the app signing key that Google Play will use.

```bash
keytool -genkey -v -keystore gxit_upload_key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storetype PKCS12
```

When prompted:
- Enter and remember a strong password
- Fill in the certificate information
- For "Is CN=Your Name, OU=Your Organizational Unit correct?" type "yes"

The keystore file `gxit_upload_key.jks` will be created in your current directory.

### 2. Move the Keystore File

Move the keystore file to the app module directory:

```bash
# From project root
mv gxit_upload_key.jks android/app/
```

### 3. Configure App Signing

Edit the `android/app/build.gradle.kts` file to use your keystore:

```kotlin
signingConfigs {
    create("release") {
        storeFile = file("gxit_upload_key.jks")
        storePassword = "YOUR_KEYSTORE_PASSWORD"
        keyAlias = "upload"
        keyPassword = "YOUR_KEY_PASSWORD"
    }
}
```

For security, you can use environment variables instead of hardcoding passwords:

```kotlin
signingConfigs {
    create("release") {
        storeFile = file("gxit_upload_key.jks")
        storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "YOUR_KEYSTORE_PASSWORD"
        keyAlias = "upload"
        keyPassword = System.getenv("KEY_PASSWORD") ?: "YOUR_KEY_PASSWORD"
    }
}
```

### 4. Build the Release AAB

```bash
flutter build appbundle
```

The app bundle will be created at:
`build/app/outputs/bundle/release/app-release.aab`

## Google Play Store Submission

### 1. Create a Google Play Developer Account

- Visit the [Google Play Console](https://play.google.com/console/signup)
- Pay the one-time $25 USD registration fee
- Complete your account details

### 2. Create a New App

1. In Google Play Console, click "Create app"
2. Fill in the app details:
   - App name: GXIT
   - Default language: English (or your preferred language)
   - App or Game: App
   - Free or Paid: Choose appropriate option
   - Declarations: Check all required boxes

### 3. Complete Store Listing

Navigate to "Store presence" > "Store listing" and complete:

- Short description (up to 80 characters)
- Full description (up to 4000 characters)
- App icon (512x512 PNG)
- Feature graphic (1024x500 JPG or PNG)
- Phone screenshots (minimum 2)
- Categorize your app

### 4. App Content Rating

Complete the content rating questionnaire to get an official content rating.

### 5. App Pricing and Distribution

Specify:
- Whether your app is free or paid
- Countries where your app will be available
- User age groups your app targets

### 6. Set Up App Release

1. Go to "Production" > "Create new release"
2. Upload your AAB file
3. Add release notes
4. Review the release and submit for review

### 7. Firebase Configuration

Ensure your app has the correct Firebase configuration matching your Play Store app:

- App ID: `1:354097109879:android:925191fa8627a44f4bdf72`
- Package name: `com.example.gxit_2025`

## App Signing by Google Play

### Enable Play App Signing

Google Play App Signing is recommended for additional security. To enable it:

1. During your first app release, select "Continue and use Play App Signing"
2. Upload your app signing key, or let Google generate one for you
3. Complete the process to enable app signing by Google

### Benefits of Play App Signing

- Secures your app signing key with Google's infrastructure
- Enables smaller app update packages
- Allows for key rotation if your upload key is compromised

## Important Final Checks

Before submission:

1. Test your signed APK on multiple devices
2. Ensure Firebase services work correctly
3. Verify your app meets [Google Play policies](https://play.google.com/about/developer-content-policy/)
4. Check that privacy policy and terms of service are accessible

## Additional Resources

- [Google Play Console Help](https://support.google.com/googleplay/android-developer/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Deployment Documentation](https://flutter.dev/docs/deployment/android) 