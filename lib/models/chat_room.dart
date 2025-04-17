import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final String name;
  final List<String> memberIds;
  final String? lastMessage;
  final String? lastSenderId;
  final DateTime? lastActivity;
  final int memberCount;
  final bool isPublic;
  final String? creatorId;
  final DateTime createdAt;

  // Token costs
  static const int messageTokenCost = 1;
  static const int createRoomTokenCost = 100;

  ChatRoom({
    required this.id,
    required this.name,
    required this.memberIds,
    this.lastMessage,
    this.lastSenderId,
    this.lastActivity,
    this.memberCount = 0,
    this.isPublic = true,
    this.creatorId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Create from Firestore document
  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Document data was null');
    }

    return ChatRoom(
      id: doc.id,
      name: data['name'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      lastMessage: data['lastMessage'],
      lastSenderId: data['lastSenderId'],
      lastActivity: (data['lastActivity'] as Timestamp?)?.toDate(),
      memberCount: data['memberCount'] ?? 0,
      isPublic: data['isPublic'] ?? true,
      creatorId: data['creatorId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'memberIds': memberIds,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'lastActivity':
          lastActivity != null
              ? Timestamp.fromDate(lastActivity!)
              : FieldValue.serverTimestamp(),
      'memberCount': memberCount,
      'isPublic': isPublic,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create updated chat room
  ChatRoom copyWith({
    String? name,
    List<String>? memberIds,
    String? lastMessage,
    String? lastSenderId,
    DateTime? lastActivity,
    int? memberCount,
    bool? isPublic,
  }) {
    return ChatRoom(
      id: id,
      name: name ?? this.name,
      memberIds: memberIds ?? this.memberIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      lastActivity: lastActivity ?? this.lastActivity,
      memberCount: memberCount ?? this.memberCount,
      isPublic: isPublic ?? this.isPublic,
      creatorId: creatorId,
      createdAt: createdAt,
    );
  }
}
