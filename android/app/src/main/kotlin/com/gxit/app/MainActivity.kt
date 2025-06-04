package com.gxit.app

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class MainActivity: FlutterActivity() {
    companion object {
        private const val TAG = "GXITMainActivity"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        // IMPORTANT: We need to ensure Flutter libraries are loaded before super.onCreate()
        // which triggers Flutter initialization
        ensureFlutterLibraryIsLoaded()
        
        // Now call super.onCreate() after libraries are loaded
        super.onCreate(savedInstanceState)
    }
    
    private fun ensureFlutterLibraryIsLoaded() {
        try {
            // Method 1: Standard library loading
            Log.i(TAG, "Attempting to load libflutter.so using System.loadLibrary")
            System.loadLibrary("flutter")
            Log.i(TAG, "Successfully loaded libflutter.so")
            return
        } catch (e: UnsatisfiedLinkError) {
            Log.e(TAG, "Failed to load libflutter.so via System.loadLibrary: ${e.message}", e)
        }
        
        try {
            // Method 2: Full path loading
            val fullPath = File(applicationInfo.nativeLibraryDir, "libflutter.so")
            Log.i(TAG, "Attempting to load from full path: ${fullPath.absolutePath}")
            if (fullPath.exists()) {
                System.load(fullPath.absolutePath)
                Log.i(TAG, "Successfully loaded libflutter.so from full path")
                return
            } else {
                Log.e(TAG, "Library file does not exist at: ${fullPath.absolutePath}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load libflutter.so from full path: ${e.message}", e)
        }
        
        // Method 3: List all libraries to see what's available
        try {
            val nativeDir = File(applicationInfo.nativeLibraryDir)
            Log.i(TAG, "Native library directory: ${nativeDir.absolutePath}")
            if (nativeDir.exists() && nativeDir.isDirectory) {
                val files = nativeDir.listFiles() ?: emptyArray()
                Log.i(TAG, "Found ${files.size} files in native directory:")
                files.forEach { file ->
                    Log.i(TAG, "  - ${file.name}: ${file.length()} bytes")
                }
            } else {
                Log.e(TAG, "Native library directory doesn't exist or is not a directory")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to list native libraries: ${e.message}", e)
        }
        
        // Method 4: Check APK for the library
        try {
            Log.i(TAG, "Checking APK for libflutter.so")
            val packageManager = applicationContext.packageManager
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            val sourceDir = appInfo.sourceDir
            Log.i(TAG, "APK path: $sourceDir")
            
            // List the contents of the APK
            val process = Runtime.getRuntime().exec("unzip -l $sourceDir | grep libflutter.so")
            val output = process.inputStream.bufferedReader().use { it.readText() }
            Log.i(TAG, "libflutter.so in APK: $output")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check APK for libflutter.so: ${e.message}", e)
        }
        
        // Log device information to help with debugging
        Log.i(TAG, "Device ABIs: ${android.os.Build.SUPPORTED_ABIS.joinToString()}")
        Log.i(TAG, "Device: ${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL}")
        Log.i(TAG, "Android version: ${android.os.Build.VERSION.RELEASE} (SDK ${android.os.Build.VERSION.SDK_INT})")
        
        Log.e(TAG, "All attempts to load libflutter.so failed")
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        try {
            GeneratedPluginRegistrant.registerWith(flutterEngine)
            Log.i(TAG, "Flutter engine configured successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error configuring Flutter engine: ${e.message}", e)
        }
    }
} 