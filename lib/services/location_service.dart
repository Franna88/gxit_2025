import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/area_chat_room.dart';
import '../models/chat_room.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  final FirebaseFirestore _firestore;

  String? _currentAreaName;
  Position? _lastPosition;

  // Jeffreys Bay, South Africa coordinates
  static const double jeffreysBayLat = -34.0507;
  static const double jeffreysBayLng = 24.9307;

  // Surrounding areas coordinates
  static final Map<String, Map<String, dynamic>> jeffreysBayAreas = {
    'Jeffreys Bay Main Beach': {
      'lat': -34.0482,
      'lng': 24.9312,
      'description': 'Main beach area with perfect waves for surfing',
      'radius': 2.0,
    },
    'Paradise Beach': {
      'lat': -34.0744,
      'lng': 24.9142,
      'description': 'Beautiful quiet beach area south of Jeffreys Bay',
      'radius': 3.0,
    },
    'Aston Bay': {
      'lat': -34.0694,
      'lng': 24.9046,
      'description': 'Calm beach perfect for family activities',
      'radius': 2.5,
    },
    'Marina Martinique': {
      'lat': -34.0874,
      'lng': 24.9151,
      'description': 'Canal system with beautiful homes and water activities',
      'radius': 2.0,
    },
    'Kabeljouws': {
      'lat': -34.0098,
      'lng': 24.9349,
      'description': 'Nature reserve with beautiful coastline',
      'radius': 4.0,
    },
    'Humansdorp': {
      'lat': -34.0307,
      'lng': 24.7673,
      'description': 'Nearby town with shopping and services',
      'radius': 5.0,
    },
    'St Francis Bay': {
      'lat': -34.1715,
      'lng': 24.8419,
      'description': 'Coastal village with canals and golf courses',
      'radius': 4.0,
    },
    'Cape St Francis': {
      'lat': -34.2049,
      'lng': 24.8361,
      'description': 'Historic lighthouse and penguin rehabilitation center',
      'radius': 3.0,
    },
    'Oyster Bay': {
      'lat': -34.1742,
      'lng': 24.6593,
      'description': 'Small coastal village with beautiful beaches',
      'radius': 3.0,
    },
    'Supertubes': {
      'lat': -34.0531,
      'lng': 24.9265,
      'description': 'World-famous surf spot with perfect right-hand break',
      'radius': 1.0,
    },
  };

  // Private user-created chat rooms for the Jeffreys Bay area
  static final List<Map<String, dynamic>> privateJBayChatRooms = [
    {
      'name': 'JBay Surf Forecast',
      'areaName': 'Jeffreys Bay',
      'latitude': -34.0507,
      'longitude': 24.9307,
      'description': 'Daily updates on surf conditions and forecasts',
      'memberCount': 17,
      'isOfficial': false,
    },
    {
      'name': 'Local Restaurants',
      'areaName': 'Jeffreys Bay',
      'latitude': -34.0492,
      'longitude': 24.9295,
      'description': 'Restaurant recommendations and reviews in Jeffreys Bay',
      'memberCount': 12,
      'isOfficial': false,
    },
    {
      'name': 'Fishing Spots',
      'areaName': 'Jeffreys Bay Coast',
      'latitude': -34.0467,
      'longitude': 24.9335,
      'description': 'Sharing best fishing spots along the coast',
      'memberCount': 8,
      'isOfficial': false,
    },
    {
      'name': 'Beach Cleanup',
      'areaName': 'Paradise Beach',
      'latitude': -34.0744,
      'longitude': 24.9142,
      'description': 'Organizing beach cleanup events',
      'memberCount': 15,
      'isOfficial': false,
    },
    {
      'name': 'Supertubes Surf Club',
      'areaName': 'Supertubes',
      'latitude': -34.0531,
      'longitude': 24.9265,
      'description': 'Local surf club for Supertubes regulars',
      'memberCount': 19,
      'isOfficial': false,
    },
    {
      'name': 'Marina Homeowners',
      'areaName': 'Marina Martinique',
      'latitude': -34.0874,
      'longitude': 24.9151,
      'description': 'Chat for homeowners in Marina Martinique',
      'memberCount': 11,
      'isOfficial': false,
    },
    {
      'name': 'St Francis Golf',
      'areaName': 'St Francis Bay',
      'latitude': -34.1715,
      'longitude': 24.8419,
      'description': 'Golf enthusiasts in St Francis Bay',
      'memberCount': 9,
      'isOfficial': false,
    },
    {
      'name': 'Dolphin Sightings',
      'areaName': 'Cape St Francis',
      'latitude': -34.2049,
      'longitude': 24.8361,
      'description': 'Share dolphin and whale sightings in the area',
      'memberCount': 14,
      'isOfficial': false,
    },
    {
      'name': 'Extreme Sports',
      'areaName': 'Jeffreys Bay',
      'latitude': -34.0507,
      'longitude': 24.9307,
      'description': 'For extreme sports enthusiasts in the area',
      'memberCount': 7,
      'isOfficial': false,
    },
    {
      'name': 'Local Photography',
      'areaName': 'Jeffreys Bay Region',
      'latitude': -34.0507,
      'longitude': 24.9307,
      'description': 'Share your photos of the Jeffreys Bay region',
      'memberCount': 20,
      'isOfficial': false,
    },
  ];

  LocationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get current location
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      debugPrint('Location services are disabled');
      return null;
    }

    // Check for location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        debugPrint('Location permissions are denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      debugPrint('Location permissions are permanently denied');
      return null;
    }

    // Get the current position
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lastPosition = position;
      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  // Get the current area name based on location
  Future<String> getCurrentAreaName() async {
    if (_currentAreaName != null) {
      return _currentAreaName!;
    }

    final position = await getCurrentLocation();
    if (position != null) {
      // In a real app, this would use reverse geocoding to get the area name
      // For now, we're generating a name based on coordinates
      _currentAreaName = _generateAreaName(
        position.latitude,
        position.longitude,
      );
      return _currentAreaName!;
    } else {
      // Fallback to Jeffreys Bay area if we can't get location
      return "Jeffreys Bay";
    }
  }

  // Update the area name based on current location
  Future<String> updateAreaName() async {
    final position = await getCurrentLocation();
    if (position != null) {
      _currentAreaName = _generateAreaName(
        position.latitude,
        position.longitude,
      );
      return _currentAreaName!;
    } else {
      return "Jeffreys Bay";
    }
  }

  // Simple area name generation based on coordinates
  String _generateAreaName(double latitude, double longitude) {
    // Round to 2 decimal places to create areas roughly 1.1km x 1.1km
    final lat = (latitude * 100).round() / 100;
    final lng = (longitude * 100).round() / 100;
    return "Area_${lat}_${lng}";
  }

  // Get nearby area chat rooms from Firestore
  Future<List<AreaChatRoom>> getNearbyAreaChatRoomsFromFirestore(
    Position currentPosition,
  ) async {
    try {
      // In a real implementation, we would query Firestore for nearby chat rooms
      // based on geohashing or a geographical query

      // For now, get all chat rooms and filter locally
      // This approach doesn't scale well but works for demo purposes
      final snapshot = await _firestore.collection('areaChatRooms').get();

      if (snapshot.docs.isEmpty) {
        // If no rooms exist, generate Jeffreys Bay area chat rooms
        return _generateJeffreysBayAreaChatRooms();
      }

      final chatRooms =
          snapshot.docs
              .map((doc) => AreaChatRoom.fromFirestore(doc))
              .where((room) => _isRoomNearby(room, currentPosition))
              .toList();

      return chatRooms;
    } catch (e) {
      debugPrint('Error fetching area chat rooms: $e');
      return _generateJeffreysBayAreaChatRooms();
    }
  }

  // Check if a chat room is nearby (within 5km)
  bool _isRoomNearby(AreaChatRoom room, Position currentPosition) {
    final userLocation = GeoPoint(
      currentPosition.latitude,
      currentPosition.longitude,
    );

    return room.isLocationInArea(userLocation);
  }

  // Generate Jeffreys Bay area chat rooms
  List<AreaChatRoom> _generateJeffreysBayAreaChatRooms() {
    final List<AreaChatRoom> chatRooms = [];
    final random = Random();

    // Create a chat room for each defined area
    jeffreysBayAreas.forEach((areaName, details) {
      // Ensure member count is between 5-20
      final memberCount = random.nextInt(16) + 5; // 5 to 20 members

      chatRooms.add(
        AreaChatRoom(
          id: 'area-${areaName.toLowerCase().replaceAll(' ', '-')}',
          name: areaName,
          memberIds: [],
          areaName: areaName,
          location: GeoPoint(details['lat'], details['lng']),
          radius: details['radius'],
          description: details['description'],
          isOfficial: true,
          memberCount: memberCount,
          isPublic: true,
          createdAt: DateTime.now().subtract(
            Duration(days: random.nextInt(90)),
          ),
        ),
      );
    });

    return chatRooms;
  }

  // Get official area chat rooms
  Future<List<AreaChatRoom>> getOfficialAreaChatRooms() async {
    try {
      final snapshot =
          await _firestore
              .collection('areaChatRooms')
              .where('isOfficial', isEqualTo: true)
              // Explicitly exclude direct messages
              .where('isDirectMessage', isEqualTo: false)
              .orderBy('createdAt', descending: true)
              .get();

      if (snapshot.docs.isEmpty) {
        return _generateOfficialAreaChatRooms();
      }

      return snapshot.docs
          .map((doc) => AreaChatRoom.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching official area chat rooms: $e');
      return _generateOfficialAreaChatRooms();
    }
  }

  // Get private chat rooms for the current user
  Future<List<AreaChatRoom>> getPrivateChatRooms() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return [];
      }

      // Get regular chat rooms first
      final regularRoomsSnapshot =
          await _firestore
              .collection('chatRooms')
              .where('memberIds', arrayContains: userId)
              .where('isPublic', isEqualTo: false)
              .orderBy('lastActivity', descending: true)
              .get();

      List<AreaChatRoom> chatRooms = [];

      // Convert regular chat rooms to area chat rooms (with default location)
      if (regularRoomsSnapshot.docs.isNotEmpty) {
        chatRooms =
            regularRoomsSnapshot.docs.map((doc) {
              final chatRoom = ChatRoom.fromFirestore(doc);
              
              // Skip direct messages - they should only appear in Contacts > Active Chats
              if (chatRoom.isDirectMessage) {
                return null;
              }

              // Create a pseudo area chat room
              return AreaChatRoom(
                id: chatRoom.id,
                name: chatRoom.name,
                memberIds: chatRoom.memberIds,
                areaName: 'Private',
                location: const GeoPoint(-34.0507, 24.9307), // Default location
                radius: 5.0,
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
            })
            .where((room) => room != null)
            .cast<AreaChatRoom>()
            .toList();
      }

      // Get area chat rooms that are private and the user is a member
      final areaRoomsSnapshot =
          await _firestore
              .collection('areaChatRooms')
              .where('memberIds', arrayContains: userId)
              .where('isPublic', isEqualTo: false)
              // Explicitly exclude direct messages
              .where('isDirectMessage', isEqualTo: false)
              .orderBy('lastActivity', descending: true)
              .get();

      // Add area chat rooms to the list
      if (areaRoomsSnapshot.docs.isNotEmpty) {
        chatRooms.addAll(
          areaRoomsSnapshot.docs.map((doc) => AreaChatRoom.fromFirestore(doc)),
        );
      }

      // Sort by lastActivity
      chatRooms.sort((a, b) {
        if (a.lastActivity == null && b.lastActivity == null) return 0;
        if (a.lastActivity == null) return 1;
        if (b.lastActivity == null) return -1;
        return b.lastActivity!.compareTo(a.lastActivity!);
      });

      return chatRooms;
    } catch (e) {
      debugPrint('Error fetching private chat rooms: $e');
      return [];
    }
  }

  // Generate sample area chat rooms for testing
  List<AreaChatRoom> _generateSampleAreaChatRooms(Position position) {
    final random = Random();
    return List.generate(5, (index) {
      // Create chat rooms within 5km of the current position
      final latOffset = (random.nextDouble() - 0.5) * 0.05;
      final lngOffset = (random.nextDouble() - 0.5) * 0.05;

      final lat = position.latitude + latOffset;
      final lng = position.longitude + lngOffset;

      final areaName = _generateAreaName(lat, lng);

      // Ensure member count is between 5-20
      final memberCount = random.nextInt(16) + 5; // 5 to 20 members

      return AreaChatRoom(
        id: 'sample-${index + 1}',
        name: areaName,
        memberIds: [],
        areaName: areaName,
        location: GeoPoint(lat, lng),
        radius: 5.0,
        description: 'Sample chat room #${index + 1} near your location',
        createdAt: DateTime.now(),
        memberCount: memberCount,
      );
    }).toList();
  }

  // Create a new area chat room for a specific location
  Future<String?> createAreaChatRoom(AreaChatRoom room) async {
    try {
      final docRef = await _firestore
          .collection('areaChatRooms')
          .add(room.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating area chat room: $e');
      return null;
    }
  }

  // Get an area chat room by ID
  Future<AreaChatRoom?> getAreaChatRoomById(String roomId) async {
    try {
      final doc = await _firestore.collection('areaChatRooms').doc(roomId).get();
      if (doc.exists) {
        return AreaChatRoom.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting area chat room by ID: $e');
      return null;
    }
  }

  // Get all public user-created area chat rooms (non-official)
  Future<List<AreaChatRoom>> getPublicAreaChatRooms() async {
    try {
      final snapshot = await _firestore
          .collection('areaChatRooms')
          .where('isPublic', isEqualTo: true)
          .where('isOfficial', isEqualTo: false)
          // Explicitly exclude direct messages
          .where('isDirectMessage', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();
          
      return snapshot.docs
          .map((doc) => AreaChatRoom.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting public area chat rooms: $e');
      return [];
    }
  }

  // Generate official area chat rooms (fallback method)
  List<AreaChatRoom> _generateOfficialAreaChatRooms() {
    final random = Random();
    final List<AreaChatRoom> areaRooms = [];

    // Use the same data as the other method
    final chatRoomData = [
      {
        'name': 'Jeffreys Bay Main Beach',
        'areaName': 'Main Beach',
        'latitude': -34.0507,
        'longitude': 24.9307,
        'description': 'Chat for Main Beach visitors and locals',
        'memberCount': 120,
      },
      {
        'name': 'Supertubes Surf Spot',
        'areaName': 'Supertubes',
        'latitude': -34.0486,
        'longitude': 24.9320,
        'description': 'For surfers at the world-famous Supertubes',
        'memberCount': 95,
      },
      {
        'name': 'Marina Martinique',
        'areaName': 'Marina',
        'latitude': -34.0801,
        'longitude': 24.9120,
        'description': 'Marina residents and visitors chat',
        'memberCount': 42,
      },
    ];

    for (final roomData in chatRoomData) {
      areaRooms.add(
        AreaChatRoom(
          id:
              'area-${roomData['name'].toString().toLowerCase().replaceAll(' ', '-')}',
          name: roomData['name'] as String,
          memberIds: [],
          areaName: roomData['areaName'] as String,
          location: GeoPoint(
            roomData['latitude'] as double,
            roomData['longitude'] as double,
          ),
          radius: 3.0,
          description: roomData['description'] as String,
          isOfficial: true,
          memberCount: roomData['memberCount'] as int,
          isPublic: true,
          creatorId: 'system',
          createdAt: DateTime.now().subtract(
            Duration(days: random.nextInt(60)),
          ),
        ),
      );
    }

    return areaRooms;
  }
}
