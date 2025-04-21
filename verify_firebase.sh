#!/bin/bash

# Exit on error
set -e

echo "GXIT Firebase Configuration Verifier"
echo "-----------------------------------"
echo ""

# Check for google-services.json
GOOGLE_SERVICES_FILE="android/app/google-services.json"

if [ ! -f "$GOOGLE_SERVICES_FILE" ]; then
    echo "Error: google-services.json not found at $GOOGLE_SERVICES_FILE"
    echo "Please download it from Firebase Console and place it in the android/app directory."
    exit 1
fi

# Extract app ID and package name
echo "Checking Firebase configuration..."
APP_ID=$(grep -o '"mobilesdk_app_id": "[^"]*"' $GOOGLE_SERVICES_FILE | cut -d'"' -f4)
PACKAGE_NAME=$(grep -o '"package_name": "[^"]*"' $GOOGLE_SERVICES_FILE | cut -d'"' -f4)

echo "Found Firebase configuration:"
echo "- App ID: $APP_ID"
echo "- Package Name: $PACKAGE_NAME"
echo ""

# Check if package name matches
EXPECTED_PACKAGE="com.example.gxit_2025"
if [ "$PACKAGE_NAME" != "$EXPECTED_PACKAGE" ]; then
    echo "Warning: Package name mismatch!"
    echo "Expected: $EXPECTED_PACKAGE"
    echo "Found: $PACKAGE_NAME"
    echo ""
    echo "This might cause Firebase services to fail."
    echo "Please make sure your package name in build.gradle.kts matches the Firebase configuration."
else
    echo "✓ Package name matches expected value."
fi

# Check app ID
EXPECTED_APP_ID="1:354097109879:android:925191fa8627a44f4bdf72"
if [ "$APP_ID" != "$EXPECTED_APP_ID" ]; then
    echo "Warning: App ID mismatch!"
    echo "Expected: $EXPECTED_APP_ID"
    echo "Found: $APP_ID"
    echo ""
    echo "This might cause Firebase services to fail."
else
    echo "✓ App ID matches expected value."
fi

echo ""
echo "Verification complete." 