#!/bin/bash

# Exit on any error
set -e

# Function to display usage
usage() {
  echo "Usage: $0 [patch|minor|major]"
  echo "  patch: Increases the third number (1.0.0 → 1.0.1)"
  echo "  minor: Increases the second number and resets patch (1.0.1 → 1.1.0)"
  echo "  major: Increases the first number and resets others (1.1.0 → 2.0.0)"
  echo ""
  echo "If no argument is provided, you will be prompted to select a version type."
}

# Check for version type argument
if [ $# -eq 1 ]; then
  VERSION_TYPE=$1
  
  if [ "$VERSION_TYPE" != "patch" ] && [ "$VERSION_TYPE" != "minor" ] && [ "$VERSION_TYPE" != "major" ]; then
    usage
    exit 1
  fi
else
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
  
  echo "Selected: $VERSION_TYPE"
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Make sure we're in the project root directory
cd "$PROJECT_DIR"

echo "Starting Android release process with $VERSION_TYPE version increment..."

# Get current version from pubspec.yaml
VERSION_LINE=$(grep 'version:' pubspec.yaml | sed 's/version: //')
CURRENT_VERSION=$(echo "$VERSION_LINE" | cut -d'+' -f1)
CURRENT_BUILD_NUMBER=$(echo "$VERSION_LINE" | cut -d'+' -f2)

echo "Current version: $CURRENT_VERSION+$CURRENT_BUILD_NUMBER"

# Increment according to type
if [ "$VERSION_TYPE" == "patch" ]; then
  MAJOR=$(echo $CURRENT_VERSION | cut -d. -f1)
  MINOR=$(echo $CURRENT_VERSION | cut -d. -f2)
  PATCH=$(echo $CURRENT_VERSION | cut -d. -f3)
  NEW_PATCH=$((PATCH + 1))
  NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"
elif [ "$VERSION_TYPE" == "minor" ]; then
  MAJOR=$(echo $CURRENT_VERSION | cut -d. -f1)
  MINOR=$(echo $CURRENT_VERSION | cut -d. -f2)
  NEW_MINOR=$((MINOR + 1))
  NEW_VERSION="$MAJOR.$NEW_MINOR.0"
elif [ "$VERSION_TYPE" == "major" ]; then
  MAJOR=$(echo $CURRENT_VERSION | cut -d. -f1)
  NEW_MAJOR=$((MAJOR + 1))
  NEW_VERSION="$NEW_MAJOR.0.0"
fi

# Increment build number - ensure it's an integer for Google Play
if [[ "$CURRENT_BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  # If it's already a number, increment it
  NEW_BUILD_NUMBER=$((CURRENT_BUILD_NUMBER + 1))
else
  # If it's not a valid number (or contains periods), start with a new number
  # We'll use the timestamp to ensure it's unique and increasing
  NEW_BUILD_NUMBER=$(date +%s)
  echo "Warning: Build number was not a valid integer. Using timestamp-based build number: $NEW_BUILD_NUMBER"
fi

echo "New version: $NEW_VERSION+$NEW_BUILD_NUMBER"

# Update pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS requires a different sed syntax
  sed -i '' "s/version: $CURRENT_VERSION+$CURRENT_BUILD_NUMBER/version: $NEW_VERSION+$NEW_BUILD_NUMBER/" pubspec.yaml
else
  sed -i "s/version: $CURRENT_VERSION+$CURRENT_BUILD_NUMBER/version: $NEW_VERSION+$NEW_BUILD_NUMBER/" pubspec.yaml
fi

# Check if key.properties exists
if [ ! -f "android/key.properties" ]; then
  echo "Warning: android/key.properties not found. You'll need this for app signing."
  read -p "Do you want to create android/key.properties now? (y/n): " CREATE_KEY_PROPERTIES
  
  if [ "$CREATE_KEY_PROPERTIES" == "y" ] || [ "$CREATE_KEY_PROPERTIES" == "Y" ]; then
    mkdir -p android
    
    read -p "Enter the path to your keystore file: " KEYSTORE_PATH
    read -p "Enter the keystore password: " KEYSTORE_PASSWORD
    read -p "Enter the key alias: " KEY_ALIAS
    read -p "Enter the key password: " KEY_PASSWORD
    
    cat > android/key.properties << EOF
storePassword=$KEYSTORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=$KEYSTORE_PATH
EOF
    
    echo "android/key.properties created successfully."
  else
    echo "Continuing without creating android/key.properties. You'll need to create it manually before release."
  fi
fi

# Setup distribution directories
if [ ! -d "distribution" ]; then
  mkdir -p distribution/whatsnew
  
  # Create empty release notes file if it doesn't exist
  if [ ! -f "distribution/whatsnew/en-US.txt" ]; then
    touch distribution/whatsnew/en-US.txt
  fi
  
  echo "Created distribution directory structure."
fi

# Ask about updating release notes
read -p "Do you want to update the release notes? (y/n): " UPDATE_NOTES

if [ "$UPDATE_NOTES" == "y" ] || [ "$UPDATE_NOTES" == "Y" ]; then
  if [ ! -d "distribution/whatsnew" ]; then
    mkdir -p distribution/whatsnew
  fi
  
  # Open release notes in default editor
  if [[ "$OSTYPE" == "darwin"* ]]; then
    open -t distribution/whatsnew/en-US.txt
  else
    if [ -n "$EDITOR" ]; then
      $EDITOR distribution/whatsnew/en-US.txt
    else
      nano distribution/whatsnew/en-US.txt
    fi
  fi
  
  echo "Press Enter when you've finished updating the release notes."
  read
fi

# Get Flutter dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Run tests if available
read -p "Do you want to run tests before building? (y/n): " RUN_TESTS

if [ "$RUN_TESTS" == "y" ] || [ "$RUN_TESTS" == "Y" ]; then
  echo "Running Flutter tests..."
  flutter test
fi

# Build the Android App Bundle
echo "Building App Bundle..."
flutter build appbundle --release

AAB_PATH="$PROJECT_DIR/build/app/outputs/bundle/release/app-release.aab"
echo "App Bundle built successfully at $AAB_PATH"

# Create service account setup script if it doesn't exist
UPLOAD_SCRIPT_PATH="$SCRIPT_DIR/play-upload.js"
if [ ! -f "$UPLOAD_SCRIPT_PATH" ]; then
  cat > "$UPLOAD_SCRIPT_PATH" << EOF
const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

// Get the aab file path from the command line argument
const aabPath = process.argv[2];
if (!aabPath) {
  console.error('Please provide the path to the .aab file as an argument');
  process.exit(1);
}

// Check if the file exists
if (!fs.existsSync(aabPath)) {
  console.error(\`File not found: \${aabPath}\`);
  process.exit(1);
}

// Get the service account file path from environment variable
const serviceAccountPath = process.env.PLAY_STORE_SERVICE_ACCOUNT_PATH;
if (!serviceAccountPath) {
  console.error('PLAY_STORE_SERVICE_ACCOUNT_PATH environment variable not set');
  process.exit(1);
}

// Check if the service account file exists
if (!fs.existsSync(serviceAccountPath)) {
  console.error(\`Service account file not found: \${serviceAccountPath}\`);
  process.exit(1);
}

async function uploadToPlayStore() {
  try {
    console.log('Starting upload to Google Play Store...');
    
    // Create a JWT auth client
    const auth = new google.auth.GoogleAuth({
      keyFile: serviceAccountPath,
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });
    
    const client = await auth.getClient();
    
    // Get package name from pubspec.yaml or other configuration
    // For this script, we'll prompt for it
    const packageName = process.env.PACKAGE_NAME;
    if (!packageName) {
      console.error('PACKAGE_NAME environment variable not set');
      process.exit(1);
    }
    
    // Initialize the androidpublisher API
    const androidpublisher = google.androidpublisher({
      version: 'v3',
      auth: client,
    });
    
    // Create an edit
    const edit = await androidpublisher.edits.insert({
      packageName: packageName,
    });
    
    const editId = edit.data.id;
    
    // Read the AAB file
    const appBundle = fs.readFileSync(aabPath);
    
    // Upload the AAB
    const bundle = await androidpublisher.edits.bundles.upload({
      packageName: packageName,
      editId: editId,
      media: {
        mimeType: 'application/octet-stream',
        body: appBundle,
      },
    });
    
    console.log('App bundle uploaded successfully!');
    
    // Track release - using internal track for safety
    const track = await androidpublisher.edits.tracks.update({
      packageName: packageName,
      editId: editId,
      track: 'internal', // Can be 'internal', 'alpha', 'beta', or 'production'
      requestBody: {
        releases: [
          {
            versionCodes: [bundle.data.versionCode],
            status: 'completed',
          },
        ],
      },
    });
    
    console.log(\`Release added to \${track.data.track} track.\`);
    
    // Check if release notes directory exists
    const releaseNotesPath = path.join(process.env.PROJECT_DIR, 'distribution/whatsnew/en-US.txt');
    if (fs.existsSync(releaseNotesPath)) {
      // Add release notes
      await androidpublisher.edits.deobfuscationfiles.upload({
        packageName: packageName,
        editId: editId,
        apkVersionCode: bundle.data.versionCode,
        deobfuscationFileType: 'releaseNotes',
        language: 'en-US',
        media: {
          mimeType: 'text/plain',
          body: fs.createReadStream(releaseNotesPath),
        },
      });
      
      console.log('Release notes uploaded successfully!');
    }
    
    // Commit the edit
    await androidpublisher.edits.commit({
      packageName: packageName,
      editId: editId,
    });
    
    console.log('Edit committed successfully!');
    console.log('App has been successfully uploaded to the Google Play Store!');
    
  } catch (error) {
    console.error('Error uploading to Play Store:', error.message);
    if (error.response) {
      console.error('Response data:', error.response.data);
    }
    process.exit(1);
  }
}

uploadToPlayStore();
EOF

  echo "Created Play Store upload script at $UPLOAD_SCRIPT_PATH"
fi

# Create package.json for the script if it doesn't exist
if [ ! -f "$SCRIPT_DIR/package.json" ]; then
  cat > "$SCRIPT_DIR/package.json" << EOF
{
  "name": "play-store-upload",
  "version": "1.0.0",
  "description": "Upload APK/AAB to Google Play Store",
  "main": "play-upload.js",
  "dependencies": {
    "googleapis": "^92.0.0"
  }
}
EOF

  echo "Created package.json for the upload script"
fi

# Ask if user wants to upload to Play Store
read -p "Do you want to upload to Play Store? (y/n): " UPLOAD_TO_PLAY_STORE

if [ "$UPLOAD_TO_PLAY_STORE" == "y" ] || [ "$UPLOAD_TO_PLAY_STORE" == "Y" ]; then
  # Check if Node.js is installed
  if ! command -v node &> /dev/null; then
    echo "Node.js is required for uploading to Play Store but is not installed."
    echo "Please install Node.js and try again, or upload manually through the Play Console."
    echo "https://nodejs.org/en/download/"
  else
    # Check if service account file exists
    SERVICE_ACCOUNT_PATH="$SCRIPT_DIR/service-account.json"
    if [ ! -f "$SERVICE_ACCOUNT_PATH" ]; then
      echo "Service account file not found at $SERVICE_ACCOUNT_PATH"
      read -p "Enter the path to your service account JSON file: " CUSTOM_SA_PATH
      export PLAY_STORE_SERVICE_ACCOUNT_PATH="$CUSTOM_SA_PATH"
    else
      export PLAY_STORE_SERVICE_ACCOUNT_PATH="$SERVICE_ACCOUNT_PATH"
    fi
    
    # Ask for package name
    read -p "Enter your app's package name (e.g. com.example.myapp): " PACKAGE_NAME
    export PACKAGE_NAME="$PACKAGE_NAME"
    export PROJECT_DIR="$PROJECT_DIR"
    
    # Check if the node modules are installed
    if [ ! -d "$SCRIPT_DIR/node_modules" ]; then
      echo "Installing dependencies for upload script..."
      (cd "$SCRIPT_DIR" && npm install)
    fi
    
    # Run the upload script
    echo "Uploading to Google Play Store..."
    (cd "$SCRIPT_DIR" && node play-upload.js "$AAB_PATH")
  fi
fi

# Commit the version change
read -p "Do you want to commit the version change? (y/n): " COMMIT_VERSION

if [ "$COMMIT_VERSION" == "y" ] || [ "$COMMIT_VERSION" == "Y" ]; then
  git add pubspec.yaml
  if [ "$UPDATE_NOTES" == "y" ] || [ "$UPDATE_NOTES" == "Y" ]; then
    git add distribution/whatsnew/en-US.txt
  fi
  
  git commit -m "Bump version to $NEW_VERSION+$NEW_BUILD_NUMBER"
  
  read -p "Do you want to tag this release? (y/n): " TAG_RELEASE
  
  if [ "$TAG_RELEASE" == "y" ] || [ "$TAG_RELEASE" == "Y" ]; then
    git tag -a "v$NEW_VERSION" -m "Version $NEW_VERSION"
    echo "Created tag v$NEW_VERSION"
  fi
  
  read -p "Do you want to push the commit and tag? (y/n): " PUSH_COMMIT
  
  if [ "$PUSH_COMMIT" == "y" ] || [ "$PUSH_COMMIT" == "Y" ]; then
    if [ "$TAG_RELEASE" == "y" ] || [ "$TAG_RELEASE" == "Y" ]; then
      git push && git push --tags
    else
      git push
    fi
  fi
fi

echo "Android release process completed!"
echo "App Bundle is available at: $AAB_PATH" 