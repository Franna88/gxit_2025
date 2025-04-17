import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../models/user_model.dart';
import '../models/user_mood.dart';
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
    final userId = currentUserId;
    if (userId == null) return false;

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

    return await _userService.getUserTokens(userId);
  }
}
