import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_service.dart';
import 'popup_chat_service.dart';
import 'user_service.dart';

class AppStartupService {
  final ChatService _chatService = ChatService();
  final PopupChatService _popupChatService = PopupChatService();
  final UserService _userService = UserService();
  Timer? _cleanupTimer;
  Timer? _dailyPopupChatTimer;
  Timer? _popupChatCheckTimer;

  // Initialize core services that should run on app startup
  Future<void> initialize() async {
    // Ensure system bot exists
    await _userService.ensureSystemBotExists();

    // Set up chat room cleanup mechanism - runs on app startup and periodically
    setupChatRoomCleanup();

    // Check for daily popup chat room creation
    setupDailyPopupChat();

    // Check popup chat room states periodically
    setupPopupChatChecks();

    // Set up auth state handling
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // User signed in - set up user-specific services
        _refreshServices();
      } else {
        // User signed out - clear any user-specific timers/services
        _cleanupTimer?.cancel();
        _popupChatCheckTimer?.cancel();
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

  // Set up daily popup chat room creation
  void setupDailyPopupChat() async {
    // Check immediately when app starts
    await _popupChatService.checkAndCreateDailyRoom();

    // Schedule to check every 24 hours (at midnight)
    final now = DateTime.now();
    final midnight = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final initialDelay = midnight.difference(now);

    // First timer to run at next midnight
    Timer(initialDelay, () {
      // Create the first room at midnight
      _popupChatService.checkAndCreateDailyRoom();

      // Then schedule recurring daily checks
      _dailyPopupChatTimer = Timer.periodic(
        const Duration(hours: 24),
        (_) => _popupChatService.checkAndCreateDailyRoom(),
      );
    });
  }

  // Set up periodic popup chat room state checks
  void setupPopupChatChecks() {
    // Check immediately when app starts
    _popupChatService.checkAllPopupChatRooms();

    // Then check every 5 minutes
    _popupChatCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _popupChatService.checkAllPopupChatRooms(),
    );
  }

  // Refresh all services when user logs in
  void _refreshServices() {
    _cleanupTimer?.cancel();
    _popupChatCheckTimer?.cancel();
    setupChatRoomCleanup();
    setupPopupChatChecks();
  }

  // Dispose timers and services when app is closed
  void dispose() {
    _cleanupTimer?.cancel();
    _dailyPopupChatTimer?.cancel();
    _popupChatCheckTimer?.cancel();
  }
}
