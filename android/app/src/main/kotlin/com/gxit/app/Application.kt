package com.gxit.app

import android.app.Application
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.io.File

class Application : Application() {
    companion object {
        private const val TAG = "GXITApplication"
    }

    override fun onCreate() {
        super.onCreate()
        
        // Debug library paths - helps diagnose missing native libraries
        logNativeLibraryInfo()
    }
    
    /**
     * Logs information about native libraries to help diagnose loading issues
     */
    private fun logNativeLibraryInfo() {
        try {
            // Log device ABI info
            val deviceAbis = android.os.Build.SUPPORTED_ABIS
            Log.i(TAG, "Device supported ABIs: ${deviceAbis.joinToString()}")
            
            // Check app's native library directories
            val appLibDirs = applicationInfo.nativeLibraryDir
            Log.i(TAG, "App native library dir: $appLibDirs")
            
            // Check for Flutter library specifically
            val flutterLib = File(appLibDirs, "libflutter.so")
            Log.i(TAG, "libflutter.so exists: ${flutterLib.exists()}, size: ${if (flutterLib.exists()) flutterLib.length() else 0}")
            
            // List all .so files in the native library directory
            val libDir = File(appLibDirs)
            if (libDir.exists() && libDir.isDirectory) {
                val soFiles = libDir.listFiles { file -> file.name.endsWith(".so") }
                Log.i(TAG, "Found ${soFiles?.size ?: 0} .so files in $appLibDirs")
                soFiles?.forEach { file ->
                    Log.i(TAG, "  - ${file.name}: ${file.length()} bytes")
                }
            } else {
                Log.e(TAG, "Native library directory doesn't exist or isn't a directory: $appLibDirs")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking native libraries: ${e.message}", e)
        }
    }
} 