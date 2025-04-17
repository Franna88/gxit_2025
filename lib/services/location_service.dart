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
      // Fallback area name if we can't get location
      return "Unknown Area";
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
      return "Unknown Area";
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
    if (position == null) {
      return [];
    }

    try {
      // In a real implementation, we would query Firestore for nearby chat rooms
      // based on geohashing or a geographical query

      // For now, get all chat rooms and filter locally
      // This approach doesn't scale well but works for demo purposes
      final snapshot = await _firestore.collection('areaChatRooms').get();

      if (snapshot.docs.isEmpty) {
        // If no rooms exist, generate and return sample ones
        return _generateSampleAreaChatRooms(position);
      }

      final chatRooms =
          snapshot.docs
              .map((doc) => AreaChatRoom.fromFirestore(doc))
              .where((room) => _isRoomNearby(room, position))
              .toList();

      return chatRooms;
    } catch (e) {
      debugPrint('Error fetching area chat rooms: $e');
      return _generateSampleAreaChatRooms(position);
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
