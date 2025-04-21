#!/bin/bash

# Exit on error
set -e

# Clean and build the app
echo "Cleaning previous builds..."
flutter clean

echo "Getting dependencies..."
flutter pub get

echo "Building release APK for GXIT..."
flutter build apk --release

echo "Building app bundle for Play Store..."
flutter build appbundle --release

echo "Build completed successfully!"
echo ""
echo "APK location: build/app/outputs/flutter-apk/app-release.apk"
echo "App Bundle location: build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "Manual upload instructions:"
echo "1. For Play Store: Upload the .aab file"
echo "2. For direct distribution: Use the .apk file" 