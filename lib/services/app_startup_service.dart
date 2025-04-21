import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_service.dart';

class AppStartupService {
  final ChatService _chatService = ChatService();
  Timer? _cleanupTimer;

  // Initialize core services that should run on app startup
  Future<void> initialize() async {
    // Set up chat room cleanup mechanism - runs on app startup and periodically
    setupChatRoomCleanup();

    // Set up auth state handling
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // User signed in - set up user-specific services
        _refreshChatRoomCleanup();
      } else {
        // User signed out - clear any user-specific timers/services
        _cleanupTimer?.cancel();
      }
    });
  }

  // Set up chat room cleanup mechanism
  void setupChatRoomCleanup() {
    // Run cleanup immediately when app starts
    _chatService.setupChatRoomCleanup();

    // Then schedule to run every 24 hours
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 24),
      (_) => _chatService.setupChatRoomCleanup(),
    );
  }

  // Refresh cleanup when user logs in
  void _refreshChatRoomCleanup() {
    _cleanupTimer?.cancel();
    setupChatRoomCleanup();
  }

  // Dispose timers and services when app is closed
  void dispose() {
    _cleanupTimer?.cancel();
  }
}
