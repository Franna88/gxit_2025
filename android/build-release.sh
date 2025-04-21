#!/bin/bash

# Exit on error
set -e

echo "Cleaning previous builds..."
./gradlew clean

echo "Building release App Bundle for Play Store..."
./gradlew bundleRelease

echo "Building signed APK..."
./gradlew assembleRelease

echo "Build completed!"
echo "APKs can be found in app/build/outputs/apk/release/"
echo "App Bundle can be found in app/build/outputs/bundle/release/" 