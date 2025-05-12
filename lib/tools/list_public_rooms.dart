import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/chat_room.dart';
import '../models/area_chat_room.dart';

// Command-line tool to list all public chat rooms in the system
// Run with: dart lib/tools/list_public_rooms.dart
void main() async {
  print('Listing all public chat rooms in the system...');
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  try {
    print('\n=== PUBLIC ROOMS IN chatRooms COLLECTION ===');
    
    // Get all public rooms from chatRooms collection
    final publicRooms = await FirebaseFirestore.instance
        .collection('chatRooms')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
        
    if (publicRooms.docs.isEmpty) {
      print('No public rooms found in chatRooms collection.');
    } else {
      print('Found ${publicRooms.docs.length} public rooms:');
      
      for (final doc in publicRooms.docs) {
        final room = ChatRoom.fromFirestore(doc);
        print('\nRoom ID: ${room.id}');
        print('Name: ${room.name}');
        print('Creator ID: ${room.creatorId ?? "No creator"}');
        print('Created At: ${room.createdAt}');
        print('Member Count: ${room.memberCount}');
      }
    }
    
    print('\n=== PUBLIC ROOMS IN areaChatRooms COLLECTION ===');
    
    // Get all public rooms from areaChatRooms collection
    final publicAreaRooms = await FirebaseFirestore.instance
        .collection('areaChatRooms')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
        
    if (publicAreaRooms.docs.isEmpty) {
      print('No public rooms found in areaChatRooms collection.');
    } else {
      print('Found ${publicAreaRooms.docs.length} public area rooms:');
      
      for (final doc in publicAreaRooms.docs) {
        final room = AreaChatRoom.fromFirestore(doc);
        print('\nRoom ID: ${room.id}');
        print('Name: ${room.name}');
        print('Area Name: ${room.areaName}');
        print('Creator ID: ${room.creatorId ?? "No creator"}');
        print('Created At: ${room.createdAt}');
        print('Member Count: ${room.memberCount}');
        print('Is Official: ${room.isOfficial}');
      }
    }
    
    // Look specifically for "Surf and Chill" room
    print('\n=== SEARCH FOR "SURF AND CHILL" ROOMS ===');
    bool found = false;
    
    for (final doc in publicRooms.docs) {
      final room = ChatRoom.fromFirestore(doc);
      if (room.name.toLowerCase().contains('surf') && 
          room.name.toLowerCase().contains('chill')) {
        found = true;
        print('\nFound in chatRooms:');
        print('Room ID: ${room.id}');
        print('Name: ${room.name}');
        print('Is Public: ${room.isPublic}');
        print('Creator ID: ${room.creatorId ?? "No creator"}');
      }
    }
    
    for (final doc in publicAreaRooms.docs) {
      final room = AreaChatRoom.fromFirestore(doc);
      if (room.name.toLowerCase().contains('surf') && 
          room.name.toLowerCase().contains('chill')) {
        found = true;
        print('\nFound in areaChatRooms:');
        print('Room ID: ${room.id}');
        print('Name: ${room.name}');
        print('Is Public: ${room.isPublic}');
        print('Creator ID: ${room.creatorId ?? "No creator"}');
      }
    }
    
    if (!found) {
      print('No rooms found with name containing "Surf and Chill".');
    }
    
  } catch (e) {
    print('Error: $e');
  }
} 