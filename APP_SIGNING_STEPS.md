# GXIT App Signing Steps

## Option 1: Using the Automated Script (Recommended)

Run the interactive script which will handle the entire process:

```bash
chmod +x generate_keystore.sh
./generate_keystore.sh
```

This script will:
1. Generate a keystore file
2. Create a key.properties file with your credentials
3. Move the keystore to the right location
4. Add the necessary entries to .gitignore for security

## Option 2: Manual Process

### Step 1: Generate the Upload Keystore

Run this command in your terminal:

```bash
keytool -genkey -v -keystore gxit_upload_key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storetype PKCS12
```

### Step 2: Move the Keystore to Your Project

```bash
mv gxit_upload_key.jks android/app/
```

### Step 3: Create key.properties File

Create a file at `android/key.properties` with the following content:

```
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=upload
storeFile=app/gxit_upload_key.jks
```

Replace `your-keystore-password` and `your-key-password` with the actual passwords you created.

### Step 4: Ensure .gitignore Contains Key Files

Add these entries to your `.gitignore` file:

```
# Keystore files
*.jks
*.keystore
android/key.properties
```

### Step 5: Build the App Bundle

```bash
flutter build appbundle
```

The app bundle will be created at: `build/app/outputs/bundle/release/app-release.aab`

### Step 6: Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app: GXIT
3. Go to Production > Create new release
4. Upload the `app-release.aab` file
5. Add release notes
6. Review and roll out to production

## Important Security Notes:

- Never commit your keystore or key.properties to source control
- Keep secure backups of your keystore file
- Remember your keystore password
- If you lose access to your upload key, you won't be able to update your app!

## Verifying Your Setup

Run this command to make sure your Firebase config matches your app:

```bash
./verify_firebase.sh
``` 