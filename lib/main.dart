import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'services/user_service.dart';
import 'services/app_startup_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// Initialize a global instance that can be accessed from anywhere
final appStartupService = AppStartupService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize app startup services
  await appStartupService.initialize();

  // Force dark status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const MainApp());
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
            future: userService.ensureUserExists(user),
            builder: (context, ensureSnapshot) {
              if (ensureSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // After ensuring the user exists in Firestore, show home screen
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
