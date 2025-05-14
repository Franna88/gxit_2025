import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus { pending, accepted, declined }

class ChatInvitation {
  final String id;
  final String roomId;
  final String roomName;
  final String inviterId;
  final String inviteeId;
  final bool isPublic;
  final bool isDirectMessage;
  final DateTime createdAt;
  final InvitationStatus status;

  ChatInvitation({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.inviterId,
    required this.inviteeId,
    required this.isPublic,
    this.isDirectMessage = false,
    required this.createdAt,
    required this.status,
  });

  // Create from Firestore document
  factory ChatInvitation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Document data was null');
    }

    return ChatInvitation(
      id: doc.id,
      roomId: data['roomId'] ?? '',
      roomName: data['roomName'] ?? '',
      inviterId: data['inviterId'] ?? '',
      inviteeId: data['inviteeId'] ?? '',
      isPublic: data['isPublic'] ?? true,
      isDirectMessage: data['isDirectMessage'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseStatus(data['status']),
    );
  }

  // Parse status string to enum
  static InvitationStatus _parseStatus(String? status) {
    switch (status) {
      case 'accepted':
        return InvitationStatus.accepted;
      case 'declined':
        return InvitationStatus.declined;
      case 'pending':
      default:
        return InvitationStatus.pending;
    }
  }

  // Convert status enum to string
  static String statusToString(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.accepted:
        return 'accepted';
      case InvitationStatus.declined:
        return 'declined';
      case InvitationStatus.pending:
        return 'pending';
    }
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      'inviterId': inviterId,
      'inviteeId': inviteeId,
      'isPublic': isPublic,
      'isDirectMessage': isDirectMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': statusToString(status),
    };
  }

  // Create updated invitation
  ChatInvitation copyWith({
    String? id,
    String? roomId,
    String? roomName,
    String? inviterId,
    String? inviteeId,
    bool? isPublic,
    bool? isDirectMessage,
    DateTime? createdAt,
    InvitationStatus? status,
  }) {
    return ChatInvitation(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      inviterId: inviterId ?? this.inviterId,
      inviteeId: inviteeId ?? this.inviteeId,
      isPublic: isPublic ?? this.isPublic,
      isDirectMessage: isDirectMessage ?? this.isDirectMessage,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
