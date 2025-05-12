import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_mood.dart';

class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final String chatRoomId;
  final DateTime timestamp;
  final MoodType? mood;
  final List<String>? reactions;
  final bool tokenUsed;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.chatRoomId,
    DateTime? timestamp,
    this.mood,
    this.reactions,
    this.tokenUsed = false,
  }) : timestamp = timestamp ?? DateTime.now();

  // Create from Firestore document
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Document data was null');
    }

    return ChatMessage(
      id: doc.id,
      content: data['content'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      chatRoomId: data['chatRoomId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mood: data['mood'] != null ? MoodType.values[data['mood']] : null,
      reactions:
          data['reactions'] != null
              ? List<String>.from(data['reactions'])
              : null,
      tokenUsed: data['tokenUsed'] ?? false,
    );
  }

  // Convert to map for Firestore and local storage
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Make sure to include the ID for local storage
      'content': content,
      'senderId': senderId,
      'senderName': senderName,
      'chatRoomId': chatRoomId,
      'timestamp': Timestamp.fromDate(timestamp),
      'mood': mood?.index,
      'reactions': reactions,
      'tokenUsed': tokenUsed,
    };
  }

  // Create from JSON map (for local storage)
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    // Convert timestamp based on type
    DateTime timestamp;
    if (map['timestamp'] is Timestamp) {
      timestamp = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(map['timestamp']);
    } else {
      timestamp = DateTime.now();
    }
    
    return ChatMessage(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      chatRoomId: map['chatRoomId'] ?? '',
      timestamp: timestamp,
      mood: map['mood'] != null ? MoodType.values[map['mood']] : null,
      reactions: map['reactions'] != null ? List<String>.from(map['reactions']) : null,
      tokenUsed: map['tokenUsed'] ?? false,
    );
  }

  // Create updated message
  ChatMessage copyWith({
    String? content,
    String? senderId,
    String? senderName,
    String? chatRoomId,
    DateTime? timestamp,
    MoodType? mood,
    List<String>? reactions,
    bool? tokenUsed,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      timestamp: timestamp ?? this.timestamp,
      mood: mood ?? this.mood,
      reactions: reactions ?? this.reactions,
      tokenUsed: tokenUsed ?? this.tokenUsed,
    );
  }
}
