import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_room.dart';

enum PopupChatStatus {
  scheduled, // Not yet open for waiting room
  waiting, // Waiting room open
  active, // Chat is live
  completed, // Chat is over
  cancelled, // Chat was cancelled
}

class PopupChatRoom extends ChatRoom {
  final DateTime scheduledTime;
  final DateTime? openWaitingRoomTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final int maxCapacity;
  final int currentUsers;
  final List<String> waitingUsers;
  final PopupChatStatus status;
  final String topic;
  final String description;
  final String? imageUrl;
  final String category;

  // Number of minutes the waiting room is open before the chat starts
  static const int waitingRoomDurationMinutes = 10;

  // Default duration of the popup chat in minutes
  static const int defaultChatDurationMinutes = 60;

  PopupChatRoom({
    required super.id,
    required super.name,
    required super.memberIds,
    super.lastMessage,
    super.lastSenderId,
    super.lastActivity,
    super.memberCount,
    super.isPublic,
    super.creatorId,
    super.createdAt,
    super.isClosed,
    super.closedAt,
    super.expiresAt,
    super.closedBy,
    super.isDirectMessage,
    super.participantIds,
    required this.scheduledTime,
    this.openWaitingRoomTime,
    this.startTime,
    this.endTime,
    required this.maxCapacity,
    this.currentUsers = 0,
    this.waitingUsers = const [],
    required this.status,
    required this.topic,
    required this.description,
    this.imageUrl,
    required this.category,
  });

  // Create from Firestore document
  factory PopupChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Document data was null');
    }

    return PopupChatRoom(
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
      isClosed: data['isClosed'] ?? false,
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      closedBy: data['closedBy'],
      isDirectMessage: data['isDirectMessage'] ?? false,
      participantIds: data['participantIds'] != null
          ? List<String>.from(data['participantIds'])
          : null,
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      openWaitingRoomTime:
          (data['openWaitingRoomTime'] as Timestamp?)?.toDate(),
      startTime: (data['startTime'] as Timestamp?)?.toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      maxCapacity: data['maxCapacity'] ?? 20,
      currentUsers: data['currentUsers'] ?? 0,
      waitingUsers: List<String>.from(data['waitingUsers'] ?? []),
      status: _parseStatus(data['status'] ?? 'scheduled'),
      topic: data['topic'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      category: data['category'] ?? 'General',
    );
  }

  static PopupChatStatus _parseStatus(String status) {
    switch (status) {
      case 'waiting':
        return PopupChatStatus.waiting;
      case 'active':
        return PopupChatStatus.active;
      case 'completed':
        return PopupChatStatus.completed;
      case 'cancelled':
        return PopupChatStatus.cancelled;
      case 'scheduled':
      default:
        return PopupChatStatus.scheduled;
    }
  }

  static String statusToString(PopupChatStatus status) {
    switch (status) {
      case PopupChatStatus.waiting:
        return 'waiting';
      case PopupChatStatus.active:
        return 'active';
      case PopupChatStatus.completed:
        return 'completed';
      case PopupChatStatus.cancelled:
        return 'cancelled';
      case PopupChatStatus.scheduled:
        return 'scheduled';
    }
  }

  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();

    return {
      ...baseMap,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'openWaitingRoomTime': openWaitingRoomTime != null
          ? Timestamp.fromDate(openWaitingRoomTime!)
          : null,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'maxCapacity': maxCapacity,
      'currentUsers': currentUsers,
      'waitingUsers': waitingUsers,
      'status': statusToString(status),
      'topic': topic,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
    };
  }

  // Return a new PopupChatRoom with waitingUsers modified
  PopupChatRoom addToWaitingList(String userId) {
    if (waitingUsers.contains(userId)) {
      return this;
    }

    return copyWith(waitingUsers: [...waitingUsers, userId]);
  }

  // Return a new PopupChatRoom with waitingUsers modified
  PopupChatRoom removeFromWaitingList(String userId) {
    if (!waitingUsers.contains(userId)) {
      return this;
    }

    return copyWith(
      waitingUsers: waitingUsers.where((id) => id != userId).toList(),
    );
  }

  // Check if waiting room is open
  bool get isWaitingRoomOpen => status == PopupChatStatus.waiting;

  // Check if chat is currently live
  bool get isChatActive => status == PopupChatStatus.active;

  // Check if waiting list is full
  bool get isWaitingListFull => waitingUsers.length >= maxCapacity;

  // Create updated popup chat room
  @override
  PopupChatRoom copyWith({
    String? id,
    String? name,
    List<String>? memberIds,
    String? lastMessage,
    String? lastSenderId,
    DateTime? lastActivity,
    int? memberCount,
    bool? isPublic,
    String? creatorId,
    DateTime? createdAt,
    bool? isClosed,
    DateTime? closedAt,
    DateTime? expiresAt,
    String? closedBy,
    bool? isDirectMessage,
    List<String>? participantIds,
    DateTime? scheduledTime,
    DateTime? openWaitingRoomTime,
    DateTime? startTime,
    DateTime? endTime,
    int? maxCapacity,
    int? currentUsers,
    List<String>? waitingUsers,
    PopupChatStatus? status,
    String? topic,
    String? description,
    String? imageUrl,
    String? category,
  }) {
    return PopupChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      memberIds: memberIds ?? this.memberIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      lastActivity: lastActivity ?? this.lastActivity,
      memberCount: memberCount ?? this.memberCount,
      isPublic: isPublic ?? this.isPublic,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      isClosed: isClosed ?? this.isClosed,
      closedAt: closedAt ?? this.closedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      closedBy: closedBy ?? this.closedBy,
      isDirectMessage: isDirectMessage ?? super.isDirectMessage,
      participantIds: participantIds ?? super.participantIds,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      openWaitingRoomTime: openWaitingRoomTime ?? this.openWaitingRoomTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      currentUsers: currentUsers ?? this.currentUsers,
      waitingUsers: waitingUsers ?? this.waitingUsers,
      status: status ?? this.status,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
    );
  }
}
