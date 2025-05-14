import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'chat_room.dart';

class AreaChatRoom extends ChatRoom {
  final String areaName;
  final GeoPoint location;
  final double radius; // Radius in kilometers
  final String? imageUrl;
  final String? description;
  final bool isOfficial; // Indicates if this is an app-generated room

  AreaChatRoom({
    required String id,
    required String name,
    required List<String> memberIds,
    required this.areaName,
    required this.location,
    required this.radius,
    this.imageUrl,
    this.description,
    this.isOfficial = true,
    String? lastMessage,
    String? lastSenderId,
    DateTime? lastActivity,
    int memberCount = 0,
    bool isPublic = true,
    String? creatorId,
    DateTime? createdAt,
    bool isDirectMessage = false,
    List<String>? participantIds,
  }) : super(
         id: id,
         name: name,
         memberIds: memberIds,
         lastMessage: lastMessage,
         lastSenderId: lastSenderId,
         lastActivity: lastActivity,
         memberCount: memberCount,
         isPublic: isPublic,
         creatorId: creatorId,
         createdAt: createdAt,
         isDirectMessage: isDirectMessage,
         participantIds: participantIds,
       );

  // Create from Firestore document
  factory AreaChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Document data was null');
    }

    // Get base ChatRoom properties first
    final chatRoom = ChatRoom.fromFirestore(doc);

    // Get GeoPoint from Firestore
    final geoPoint =
        data['location'] as GeoPoint? ??
        const GeoPoint(
          -34.0507,
          24.9307,
        ); // Default to Jeffreys Bay center if not specified

    return AreaChatRoom(
      id: chatRoom.id,
      name: chatRoom.name,
      memberIds: chatRoom.memberIds,
      areaName: data['areaName'] ?? '',
      location: geoPoint,
      radius: (data['radius'] ?? 5.0).toDouble(),
      imageUrl: data['imageUrl'],
      description: data['description'],
      isOfficial: data['isOfficial'] ?? true,
      lastMessage: chatRoom.lastMessage,
      lastSenderId: chatRoom.lastSenderId,
      lastActivity: chatRoom.lastActivity,
      memberCount: chatRoom.memberCount,
      isPublic: chatRoom.isPublic,
      creatorId: chatRoom.creatorId,
      createdAt: chatRoom.createdAt,
      isDirectMessage: chatRoom.isDirectMessage,
      participantIds: chatRoom.participantIds,
    );
  }

  // Convert to map for Firestore
  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();

    return {
      ...baseMap,
      'areaName': areaName,
      'location': location,
      'radius': radius,
      'imageUrl': imageUrl,
      'description': description,
      'isOfficial': isOfficial,
    };
  }

  // Calculate if a user is within this area's radius
  bool isLocationInArea(GeoPoint userLocation) {
    // Calculate distance between room location and user location in kilometers
    final distance = _calculateDistance(
      location.latitude,
      location.longitude,
      userLocation.latitude,
      userLocation.longitude,
    );

    return distance <= radius;
  }

  // Haversine formula to calculate distance between two coordinates in kilometers
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    const c = 12742; // 2 * Earth radius (6371 km)

    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;

    return c * math.asin(math.sqrt(a)); // Distance in km
  }
}
