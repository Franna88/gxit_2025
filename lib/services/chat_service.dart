import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../models/user_model.dart';
import '../models/user_mood.dart';
import '../models/chat_invitation.dart';
import '../models/notification_model.dart';
import 'user_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Collection references
  CollectionReference get _roomsCollection =>
      _firestore.collection('chatRooms');
  CollectionReference get _messagesCollection =>
      _firestore.collection('messages');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get chat room document reference
  DocumentReference getChatRoomRef(String roomId) {
    return _roomsCollection.doc(roomId);
  }

  // Get chat room data as stream
  Stream<ChatRoom?> getChatRoomStream(String roomId) {
    return getChatRoomRef(roomId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return ChatRoom.fromFirestore(snapshot);
      }
      return null;
    });
  }

  // Get all chat rooms for current user
  Stream<List<ChatRoom>> getUserChatRoomsStream(String userId) {
    return _roomsCollection
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatRoom.fromFirestore(doc))
              .toList();
        });
  }

  // Get initial messages for a chat room (non-stream version for quick checks)
  Future<List<ChatMessage>> getInitialMessages(String roomId, int limit) async {
    try {
      final snapshot = await _messagesCollection
          .where('chatRoomId', isEqualTo: roomId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
          
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting initial messages: $e');
      return [];
    }
  }

  // Get messages for a chat room
  Stream<List<ChatMessage>> getChatMessagesStream(String roomId) {
    return _messagesCollection
        .where('chatRoomId', isEqualTo: roomId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
  }

  // Create a new chat room with token validation
  Future<String?> createChatRoom({
    required String name,
    required List<String> memberIds,
    bool isPublic = true,
  }) async {
    final userId = currentUserId;
    if (userId == null) return null;

    // Check if user has enough tokens for creating a room
    final hasTokens = await _userService.hasEnoughTokens(
      userId,
      ChatRoom.createRoomTokenCost,
    );

    if (!hasTokens) {
      throw Exception('Not enough tokens to create a chat room');
    }

    // Deduct tokens from user
    final tokenUsed = await _userService.useTokens(
      userId,
      ChatRoom.createRoomTokenCost,
    );

    if (!tokenUsed) {
      return null;
    }

    // Include creator in members if not already
    if (!memberIds.contains(userId)) {
      memberIds.add(userId);
    }

    // Create the chat room
    final docRef = await _roomsCollection.add({
      'name': name,
      'memberIds': memberIds,
      'memberCount': memberIds.length,
      'creatorId': userId,
      'isPublic': isPublic,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // Send a message with token validation
  Future<bool> sendMessage({
    required String chatRoomId,
    required String content,
    MoodType? mood,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('Error: User is not authenticated');
        return false;
      }

      // Special handling for demo room to bypass Firebase
      if (chatRoomId == 'demoRoom') {
        print('Demo room detected - bypassing Firebase operations');
        return true;
      }

      // Check if the room exists and is not closed
      final roomDoc = await getChatRoomRef(chatRoomId).get();
      if (!roomDoc.exists) {
        throw Exception('Chat room does not exist');
      }

      final room = ChatRoom.fromFirestore(roomDoc);

      // Check if the room is closed
      if (room.isClosed) {
        throw Exception(
          'This chat room has been closed and no longer accepts messages',
        );
      }

      // Check if user has enough tokens for sending a message
      final hasTokens = await _userService.hasEnoughTokens(
        userId,
        ChatRoom.messageTokenCost,
      );

      if (!hasTokens) {
        throw Exception('Not enough tokens to send a message');
      }

      // Get user data for the sender name
      final user = await _userService.getUser(userId);
      if (user == null) return false;

      // Deduct tokens from user
      final tokenUsed = await _userService.useTokens(
        userId,
        ChatRoom.messageTokenCost,
      );

      if (!tokenUsed) {
        return false;
      }

      // Save the message
      await _messagesCollection.add({
        'content': content,
        'senderId': userId,
        'senderName': user.name,
        'chatRoomId': chatRoomId,
        'timestamp': FieldValue.serverTimestamp(),
        'mood': mood?.index,
        'tokenUsed': true,
      });

      // Update the chat room's last message
      await getChatRoomRef(chatRoomId).update({
        'lastMessage': content,
        'lastSenderId': userId,
        'lastActivity': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false; // Return false instead of rethrowing
    }
  }

  // Join a chat room
  Future<bool> joinChatRoom(String roomId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    // Update the room's member list
    await getChatRoomRef(roomId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'memberCount': FieldValue.increment(1),
    });

    return true;
  }

  // Leave a chat room
  Future<bool> leaveChatRoom(String roomId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    // Update the room's member list
    await getChatRoomRef(roomId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'memberCount': FieldValue.increment(-1),
    });

    return true;
  }

  // Delete a chat room (only creator can delete)
  Future<bool> deleteChatRoom(String roomId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    // Get the room to check if the current user is the creator
    final roomDoc = await getChatRoomRef(roomId).get();
    if (!roomDoc.exists) return false;

    final room = ChatRoom.fromFirestore(roomDoc);
    if (room.creatorId != userId) {
      throw Exception('Only the room creator can delete this room');
    }

    // Delete all messages in the room
    final messages =
        await _messagesCollection.where('chatRoomId', isEqualTo: roomId).get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }

    // Delete the room
    batch.delete(getChatRoomRef(roomId));
    await batch.commit();

    return true;
  }

  // Add reaction to a message
  Future<bool> addReaction(String messageId, String reaction) async {
    final userId = currentUserId;
    if (userId == null) return false;

    await _messagesCollection.doc(messageId).update({
      'reactions': FieldValue.arrayUnion([reaction]),
    });

    return true;
  }

  // Remove reaction from a message
  Future<bool> removeReaction(String messageId, String reaction) async {
    final userId = currentUserId;
    if (userId == null) return false;

    await _messagesCollection.doc(messageId).update({
      'reactions': FieldValue.arrayRemove([reaction]),
    });

    return true;
  }

  // Get user token balance
  Future<int> getUserTokenBalance() async {
    final userId = currentUserId;
    if (userId == null) return 0;

    try {
      final user = await _userService.getUser(userId);
      return user?.tokens ?? 0;
    } catch (e) {
      print('Error getting token balance: $e');
      return 0;
    }
  }

  // Find or create a private chat room between the current user and another user
  Future<String?> findOrCreatePrivateChatRoom({
    required String otherUserId,
    required String otherUserName,
  }) async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      // First check if a chat room already exists between these users
      final existingRoomsQuery =
          await _roomsCollection
              .where('memberIds', arrayContains: userId)
              .where('isPublic', isEqualTo: false)
              .get();

      // Look for a room that contains exactly these two users
      for (var doc in existingRoomsQuery.docs) {
        final room = ChatRoom.fromFirestore(doc);
        if (room.memberIds.length == 2 &&
            room.memberIds.contains(otherUserId) &&
            room.memberIds.contains(userId)) {
          return room.id;
        }
      }

      // If no room exists, create a new one
      // Check if user has enough tokens for creating a room
      final hasTokens = await _userService.hasEnoughTokens(
        userId,
        ChatRoom.createRoomTokenCost,
      );

      if (!hasTokens) {
        throw Exception('Not enough tokens to create a chat room');
      }

      // Get current user's name
      final currentUser = await _userService.getUser(userId);
      if (currentUser == null) return null;

      // Deduct tokens from user
      final tokenUsed = await _userService.useTokens(
        userId,
        ChatRoom.createRoomTokenCost,
      );

      if (!tokenUsed) {
        return null;
      }

      // Create room name from both users
      final roomName = "${currentUser.name} & $otherUserName";

      // Create the private chat room
      final docRef = await _roomsCollection.add({
        'name': roomName,
        'memberIds': [userId, otherUserId],
        'memberCount': 2,
        'creatorId': userId,
        'isPublic': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error finding or creating private chat room: $e');
      return null;
    }
  }

  // Create a new area chat room
  Future<String?> createAreaChatRoom({
    required String name,
    required String areaName,
    required GeoPoint location,
    required double radius,
    String? imageUrl,
    String? description,
    required List<String> memberIds,
    bool isPublic = true,
    bool isOfficial = false,
  }) async {
    final userId = currentUserId;
    if (userId == null) return null;

    // Check if user has enough tokens for creating a room
    final hasTokens = await _userService.hasEnoughTokens(
      userId,
      ChatRoom.createRoomTokenCost,
    );

    if (!hasTokens) {
      throw Exception('Not enough tokens to create a chat room');
    }

    // Deduct tokens from user
    final tokenUsed = await _userService.useTokens(
      userId,
      ChatRoom.createRoomTokenCost,
    );

    if (!tokenUsed) {
      return null;
    }

    // Include creator in members if not already
    if (!memberIds.contains(userId)) {
      memberIds.add(userId);
    }

    // Create the area chat room
    final docRef = await _firestore.collection('areaChatRooms').add({
      'name': name,
      'areaName': areaName,
      'location': location,
      'radius': radius,
      'imageUrl': imageUrl,
      'description': description,
      'memberIds': memberIds,
      'memberCount': memberIds.length,
      'creatorId': userId,
      'isPublic': isPublic,
      'isOfficial': isOfficial,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // Invite users to a chat room
  Future<bool> inviteUsersToChatRoom({
    required String roomId,
    required List<String> userIds,
  }) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      // Get the chat room to verify the current user is a member
      final roomDoc = await getChatRoomRef(roomId).get();
      if (!roomDoc.exists) return false;

      final room = ChatRoom.fromFirestore(roomDoc);

      // Verify current user is a member or creator
      if (!room.memberIds.contains(userId)) {
        throw Exception('You must be a member of the room to invite others');
      }

      // Create invitations for each user
      final batch = _firestore.batch();
      for (String inviteeId in userIds) {
        // Skip if user is already a member
        if (room.memberIds.contains(inviteeId)) continue;

        // Create invitation document
        final inviteRef = _firestore.collection('chatInvitations').doc();
        batch.set(inviteRef, {
          'roomId': roomId,
          'inviterId': userId,
          'inviteeId': inviteeId,
          'roomName': room.name,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending', // pending, accepted, declined
          'isPublic': room.isPublic,
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error inviting users to chat room: $e');
      return false;
    }
  }

  // Get chat room invitations for current user
  Stream<List<Map<String, dynamic>>> getChatInvitationsStream() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chatInvitations')
        .where('inviteeId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {'id': doc.id, ...data};
          }).toList();
        });
  }

  // Get chat room invitations for current user - typed version
  Stream<List<ChatInvitation>> getChatInvitations() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chatInvitations')
        .where('inviteeId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatInvitation.fromFirestore(doc))
              .toList();
        });
  }

  // Accept a chat room invitation
  Future<bool> acceptChatInvitation(String invitationId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      // Get the invitation
      final inviteDoc =
          await _firestore
              .collection('chatInvitations')
              .doc(invitationId)
              .get();
      if (!inviteDoc.exists) return false;

      final inviteData = inviteDoc.data() as Map<String, dynamic>;

      // Verify the current user is the invitee
      if (inviteData['inviteeId'] != userId) {
        throw Exception('This invitation is not for you');
      }

      // Update invitation status
      await _firestore.collection('chatInvitations').doc(invitationId).update({
        'status': 'accepted',
      });

      // Add user to chat room
      await joinChatRoom(inviteData['roomId']);

      return true;
    } catch (e) {
      print('Error accepting chat invitation: $e');
      return false;
    }
  }

  // Decline a chat room invitation
  Future<bool> declineChatInvitation(String invitationId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      // Get the invitation
      final inviteDoc =
          await _firestore
              .collection('chatInvitations')
              .doc(invitationId)
              .get();
      if (!inviteDoc.exists) return false;

      final inviteData = inviteDoc.data() as Map<String, dynamic>;

      // Verify the current user is the invitee
      if (inviteData['inviteeId'] != userId) {
        throw Exception('This invitation is not for you');
      }

      // Update invitation status
      await _firestore.collection('chatInvitations').doc(invitationId).update({
        'status': 'declined',
      });

      return true;
    } catch (e) {
      print('Error declining chat invitation: $e');
      return false;
    }
  }

  // Close a chat room (mark as closed and stop accepting new messages)
  Future<bool> closeChatRoom(String roomId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      // Get the room to check if the current user is the creator
      final roomDoc = await getChatRoomRef(roomId).get();
      if (!roomDoc.exists) return false;

      final room = ChatRoom.fromFirestore(roomDoc);

      // Only creator can close the room
      if (room.creatorId != userId) {
        throw Exception('Only the room creator can close this room');
      }

      // Mark the room as closed and set expiration
      final expirationTime = DateTime.now().add(
        const Duration(days: 7),
      ); // Keep for 7 days then delete

      await getChatRoomRef(roomId).update({
        'isClosed': true,
        'closedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expirationTime),
        'closedBy': userId,
      });

      // Notify all members about room closure
      final batch = _firestore.batch();
      for (String memberId in room.memberIds) {
        if (memberId == userId) continue; // Skip the creator

        final notification = NotificationModel(
          id: '', // Will be set by Firestore
          userId: memberId,
          type: NotificationType.roomClosed,
          roomId: roomId,
          roomName: room.name,
          message:
              'The chat room "${room.name}" has been closed by the creator.',
          createdAt: DateTime.now(),
          isRead: false,
        );

        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, notification.toMap());
      }

      await batch.commit();

      return true;
    } catch (e) {
      print('Error closing chat room: $e');
      return false;
    }
  }

  // Schedule a task to clean up expired chat rooms
  void setupChatRoomCleanup() {
    // This would typically be done with a Firebase Cloud Function
    // Here we are simulating checking for expired rooms when a user opens the app
    _cleanupExpiredChatRooms();
  }

  // Clean up expired chat rooms
  Future<void> _cleanupExpiredChatRooms() async {
    try {
      final now = DateTime.now();

      // Find all closed rooms with expiration dates in the past
      final expiredRoomsSnapshot =
          await _roomsCollection
              .where('isClosed', isEqualTo: true)
              .where('expiresAt', isLessThan: Timestamp.fromDate(now))
              .get();

      if (expiredRoomsSnapshot.docs.isEmpty) return;

      // Delete all expired rooms and their messages
      final batch = _firestore.batch();

      for (final doc in expiredRoomsSnapshot.docs) {
        final roomId = doc.id;

        // Delete all messages in the room
        final messagesSnapshot =
            await _messagesCollection
                .where('chatRoomId', isEqualTo: roomId)
                .get();

        for (final messageDoc in messagesSnapshot.docs) {
          batch.delete(messageDoc.reference);
        }

        // Delete the room itself
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Deleted ${expiredRoomsSnapshot.docs.length} expired chat rooms');
    } catch (e) {
      print('Error cleaning up expired chat rooms: $e');
    }
  }

  // Get notifications for current user (including room closure notifications)
  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {'id': doc.id, ...data};
          }).toList();
        });
  }

  // Get notifications for current user - typed version
  Stream<List<NotificationModel>> getNotifications() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }

  // Mark a notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }
}
