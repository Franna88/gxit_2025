#!/bin/bash

# Script to prepare and build the GXIT app for TestFlight deployment

echo "=== GXIT TestFlight Build Script ==="
echo "This script will prepare and build the app for TestFlight deployment."

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "Error: This script must be run on macOS to build for iOS."
  exit 1
fi

# Check for required tools
if ! command -v flutter &> /dev/null; then
  echo "Error: Flutter is not installed or not in PATH."
  exit 1
fi

if ! command -v xcodebuild &> /dev/null; then
  echo "Error: Xcode command-line tools are not installed."
  exit 1
fi

# Clean and get dependencies
echo "Cleaning project and getting dependencies..."
flutter clean
flutter pub get

# Check for any analysis issues
echo "Running flutter analyze..."
flutter analyze
if [ $? -ne 0 ]; then
  echo "Warning: Flutter analysis found issues. Continue anyway? (y/n)"
  read -r response
  if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Build canceled."
    exit 1
  fi
fi

# Ensure we're using the latest version from pubspec.yaml
VERSION=$(grep -E "^version:" pubspec.yaml | awk '{print $2}' | tr -d "'")
echo "Building version: $VERSION"

# Build iOS
echo "Building for iOS..."
flutter build ios --release --no-codesign

# Remind user about Xcode steps
echo ""
echo "==== iOS Build Completed ===="
echo ""
echo "To finish the TestFlight deployment:"
echo "1. Open the iOS project in Xcode:"
echo "   open ios/Runner.xcworkspace"
echo ""
echo "2. In Xcode, select a real device or 'Any iOS Device (arm64)'"
echo "3. Select Product > Archive"
echo "4. When archiving completes, click 'Distribute App'"
echo "5. Choose 'App Store Connect' and follow the prompts"
echo ""
echo "After uploading to App Store Connect:"
echo "- Go to https://appstoreconnect.apple.com/"
echo "- Navigate to your app > TestFlight"
echo "- Wait for processing to complete (~15-30 minutes)"
echo "- Add test information and invite testers"
echo ""
echo "For more details, see the TESTFLIGHT_GUIDE.md file." 