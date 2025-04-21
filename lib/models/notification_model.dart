import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  roomClosed,
  invitationReceived,
  messageReceived,
  roomExpired,
  systemMessage,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String? roomId;
  final String? roomName;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    this.roomId,
    this.roomName,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.metadata,
  });

  // Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Document data was null');
    }

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: _parseType(data['type']),
      roomId: data['roomId'],
      roomName: data['roomName'],
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      metadata: data['metadata'],
    );
  }

  // Parse type string to enum
  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'room_closed':
        return NotificationType.roomClosed;
      case 'invitation_received':
        return NotificationType.invitationReceived;
      case 'message_received':
        return NotificationType.messageReceived;
      case 'room_expired':
        return NotificationType.roomExpired;
      case 'system_message':
      default:
        return NotificationType.systemMessage;
    }
  }

  // Convert type enum to string
  static String typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.roomClosed:
        return 'room_closed';
      case NotificationType.invitationReceived:
        return 'invitation_received';
      case NotificationType.messageReceived:
        return 'message_received';
      case NotificationType.roomExpired:
        return 'room_expired';
      case NotificationType.systemMessage:
        return 'system_message';
    }
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': typeToString(type),
      'roomId': roomId,
      'roomName': roomName,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  // Create updated notification
  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? roomId,
    String? roomName,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}
