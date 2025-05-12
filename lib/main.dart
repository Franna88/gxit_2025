import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';
import 'firebase_options.dart';
import 'theme.dart';
import 'services/user_service.dart';
import 'services/app_startup_service.dart';
import 'services/lifecycle_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/self_description_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/wants_screen.dart';
import 'screens/needs_screen.dart';

// Initialize a global instance that can be accessed from anywhere
final appStartupService = AppStartupService();

// Initialize lifecycle service
late final LifecycleService lifecycleService;

// Add error handling for Flutter errors
void _handleFlutterError(FlutterErrorDetails details) {
  FlutterError.dumpErrorToConsole(details);
  // You could add custom error reporting here
  print('Flutter error: ${details.exception}');
  print('Stack trace: ${details.stack}');
}

Future<void> main() async {
  // Set up Flutter error handling
  FlutterError.onError = _handleFlutterError;

  // Catch any errors in the Zone
  runZonedGuarded(
    () async {
      // Initialize Flutter binding
      WidgetsFlutterBinding.ensureInitialized();

      try {
        // Apply system UI overlay styling
        if (Platform.isIOS) {
          // iOS-specific setup
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarBrightness:
                  Brightness.dark, // iOS: dark status bar (white content)
              statusBarIconBrightness:
                  Brightness.light, // Android: light icons for dark bg
            ),
          );
        } else {
          // Android/other platforms
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.black,
              statusBarIconBrightness:
                  Brightness.light, // dark icons for light bg
              systemNavigationBarIconBrightness: Brightness.light,
            ),
          );
        }

        // Initialize Firebase with error handling
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('Firebase initialized successfully');

        // Configure Firestore settings
        FirebaseFirestore.instance.settings = Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );

        // Test Firestore connection
        try {
          // This is a simple read operation to test if we have permissions
          await FirebaseFirestore.instance.collection('users').limit(1).get();
          print('Firestore connection test successful');
        } catch (e) {
          print('Firestore connection test failed: $e');
          // We'll continue anyway and handle errors at the app level
        }

        // Initialize app startup services with enhanced error handling
        try {
          await appStartupService.initialize();
          print('App startup services initialized');
        } catch (e) {
          print('Error initializing app startup services: $e');
          // We'll continue anyway to allow the app to at least start
        }

        // Setup lifecycle service
        lifecycleService = LifecycleService(
          onAppClosed: () {
            // Clean up resources when app is closed
            appStartupService.dispose();
          },
        );

        runApp(const MainApp());
      } catch (e, stackTrace) {
        print('Error during initialization: $e');
        print(stackTrace);
        // Run a simplified version of the app that displays the error
        runApp(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'App Initialization Error',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Error: $e',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          // Launch the app without Firebase initialization
                          runApp(
                            MaterialApp(
                              title: 'Social Buzz',
                              debugShowCheckedModeBanner: false,
                              theme: AppTheme.lightTheme,
                              darkTheme: AppTheme.darkTheme,
                              themeMode: ThemeMode.dark,
                              home: const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text('Continue without Firebase'),
                      ),
                    ],
                  ),
                ),
              ),
              backgroundColor: Colors.black,
            ),
            theme: ThemeData.dark(),
          ),
        );
      }
    },
    (error, stackTrace) {
      print('Uncaught error: $error');
      print(stackTrace);
      // You could add error reporting here
    },
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Buzz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: _handleAuthState(),
    );
  }

  // Check if user is already logged in and return appropriate screen
  Widget _handleAuthState() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If connection state is waiting, show loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in, go to home screen
        if (snapshot.hasData && snapshot.data != null) {
          // Ensure user exists in Firestore
          final user = snapshot.data!;
          final userService = UserService();

          // We use a FutureBuilder to handle the async operation
          return FutureBuilder(
            future: () async {
              try {
                await userService.ensureUserExists(user);
                
                // Check if user has completed all required steps
                final hasDescription = await userService.hasCompletedSelfDescription(user.uid);
                final hasPreferences = await userService.hasCompletedPreferences(user.uid);
                final hasWants = await userService.hasCompletedWants(user.uid);
                final hasNeeds = await userService.hasCompletedNeeds(user.uid);
                return {
                  'success': true,
                  'hasDescription': hasDescription,
                  'hasPreferences': hasPreferences,
                  'hasWants': hasWants,
                  'hasNeeds': hasNeeds,
                };
              } catch (e) {
                print('Error ensuring user exists: $e');
                return {'success': false};
              }
            }(),
            builder: (context, ensureSnapshot) {
              if (ensureSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Check if there was an error while ensuring user exists
              if (ensureSnapshot.hasError || 
                  ensureSnapshot.data == null || 
                  ensureSnapshot.data!['success'] == false) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Error loading user data',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          ensureSnapshot.hasError
                              ? 'Error: ${ensureSnapshot.error}'
                              : 'Failed to save user data',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            FirebaseAuth.instance.signOut();
                          },
                          child: const Text('Sign Out'),
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: () {
                            // Try to continue to home screen anyway
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );
                          },
                          child: const Text('Continue Anyway'),
                        ),
                      ],
                    ),
                  ),
                  backgroundColor: Colors.black,
                );
              }

              // Check if user needs to complete self-description
              if (ensureSnapshot.data!['hasDescription'] == false) {
                return SelfDescriptionScreen(userId: user.uid);
              }
              
              // Check if user needs to complete preferences
              if (ensureSnapshot.data!['hasPreferences'] == false) {
                return PreferencesScreen(userId: user.uid);
              }
              
              // Check if user needs to complete wants
              if (ensureSnapshot.data!['hasWants'] == false) {
                return WantsScreen(userId: user.uid);
              }
              
              // Check if user needs to complete needs
              if (ensureSnapshot.data!['hasNeeds'] == false) {
                return NeedsScreen(userId: user.uid);
              }

              // After ensuring the user has completed all steps, show home screen
              return const HomeScreen();
            },
          );
        }

        // Otherwise go to login screen
        return const LoginScreen();
      },
    );
  }
}
