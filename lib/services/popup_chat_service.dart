import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/popup_chat_room.dart';
import '../models/notification_model.dart';
import 'user_service.dart';

class PopupChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final Random _random = Random();

  // Collection references
  CollectionReference get _popupRoomsCollection =>
      _firestore.collection('popupChatRooms');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // System bot ID - could be stored in environment or Firestore settings
  static const String systemBotId = 'system_bot';

  // Sample chat topics by category
  static const Map<String, List<String>> chatTopics = {
    'Technology': [
      'The Future of AI: Friend or Foe?',
      'Are Cryptocurrencies Going to Replace Traditional Banking?',
      'The Metaverse: Next Big Thing or Just Hype?',
      'Should Social Media Be Regulated?',
      'Are Smartphones Making Us Less Social?',
    ],
    'Entertainment': [
      'The Best Movie of All Time - Defend Your Choice',
      'Is Streaming Killing Traditional TV?',
      'Are Remakes and Sequels Ruining Cinema?',
      'The Most Overrated Celebrity - Who and Why?',
      'Is Reality TV Authentic or Completely Scripted?',
    ],
    'Society': [
      'Is Working From Home the Future?',
      'Should University Education Be Free?',
      'The Perfect Age Gap in Relationships: Does It Exist?',
      'Is Marriage Still Relevant in Today\'s Society?',
      'Social Media: Net Positive or Negative for Society?',
    ],
    'Philosophy': [
      'Does Free Will Actually Exist?',
      'Is Human Nature Fundamentally Good or Evil?',
      'If You Could Live Forever, Would You?',
      'Is Ignorance Really Bliss?',
      'What Defines Success? Money, Happiness, or Something Else?',
    ],
    'Controversial': [
      'Pineapple on Pizza: Delicious or Disgraceful?',
      'Does the Toilet Paper Go Over or Under the Roll?',
      'Is a Hot Dog a Sandwich?',
      'Cats vs. Dogs: Which Makes the Better Pet?',
      'Should Breaking Up by Text Be Socially Acceptable?',
    ],
  };

  // Get popup chat room as stream
  Stream<PopupChatRoom?> getPopupChatRoomStream(String roomId) {
    return _popupRoomsCollection.doc(roomId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return PopupChatRoom.fromFirestore(snapshot);
      }
      return null;
    });
  }

  // Get all scheduled popup chat rooms
  Stream<List<PopupChatRoom>> getScheduledPopupChatRoomsStream() {
    try {
      final now = DateTime.now();
      
      // First try to ensure the system bot exists
      _userService.ensureSystemBotExists();
      
      // Create a safeguarded stream with error handling
      return _popupRoomsCollection
          .where('scheduledTime', isGreaterThan: Timestamp.fromDate(now))
          .where(
            'status',
            isEqualTo: PopupChatRoom.statusToString(PopupChatStatus.scheduled),
          )
          .orderBy('scheduledTime')
          .snapshots()
          .handleError((error) {
            print('Error fetching scheduled popup chats: $error');
            // Return an empty list instead of propagating the error
            return [];
          })
          .map((snapshot) {
            // Check if we have daily topics to create if none exist
            if (snapshot.docs.isEmpty) {
              // Create a daily room if none exists, but don't wait for it
              checkAndCreateDailyRoom().then((created) {
                if (created) {
                  print('Created new daily discussion topic');
                }
              });
            }
            
            return snapshot.docs
                .map((doc) {
                  try {
                    return PopupChatRoom.fromFirestore(doc);
                  } catch (e) {
                    print('Error parsing popup chat room: $e');
                    return null;
                  }
                })
                .where((room) => room != null)
                .cast<PopupChatRoom>()
                .toList();
          });
    } catch (e) {
      print('Error setting up scheduled popup chats stream: $e');
      // Return an empty stream if there's a setup error
      return Stream.value([]);
    }
  }

  // Get all active waiting rooms
  Stream<List<PopupChatRoom>> getActiveWaitingRoomsStream() {
    return _popupRoomsCollection
        .where(
          'status',
          isEqualTo: PopupChatRoom.statusToString(PopupChatStatus.waiting),
        )
        .orderBy('scheduledTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PopupChatRoom.fromFirestore(doc))
              .toList();
        });
  }

  // Get all active popup chats
  Stream<List<PopupChatRoom>> getActiveChatRoomsStream() {
    return _popupRoomsCollection
        .where(
          'status',
          isEqualTo: PopupChatRoom.statusToString(PopupChatStatus.active),
        )
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PopupChatRoom.fromFirestore(doc))
              .toList();
        });
  }

  // Get popup chats that the current user is participating in
  Stream<List<PopupChatRoom>> getUserPopupChatRoomsStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _popupRoomsCollection
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PopupChatRoom.fromFirestore(doc))
              .toList();
        });
  }

  // Create a new popup chat room
  Future<String?> createPopupChatRoom({
    required String topic,
    required String description,
    required String category,
    required DateTime scheduledTime,
    int maxCapacity = 20,
    String? imageUrl,
    String? creatorId,
  }) async {
    final userId = creatorId ?? currentUserId;
    if (userId == null) return null;

    // No admin check needed anymore, we use creatorId param to handle system actions

    // Calculate waiting room open time (10 minutes before scheduled time)
    final openWaitingRoomTime = scheduledTime.subtract(
      const Duration(minutes: PopupChatRoom.waitingRoomDurationMinutes),
    );

    // Create the popup chat room
    final docRef = await _popupRoomsCollection.add({
      'name': topic,
      'topic': topic,
      'description': description,
      'category': category,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'openWaitingRoomTime': Timestamp.fromDate(openWaitingRoomTime),
      'memberIds': [],
      'memberCount': 0,
      'creatorId': userId,
      'isPublic': true,
      'createdAt': FieldValue.serverTimestamp(),
      'maxCapacity': maxCapacity,
      'currentUsers': 0,
      'waitingUsers': [],
      'status': PopupChatRoom.statusToString(PopupChatStatus.scheduled),
      'imageUrl': imageUrl,
    });

    return docRef.id;
  }

  // Create a daily random popup chat room
  Future<String?> createDailyRandomChatRoom() async {
    // Pick a random category
    final categories = chatTopics.keys.toList();
    final randomCategory = categories[_random.nextInt(categories.length)];

    // Pick a random topic from that category
    final topicsList = chatTopics[randomCategory]!;
    final randomTopic = topicsList[_random.nextInt(topicsList.length)];

    // Schedule for tomorrow at noon
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1, hours: 12)); // Next day at 12:00

    // Create an engaging description
    final description =
        'Daily discussion: "$randomTopic". '
        'Limited to ${20} participants. Join the waiting room ${PopupChatRoom.waitingRoomDurationMinutes} '
        'minutes before the scheduled time to secure your spot!';

    // Create the room with the system bot as creator
    return createPopupChatRoom(
      topic: randomTopic,
      description: description,
      category: randomCategory,
      scheduledTime: scheduledTime,
      maxCapacity: 20,
      creatorId: systemBotId,
    );
  }

  // Check if we need to create a new daily chat room
  Future<bool> checkAndCreateDailyRoom() async {
    try {
      // Ensure the system bot exists first
      await _userService.ensureSystemBotExists();
      
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final tomorrowMidnight = todayMidnight.add(const Duration(days: 1));

      // Check if we have any system-created rooms scheduled for tomorrow already
      try {
        final existingRooms =
            await _popupRoomsCollection
                .where('creatorId', isEqualTo: systemBotId)
                .where(
                  'scheduledTime',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(todayMidnight),
                )
                .where(
                  'scheduledTime',
                  isLessThan: Timestamp.fromDate(tomorrowMidnight),
                )
                .limit(1)
                .get();

        // If no rooms exist for tomorrow, create one
        if (existingRooms.docs.isEmpty) {
          print("No daily discussion topics found - creating a new one");
          final roomId = await createDailyRandomChatRoom();
          return roomId != null;
        }
        
        print("Found existing daily discussion topic");
        return false;
      } catch (e) {
        // If there's an error with the query, it might be because the collection doesn't exist yet
        print("Error checking for existing rooms: $e - creating a new one");
        final roomId = await createDailyRandomChatRoom();
        return roomId != null;
      }
    } catch (e) {
      print('Error checking/creating daily room: $e');
      return false;
    }
  }

  // Join waiting room for a popup chat
  Future<bool> joinWaitingRoom(String roomId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      // Get the room
      final roomDoc = await _popupRoomsCollection.doc(roomId).get();
      if (!roomDoc.exists) return false;

      final room = PopupChatRoom.fromFirestore(roomDoc);

      // Check if waiting room is open
      if (room.status != PopupChatStatus.waiting) {
        throw Exception('Waiting room is not open yet');
      }

      // Check if waiting room is full
      if (room.isWaitingListFull) {
        throw Exception('Waiting room is full');
      }

      // Add user to waiting list if not already in it
      if (!room.waitingUsers.contains(userId)) {
        await _popupRoomsCollection.doc(roomId).update({
          'waitingUsers': FieldValue.arrayUnion([userId]),
        });
      }

      return true;
    } catch (e) {
      print('Error joining waiting room: $e');
      return false;
    }
  }

  // Leave waiting room
  Future<bool> leaveWaitingRoom(String roomId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      // Remove user from waiting list
      await _popupRoomsCollection.doc(roomId).update({
        'waitingUsers': FieldValue.arrayRemove([userId]),
      });

      return true;
    } catch (e) {
      print('Error leaving waiting room: $e');
      return false;
    }
  }

  // Admin method to create multiple popup chat rooms at once (for demo or testing)
  Future<List<String>> createMultiplePopupChatRooms(int count) async {
    final userId = currentUserId ?? systemBotId;

    final List<String> createdRoomIds = [];
    final now = DateTime.now();

    // Create rooms with staggered start times
    for (int i = 0; i < count; i++) {
      // Pick random category and topic
      final categories = chatTopics.keys.toList();
      final category = categories[i % categories.length];
      final topicsList = chatTopics[category]!;
      final topic = topicsList[i % topicsList.length];

      // Stagger start times (first one in 1 hour, then every 30 minutes)
      final scheduledTime = now.add(Duration(minutes: 60 + (i * 30)));

      // Create description
      final description =
          'Join this exciting discussion about "$topic". '
          'Limited to ${20} participants. Join the waiting room ${PopupChatRoom.waitingRoomDurationMinutes} '
          'minutes before the scheduled time!';

      try {
        final roomId = await createPopupChatRoom(
          topic: topic,
          description: description,
          category: category,
          scheduledTime: scheduledTime,
          maxCapacity: 20,
          creatorId: userId,
        );

        if (roomId != null) {
          createdRoomIds.add(roomId);
        }
      } catch (e) {
        print('Error creating popup chat room: $e');
      }
    }

    return createdRoomIds;
  }

  // Internal method to open waiting room
  Future<void> _openWaitingRoom(String roomId) async {
    try {
      // Update room status to waiting
      await _popupRoomsCollection.doc(roomId).update({
        'status': PopupChatRoom.statusToString(PopupChatStatus.waiting),
        'openWaitingRoomTime': FieldValue.serverTimestamp(),
      });

      // Send notifications to all users about waiting room opening
      // This would typically be done with a Firebase Cloud Function
      _notifyWaitingRoomOpen(roomId);
    } catch (e) {
      print('Error opening waiting room: $e');
    }
  }

  // Internal method to start chat (move from waiting to active)
  Future<void> _startChatRoom(String roomId) async {
    try {
      // Get the room
      final roomDoc = await _popupRoomsCollection.doc(roomId).get();
      if (!roomDoc.exists) return;

      final room = PopupChatRoom.fromFirestore(roomDoc);
      final waitingUsers = room.waitingUsers;

      // If more users than capacity, take only max capacity
      final selectedUsers =
          waitingUsers.length > room.maxCapacity
              ? waitingUsers.sublist(0, room.maxCapacity)
              : waitingUsers;

      // Update room status to active and add waiting users to members
      await _popupRoomsCollection.doc(roomId).update({
        'status': PopupChatRoom.statusToString(PopupChatStatus.active),
        'startTime': FieldValue.serverTimestamp(),
        'memberIds': selectedUsers,
        'memberCount': selectedUsers.length,
        'currentUsers': selectedUsers.length,
      });

      // Calculate end time (default duration after start)
      final endTime = DateTime.now().add(
        const Duration(minutes: PopupChatRoom.defaultChatDurationMinutes),
      );

      // Schedule chat end
      await _popupRoomsCollection.doc(roomId).update({
        'endTime': Timestamp.fromDate(endTime),
      });

      // Notify selected users that they have been added to the chat
      _notifyChatStarted(roomId, selectedUsers);
    } catch (e) {
      print('Error starting chat room: $e');
    }
  }

  // Manually open waiting room (simplified, no admin check)
  Future<bool> manuallyOpenWaitingRoom(String roomId) async {
    try {
      await _openWaitingRoom(roomId);
      return true;
    } catch (e) {
      print('Error manually opening waiting room: $e');
      return false;
    }
  }

  // Manually start chat (simplified, no admin check)
  Future<bool> manuallyStartChat(String roomId) async {
    try {
      await _startChatRoom(roomId);
      return true;
    } catch (e) {
      print('Error manually starting chat room: $e');
      return false;
    }
  }

  // Internal method to end chat
  Future<void> _endChatRoom(String roomId) async {
    try {
      // Update room status to completed
      await _popupRoomsCollection.doc(roomId).update({
        'status': PopupChatRoom.statusToString(PopupChatStatus.completed),
        'isClosed': true,
        'closedAt': FieldValue.serverTimestamp(),
      });

      // Set expiration date (7 days after closing)
      final expirationTime = DateTime.now().add(const Duration(days: 7));
      await _popupRoomsCollection.doc(roomId).update({
        'expiresAt': Timestamp.fromDate(expirationTime),
      });

      // Notify members that the chat has ended
      _notifyChatEnded(roomId);
    } catch (e) {
      print('Error ending chat room: $e');
    }
  }

  // Manually end chat (simplified, no admin check)
  Future<bool> manuallyEndChat(String roomId) async {
    try {
      await _endChatRoom(roomId);
      return true;
    } catch (e) {
      print('Error manually ending chat room: $e');
      return false;
    }
  }

  // Setup timers for scheduled actions on a popup chat room
  void setupPopupChatTimers(String roomId) async {
    // Get the room
    final roomDoc = await _popupRoomsCollection.doc(roomId).get();
    if (!roomDoc.exists) return;

    final room = PopupChatRoom.fromFirestore(roomDoc);

    // If room is already active or completed, do nothing
    if (room.status == PopupChatStatus.active ||
        room.status == PopupChatStatus.completed) {
      return;
    }

    final now = DateTime.now();

    // If room is still scheduled and waiting room should open now
    if (room.status == PopupChatStatus.scheduled &&
        room.openWaitingRoomTime != null &&
        room.openWaitingRoomTime!.isBefore(now)) {
      await _openWaitingRoom(roomId);
    }

    // If waiting room is open and chat should start now
    if (room.status == PopupChatStatus.waiting &&
        room.scheduledTime.isBefore(now)) {
      await _startChatRoom(roomId);
    }

    // If chat is active and should end now
    if (room.status == PopupChatStatus.active &&
        room.endTime != null &&
        room.endTime!.isBefore(now)) {
      await _endChatRoom(roomId);
    }
  }

  // Check and update all popup chat rooms
  Future<void> checkAllPopupChatRooms() async {
    try {
      final now = Timestamp.fromDate(DateTime.now());

      // Find rooms where waiting room should open
      final waitingRoomQuery =
          await _popupRoomsCollection
              .where(
                'status',
                isEqualTo: PopupChatRoom.statusToString(
                  PopupChatStatus.scheduled,
                ),
              )
              .where('openWaitingRoomTime', isLessThanOrEqualTo: now)
              .get();

      for (var doc in waitingRoomQuery.docs) {
        await _openWaitingRoom(doc.id);
      }

      // Find rooms where chat should start
      final startChatQuery =
          await _popupRoomsCollection
              .where(
                'status',
                isEqualTo: PopupChatRoom.statusToString(
                  PopupChatStatus.waiting,
                ),
              )
              .where('scheduledTime', isLessThanOrEqualTo: now)
              .get();

      for (var doc in startChatQuery.docs) {
        await _startChatRoom(doc.id);
      }

      // Find rooms where chat should end
      final endChatQuery =
          await _popupRoomsCollection
              .where(
                'status',
                isEqualTo: PopupChatRoom.statusToString(PopupChatStatus.active),
              )
              .where('endTime', isLessThanOrEqualTo: now)
              .get();

      for (var doc in endChatQuery.docs) {
        await _endChatRoom(doc.id);
      }

      // Check if we need to create a new daily room
      await checkAndCreateDailyRoom();
    } catch (e) {
      print('Error checking popup chat rooms: $e');
    }
  }

  // Notification methods
  Future<void> _notifyWaitingRoomOpen(String roomId) async {
    try {
      // Get room details
      final roomDoc = await _popupRoomsCollection.doc(roomId).get();
      final room = PopupChatRoom.fromFirestore(roomDoc);

      // In a real app, you would have a list of users who have registered interest
      // For now, let's assume all users get notified
      final usersQuery = await _firestore.collection('users').get();

      final batch = _firestore.batch();
      for (var userDoc in usersQuery.docs) {
        final userId = userDoc.id;

        final notification = NotificationModel(
          id: '', // Will be set by Firestore
          userId: userId,
          type: NotificationType.systemMessage,
          roomId: roomId,
          roomName: room.name,
          message:
              'The waiting room for "${room.name}" is now open! Join now to secure your spot.',
          createdAt: DateTime.now(),
          isRead: false,
        );

        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, notification.toMap());
      }

      await batch.commit();
    } catch (e) {
      print('Error notifying about waiting room opening: $e');
    }
  }

  Future<void> _notifyChatStarted(
    String roomId,
    List<String> selectedUsers,
  ) async {
    try {
      // Get room details
      final roomDoc = await _popupRoomsCollection.doc(roomId).get();
      final room = PopupChatRoom.fromFirestore(roomDoc);

      // Create notifications for selected users
      final batch = _firestore.batch();
      for (String userId in selectedUsers) {
        final notification = NotificationModel(
          id: '', // Will be set by Firestore
          userId: userId,
          type: NotificationType.systemMessage,
          roomId: roomId,
          roomName: room.name,
          message:
              'You have been selected to join the popup chat "${room.name}"! The chat is now live.',
          createdAt: DateTime.now(),
          isRead: false,
        );

        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, notification.toMap());
      }

      await batch.commit();
    } catch (e) {
      print('Error notifying about chat starting: $e');
    }
  }

  Future<void> _notifyChatEnded(String roomId) async {
    try {
      // Get room details
      final roomDoc = await _popupRoomsCollection.doc(roomId).get();
      final room = PopupChatRoom.fromFirestore(roomDoc);

      // Notify all members
      final batch = _firestore.batch();
      for (String userId in room.memberIds) {
        final notification = NotificationModel(
          id: '', // Will be set by Firestore
          userId: userId,
          type: NotificationType.roomClosed,
          roomId: roomId,
          roomName: room.name,
          message:
              'The popup chat "${room.name}" has ended. You can still view the conversation for the next 7 days.',
          createdAt: DateTime.now(),
          isRead: false,
        );

        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, notification.toMap());
      }

      await batch.commit();
    } catch (e) {
      print('Error notifying about chat ending: $e');
    }
  }

  // Initialize the popup chat service
  Future<void> initialize() async {
    try {
      // Ensure system bot exists
      await _userService.ensureSystemBotExists();
      
      // Check if we need to create a daily room
      await checkAndCreateDailyRoom();
      
      // Check for expired/pending popup chat rooms
      checkAllPopupChatRooms();
      
      print('Popup chat service initialized successfully');
    } catch (e) {
      print('Error initializing popup chat service: $e');
    }
  }
}
