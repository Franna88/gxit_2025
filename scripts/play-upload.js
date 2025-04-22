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
  console.error(`File not found: ${aabPath}`);
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
  console.error(`Service account file not found: ${serviceAccountPath}`);
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
    
    console.log(`Release added to ${track.data.track} track.`);
    
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
