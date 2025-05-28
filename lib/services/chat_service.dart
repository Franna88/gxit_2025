import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../models/user_model.dart';
import '../models/user_mood.dart';
import '../models/chat_invitation.dart';
import '../models/notification_model.dart';
import 'user_service.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Collection references
  CollectionReference get _roomsCollection =>
      _firestore.collection('chatRooms');
  CollectionReference get _messagesCollection =>
      _firestore.collection('messages');

  // Keep a cache of messages per room to prevent flickering or disappearing messages
  final Map<String, List<ChatMessage>> _messageCache = {};
  
  // Flag to check if local storage has been initialized
  bool _localStorageInitialized = false;
  
  // Initialize local storage on startup
  Future<void> _initLocalStorage() async {
    if (_localStorageInitialized) return;
    
    try {
      // Restore cached messages from SharedPreferences
      await _loadCachedMessagesFromStorage();
      _localStorageInitialized = true;
    } catch (e) {
      print('Error initializing local storage: $e');
    }
  }
  
  // Save messages to local storage
  Future<void> _saveMessagesToLocalStorage(String roomId, List<ChatMessage> messages) async {
    try {
      if (messages.isEmpty) return;
      
      final prefs = await SharedPreferences.getInstance();
      
      // Convert messages to JSON
      final messagesJson = messages.map((msg) {
        final map = msg.toMap();
        // Handle timestamp conversion
        if (map['timestamp'] is Timestamp) {
          map['timestamp'] = (map['timestamp'] as Timestamp).millisecondsSinceEpoch;
        }
        return map;
      }).toList();
      
      // Save to SharedPreferences
      await prefs.setString('messages_$roomId', jsonEncode(messagesJson));
      print('Saved ${messages.length} messages to local storage for room $roomId');
    } catch (e) {
      print('Error saving messages to local storage: $e');
    }
  }
  
  // Load cached messages from local storage
  Future<void> _loadCachedMessagesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all keys from prefs that match our message pattern
      final keys = prefs.getKeys().where((key) => key.startsWith('messages_')).toList();
      
      for (final key in keys) {
        final roomId = key.substring('messages_'.length);
        final json = prefs.getString(key);
        
        if (json != null) {
          try {
            final List<dynamic> messagesJson = jsonDecode(json);
            final messages = messagesJson.map((jsonMsg) {
              return ChatMessage.fromMap(jsonMsg);
            }).toList();
            
            // Store in cache
            _messageCache[roomId] = messages;
            print('Loaded ${messages.length} cached messages for room $roomId');
          } catch (e) {
            print('Error parsing cached messages for room $roomId: $e');
          }
        }
      }
    } catch (e) {
      print('Error loading cached messages from storage: $e');
    }
  }

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid ?? '';

  // Get chat room document reference
  DocumentReference getChatRoomRef(String roomId) {
    return _roomsCollection.doc(roomId);
  }

  // Get chat room data as stream
  Stream<ChatRoom?> getChatRoomStream(String roomId) {
    return getChatRoomRef(roomId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      
      final chatRoom = ChatRoom.fromFirestore(snapshot);
      
      // Check for "new people" title in direct messages and fix it if needed
      if (chatRoom.isDirectMessage && 
          (chatRoom.name.toLowerCase() == "new people" || chatRoom.name.trim().isEmpty)) {
        // This is a temporary fix in the stream - consider updating the DB record
        print('Found "new people" room name in a direct message - should be fixed in database');
      }
      
      return chatRoom;
    });
  }

  // Get a chat room by ID (one-time fetch, not stream)
  Future<ChatRoom?> getChatRoomById(String roomId) async {
    try {
      final doc = await getChatRoomRef(roomId).get();
      if (doc.exists) {
        return ChatRoom.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting chat room by ID: $e');
      return null;
    }
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

  // Get all public chat rooms
  Future<List<ChatRoom>> getPublicChatRooms() async {
    try {
      final snapshot = await _roomsCollection
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
          
      return snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting public chat rooms: $e');
      return [];
    }
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
    // Ensure local storage is initialized
    if (!_localStorageInitialized) {
      _initLocalStorage();
    }
    
    // Create a map to track messages by sender to prevent their disappearance
    Map<String, ChatMessage> latestMessagesBySender = {};
    
    return _messagesCollection
        .where('chatRoomId', isEqualTo: roomId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
          
          // Process and store messages by sender ID to ensure we keep them
          for (final message in messages) {
            // Store the latest message from each sender
            if (!latestMessagesBySender.containsKey(message.senderId) || 
                latestMessagesBySender[message.senderId]!.timestamp.isBefore(message.timestamp)) {
              latestMessagesBySender[message.senderId] = message;
            }
          }
          
          // If we got messages, save them to persistent storage
          if (messages.isNotEmpty) {
            _saveMessagesToLocalStorage(roomId, messages);
          }
          
          // If we got an empty list but have cached messages, use the cache
          if (messages.isEmpty && _messageCache.containsKey(roomId) && 
              (_messageCache[roomId]?.isNotEmpty ?? false)) {
            print('Using cached messages for room: $roomId');
            return _messageCache[roomId]!;
          }
          
          // Otherwise, update the cache with the new messages
          if (messages.isNotEmpty) {
            _messageCache[roomId] = messages;
            
            // Since we have fresh messages, rebuild our map of latest messages per sender
            latestMessagesBySender.clear();
            for (final message in messages) {
              if (!latestMessagesBySender.containsKey(message.senderId) || 
                  latestMessagesBySender[message.senderId]!.timestamp.isBefore(message.timestamp)) {
                latestMessagesBySender[message.senderId] = message;
              }
            }
          } else if (_messageCache.containsKey(roomId)) {
            // If the new stream is empty but we have cache, check if we're losing sender messages
            // and append them to avoid losing messages from specific users
            final cachedMessages = _messageCache[roomId]!;
            
            // Track senders in the current stream result
            final senderIds = messages.map((m) => m.senderId).toSet();
            
            // Find messages from senders that are missing in this update but were in our cache
            for (final cachedMsg in cachedMessages) {
              if (!senderIds.contains(cachedMsg.senderId)) {
                // We found a sender whose messages disappeared - add their latest message back
                if (latestMessagesBySender.containsKey(cachedMsg.senderId)) {
                  messages.add(latestMessagesBySender[cachedMsg.senderId]!);
                  print('Preserved message from sender: ${cachedMsg.senderId} to prevent disappearance');
                }
              }
            }
          }
          
          // Ensure we don't return an empty list if there's a temporary issue
          if (messages.isEmpty) {
            print('Warning: Empty messages stream for room: $roomId');
          }
          
          return messages;
        });
  }

  // Create a new chat room
  // 
  // Parameters:
  // - name: The name of the chat room
  // - memberIds: List of user IDs who will be members of the room
  // - isPublic: If true, the room appears in public chat room sections and can be joined by anyone
  //             If false, the room is private and appears in the Private Chat Rooms section
  // - isDirectMessage: If true, this is a 1-on-1 direct message that appears only in Active Chats
  //                    If false, this is a regular chat room (public or private)
  //
  // Room Types:
  // 1. Public Chat Room: isPublic=true, isDirectMessage=false → Appears in Area/Public Rooms
  // 2. Private Chat Room: isPublic=false, isDirectMessage=false → Appears in Private Chat Rooms
  // 3. Direct Message: isPublic=false, isDirectMessage=true → Appears only in Active Chats
  Future<String?> createChatRoom({
    required String name,
    required List<String> memberIds,
    bool isPublic = true,
    bool isDirectMessage = false,
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
      'isDirectMessage': isDirectMessage,
      'participantIds': isDirectMessage ? memberIds : null,
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

      // Prepare message data
      final messageData = {
        'content': content,
        'senderId': userId,
        'senderName': user.name,
        'chatRoomId': chatRoomId,
        'timestamp': FieldValue.serverTimestamp(),
        'mood': mood?.index,
        'tokenUsed': true,
      };
      
      // Try to save the message with retry logic (up to 2 retries)
      DocumentReference? messageRef;
      int retries = 0;
      while (retries < 3 && messageRef == null) {
        try {
          messageRef = await _messagesCollection.add(messageData);
        } catch (e) {
          print('Error saving message (attempt ${retries + 1}): $e');
          retries++;
          if (retries >= 3) rethrow;
          // Wait briefly before retry
          await Future.delayed(Duration(milliseconds: 500 * retries));
        }
      }

      // Update the chat room's last message info in a separate transaction
      try {
        await getChatRoomRef(chatRoomId).update({
          'lastMessage': content,
          'lastSenderId': userId,
          'lastActivity': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Warning: Failed to update room last message: $e');
        // Don't fail the whole operation if only the room update fails
      }

      return messageRef != null;
    } catch (e) {
      print('Error sending message: $e');
      rethrow; // Rethrow so UI can show appropriate error
    }
  }

  // Join a chat room
  Future<bool> joinChatRoom(String roomId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      // First check if the room exists
      final roomDoc = await getChatRoomRef(roomId).get();
      if (!roomDoc.exists) {
        throw Exception('Chat room does not exist');
      }

      final room = ChatRoom.fromFirestore(roomDoc);
      
      // Check if user is already a member
      if (room.memberIds.contains(userId)) {
        // User is already a member, no need to update
        return true;
      }
      
      // Check if the room is public or if the user has been invited
      if (!room.isPublic) {
        // This is a private room - could add invitation check here in the future
        throw Exception('Cannot join a private chat room without an invitation');
      }

      // Update the room's member list
      await getChatRoomRef(roomId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'memberCount': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      print('Error joining chat room: $e');
      rethrow; // Rethrow so caller can display appropriate error
    }
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

  // Check if a pending invitation exists
  Future<bool> hasPendingInvitation(String inviteeId, String roomId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chatInvitations')
          .where('inviteeId', isEqualTo: inviteeId)
          .where('roomId', isEqualTo: roomId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking pending invitation: $e');
      return false;
    }
  }

  // Invite users to chat room
  // IMPORTANT: This method preserves the original room type (private chat room vs direct message)
  // and does NOT convert private chat rooms to direct messages based on invitation count.
  // The isDirectMessage flag should only be true for rooms originally created as direct messages.
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

      // Use the room's existing isDirectMessage flag instead of determining it based on invitation count
      // This preserves the original room type (private chat room vs direct message)
      bool isDirectMessage = room.isDirectMessage;

      // Create invitations for each user
      final batch = _firestore.batch();
      bool anyInvitationCreated = false;

      for (String inviteeId in userIds) {
        // Skip if user is already a member
        if (room.memberIds.contains(inviteeId)) {
          continue;
        }

        // Check for pending invitation
        final hasPending = await hasPendingInvitation(inviteeId, roomId);
        if (hasPending) {
          throw Exception('An invitation is already pending for this user');
        }

        // Create invitation document
        final inviteRef = _firestore.collection('chatInvitations').doc();
        batch.set(inviteRef, {
          'roomId': roomId,
          'inviterId': userId,
          'inviteeId': inviteeId,
          'roomName': room.name,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'isPublic': room.isPublic,
          'isDirectMessage': isDirectMessage,
        });
        anyInvitationCreated = true;

        // Only update the chat room with direct message info if it was originally created as a direct message
        // and doesn't already have participantIds set
        if (isDirectMessage && room.participantIds == null) {
          await getChatRoomRef(roomId).update({
            'participantIds': [userId, inviteeId],
          });
        }
      }

      // Only commit if we have any invitations to create
      if (anyInvitationCreated) {
        await batch.commit();
      }
      return true;
    } catch (e) {
      print('Error inviting users to chat room: $e');
      rethrow; // Rethrow to handle the specific error message in the UI
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
    if (userId == null) {
      print('Error accepting invitation: No current user');
      return false;
    }

    try {
      print('Accepting invitation: $invitationId for user: $userId');
      
      // Get the invitation
      final inviteDoc = await _firestore.collection('chatInvitations').doc(invitationId).get();
      if (!inviteDoc.exists) {
        print('Error accepting invitation: Invitation does not exist');
        return false;
      }

      final inviteData = inviteDoc.data() as Map<String, dynamic>;
      final String roomId = inviteData['roomId'] ?? '';
      
      // Validate room ID
      if (roomId.isEmpty) {
        print('Error accepting invitation: Room ID is missing or empty');
        return false;
      }

      // Verify the current user is the invitee
      if (inviteData['inviteeId'] != userId) {
        print('Error accepting invitation: This invitation is not for the current user');
        throw Exception('This invitation is not for you');
      }

      // Update invitation status
      await _firestore.collection('chatInvitations').doc(invitationId).update({
        'status': 'accepted',
      });

      print('Invitation status updated to accepted');
      
      // First check if the room exists
      final roomDoc = await getChatRoomRef(roomId).get();
      if (!roomDoc.exists) {
        print('Error accepting invitation: Chat room does not exist: $roomId');
        throw Exception('Chat room no longer exists');
      }
      
      // Verify the user is not already a member
      final room = ChatRoom.fromFirestore(roomDoc);
      if (room.memberIds.contains(userId)) {
        print('User is already a member of this room');
      } else {
        // Add user to chat room
        print('Adding user to chat room: $roomId');
        try {
          // Update the room's member list
          await getChatRoomRef(roomId).update({
            'memberIds': FieldValue.arrayUnion([userId]),
            'memberCount': FieldValue.increment(1),
          });
          print('User added to room successfully');
        } catch (e) {
          print('Error adding user to room: $e');
          // Continue execution - the invitation was accepted even if joining failed
        }
      }

      // Check if this is meant to be a direct message
      bool isDirectMessage = inviteData['isDirectMessage'] ?? false;
      
      // Only update chat room if it was originally created as a direct message
      // Don't convert private chat rooms to direct messages
      if (isDirectMessage) {
        final inviterId = inviteData['inviterId'] ?? '';
        if (inviterId.isNotEmpty) {
          try {
            // Only update participantIds if not already set, don't change isDirectMessage flag
            // as it should have been set correctly during room creation
            await getChatRoomRef(roomId).update({
              'participantIds': [inviterId, userId],
            });
            print('Room updated with participant IDs for direct messaging');
          } catch (e) {
            print('Error updating room participant IDs: $e');
            // Continue execution - the invitation was accepted even if this update failed
          }
        }
      }

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

  // Check if user is already a member of a chat room
  Future<bool> isUserMemberOfRoom(String roomId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      final roomDoc = await getChatRoomRef(roomId).get();
      if (!roomDoc.exists) return false;

      final room = ChatRoom.fromFirestore(roomDoc);
      return room.memberIds.contains(userId);
    } catch (e) {
      print('Error checking room membership: $e');
      return false;
    }
  }

  // Special method to force refresh messages for accounts with sync issues (like Litha's)
  Future<List<ChatMessage>> forceRefreshMessages(String roomId) async {
    try {
      // Ensure local storage is initialized
      if (!_localStorageInitialized) {
        await _initLocalStorage();
      }
      
      // Use a direct Firestore query to get the latest messages
      final snapshot = await _firestore
          .collection('messages')
          .where('chatRoomId', isEqualTo: roomId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
          
      final messages = snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
          
      // Check if we got messages from Firestore
      if (messages.isNotEmpty) {
        // Save to local storage immediately
        await _saveMessagesToLocalStorage(roomId, messages);
        
        // Update the cache with these fresh messages
        _messageCache[roomId] = messages;
        print('Force refreshed ${messages.length} messages for room: $roomId');
        return messages;
      } else {
        // If we didn't get any messages from Firestore, try to load from local storage
        if (_messageCache.containsKey(roomId) && _messageCache[roomId]!.isNotEmpty) {
          print('Using cached messages during force refresh for room: $roomId');
          return _messageCache[roomId]!;
        }
        
        // No messages anywhere - try one more desperate approach
        try {
          final fallbackSnapshot = await _firestore
              .collection('messages')
              .where('chatRoomId', isEqualTo: roomId)
              .get();
              
          if (fallbackSnapshot.docs.isNotEmpty) {
            final fallbackMessages = fallbackSnapshot.docs
                .map((doc) => ChatMessage.fromFirestore(doc))
                .toList();
                
            // Sort by timestamp
            fallbackMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            
            // Save to local storage
            await _saveMessagesToLocalStorage(roomId, fallbackMessages);
            
            // Update cache
            _messageCache[roomId] = fallbackMessages;
            print('Force refreshed ${fallbackMessages.length} messages using fallback for room: $roomId');
            return fallbackMessages;
          }
        } catch (fallbackError) {
          print('Error in fallback refresh: $fallbackError');
        }
      }
      
      return [];
    } catch (e) {
      print('Error force refreshing messages: $e');
      
      // Last resort: try to use the cache
      if (_messageCache.containsKey(roomId)) {
        return _messageCache[roomId]!;
      }
      
      return [];
    }
  }

  // Add messages directly to the local cache - helps ensure messages never disappear
  Future<void> addToLocalCache(String roomId, List<ChatMessage> messages) async {
    if (messages.isEmpty) return;
    
    // Ensure we have initialized local storage
    if (!_localStorageInitialized) {
      await _initLocalStorage();
    }
    
    // Add to memory cache first
    if (!_messageCache.containsKey(roomId)) {
      _messageCache[roomId] = [];
    }
    
    // Add new messages to existing ones (avoid duplicates by id)
    final existingIds = _messageCache[roomId]!.map((m) => m.id).toSet();
    for (final message in messages) {
      if (!existingIds.contains(message.id)) {
        _messageCache[roomId]!.add(message);
      }
    }
    
    // Sort again after adding
    _messageCache[roomId]!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Save to persistent storage
    await _saveMessagesToLocalStorage(roomId, _messageCache[roomId]!);
    
    print('Added ${messages.length} messages to local cache for room $roomId');
  }

  // Get a specific chat invitation by ID
  Future<ChatInvitation?> getChatInvitationById(String invitationId) async {
    try {
      if (invitationId.isEmpty) {
        print('Error: Attempted to get chat invitation with empty ID');
        return null;
      }
      
      print('Getting invitation with ID: $invitationId');
      final doc = await _firestore.collection('chatInvitations').doc(invitationId).get();
      
      if (!doc.exists) {
        print('Error: Chat invitation not found with ID: $invitationId');
        return null;
      }
      
      // Log data for debugging
      final data = doc.data();
      print('Invitation data: $data');
      
      if (data == null || data.isEmpty) {
        print('Error: Chat invitation data is null or empty');
        return null;
      }
      
      // Validate required fields
      if (!data.containsKey('roomId') || !data.containsKey('inviterId') || !data.containsKey('inviteeId')) {
        print('Error: Chat invitation missing required fields: $data');
        return null;
      }
      
      return ChatInvitation.fromFirestore(doc);
    } catch (e) {
      print('Error getting chat invitation: $e');
      return null;
    }
  }

  // Get all direct message chat rooms for current user
  Stream<List<ChatRoom>> getDirectMessageChatsStream(String userId) {
    return _roomsCollection
        .where('memberIds', arrayContains: userId)
        .where('isDirectMessage', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatRoom.fromFirestore(doc))
              .toList();
        });
  }

  // Get current user's active chats
  Stream<List<ChatModel>> getActiveChats() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.$userId': 0,
    });
  }

  // Get chat room ID for a given name (create if doesn't exist)
  Future<String> getChatRoomId(String name) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Check if chat room already exists
    final querySnapshot = await _firestore
        .collection('chats')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }

    // Create new chat room
    final docRef = await _firestore.collection('chats').add({
      'name': name,
      'participants': [userId],
      'isActive': true,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': {userId: 0},
    });

    return docRef.id;
  }

  // Utility method to update existing direct message rooms with participantIds
  Future<void> updateDirectMessageRoomsWithParticipantIds() async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      // Get all direct message rooms for the current user that don't have participantIds
      final querySnapshot = await _roomsCollection
          .where('memberIds', arrayContains: userId)
          .where('isDirectMessage', isEqualTo: true)
          .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        
        // Check if participantIds is missing or null
        if (data != null && data['participantIds'] == null) {
          final memberIds = List<String>.from(data['memberIds'] ?? []);
          
          // Update the document with participantIds
          await doc.reference.update({
            'participantIds': memberIds,
          });
          
          print('Updated chat room ${doc.id} with participantIds: $memberIds');
        }
      }
    } catch (e) {
      print('Error updating direct message rooms: $e');
    }
  }
}
