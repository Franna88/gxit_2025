#!/bin/bash

# Exit on error
set -e

echo "GXIT App Keystore Generator"
echo "---------------------------"
echo ""

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "Error: 'keytool' command not found!"
    echo "Please install Java JDK or add it to your PATH."
    exit 1
fi

# Default keystore file name
KEYSTORE_FILE="gxit_upload_key.jks"

# Check if keystore already exists
if [ -f "$KEYSTORE_FILE" ]; then
    echo "Warning: Keystore file '$KEYSTORE_FILE' already exists!"
    read -p "Do you want to overwrite it? (y/n): " OVERWRITE
    if [ "$OVERWRITE" != "y" ]; then
        echo "Aborted. Exiting without creating a new keystore."
        exit 0
    fi
fi

# Generate keystore
echo ""
echo "Generating keystore file: $KEYSTORE_FILE"
echo "You will be prompted to enter information for your keystore."
echo "Please remember the passwords you enter!"
echo ""

keytool -genkey -v -keystore "$KEYSTORE_FILE" -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storetype PKCS12

# Prompt for passwords to create key.properties file
echo ""
read -p "Enter the keystore password you used (for key.properties): " KEYSTORE_PASSWORD
read -p "Enter the key password you used (for key.properties): " KEY_PASSWORD

# Check if successful
if [ $? -eq 0 ]; then
    echo ""
    echo "Keystore generated successfully!"
    echo ""
    
    # Ask if user wants to move the keystore
    read -p "Do you want to move the keystore to the Android app directory? (y/n): " MOVE
    if [ "$MOVE" == "y" ]; then
        # Create directory if it doesn't exist
        mkdir -p android/app
        
        # Move the file
        mv "$KEYSTORE_FILE" android/app/
        
        # Create key.properties file
        echo "Creating key.properties file..."
        cat > android/key.properties << EOL
storePassword=$KEYSTORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=upload
storeFile=app/gxit_upload_key.jks
EOL
        
        echo "Keystore moved to android/app/$KEYSTORE_FILE"
        echo "key.properties created at android/key.properties"
        echo ""
        echo "Your app is now configured for signing with the keystore."
    else
        echo "Keystore remains at: $(pwd)/$KEYSTORE_FILE"
        echo ""
        echo "Don't forget to:"
        echo "1. Move the keystore file to android/app/ directory"
        echo "2. Create android/key.properties with your keystore information"
    fi
    
    echo ""
    echo "IMPORTANT: Store your keystore password in a safe place!"
    echo "If you lose it, you will not be able to update your app in the future."
else
    echo "Error: Failed to generate keystore."
    exit 1
fi

# Add key.properties to .gitignore if it exists
GITIGNORE_FILE=".gitignore"
if [ -f "$GITIGNORE_FILE" ]; then
    if ! grep -q "key.properties" "$GITIGNORE_FILE"; then
        echo "" >> "$GITIGNORE_FILE"
        echo "# Keystore files" >> "$GITIGNORE_FILE"
        echo "*.jks" >> "$GITIGNORE_FILE"
        echo "*.keystore" >> "$GITIGNORE_FILE"
        echo "android/key.properties" >> "$GITIGNORE_FILE"
        echo "Added keystore files to .gitignore for security"
    fi
fi

echo ""
echo "App signing setup complete!" 