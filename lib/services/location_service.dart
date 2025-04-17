import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/area_chat_room.dart';
import 'dart:math';

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

  // Get nearby area chat rooms
  Future<List<AreaChatRoom>> getNearbyAreaChatRooms() async {
    final position = await getCurrentLocation();
    Position currentPosition;

    if (position == null) {
      // Use Jeffreys Bay coordinates if we can't get location
      currentPosition = Position(
        latitude: jeffreysBayLat,
        longitude: jeffreysBayLng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    } else {
      currentPosition = position;
    }

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

    // Create a chat room for each defined area
    jeffreysBayAreas.forEach((areaName, details) {
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
          memberCount: Random().nextInt(100) + 50,
          isPublic: true,
          createdAt: DateTime.now().subtract(
            Duration(days: Random().nextInt(90)),
          ),
        ),
      );
    });

    return chatRooms;
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

      return AreaChatRoom(
        id: 'sample-${index + 1}',
        name: areaName,
        memberIds: [],
        areaName: areaName,
        location: GeoPoint(lat, lng),
        radius: 5.0,
        description: 'Sample chat room #${index + 1} near your location',
        createdAt: DateTime.now(),
        memberCount: random.nextInt(50) + 5,
      );
    }).toList();
  }

  // Get all official area chat rooms
  Future<List<AreaChatRoom>> getOfficialAreaChatRooms() {
    return Future.value(_generateJeffreysBayAreaChatRooms());
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
}
