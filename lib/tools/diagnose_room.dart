import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/chat_room.dart';
import '../models/area_chat_room.dart';
import 'dart:io';

// Command-line tool to diagnose issues with chat rooms
// Run with: dart lib/tools/diagnose_room.dart <room_id>
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Please provide a room ID as argument.');
    exit(1);
  }
  
  final roomId = args[0];
  print('Diagnosing room with ID: $roomId');
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  try {
    // First check in chatRooms collection
    final roomDoc = await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(roomId)
        .get();
        
    if (roomDoc.exists) {
      final room = ChatRoom.fromFirestore(roomDoc);
      print('\n=== ROOM FOUND IN chatRooms COLLECTION ===');
      _printRoomDetails(room);
      exit(0);
    }
    
    // If not found, check in areaChatRooms collection
    final areaRoomDoc = await FirebaseFirestore.instance
        .collection('areaChatRooms')
        .doc(roomId)
        .get();
        
    if (areaRoomDoc.exists) {
      final room = AreaChatRoom.fromFirestore(areaRoomDoc);
      print('\n=== ROOM FOUND IN areaChatRooms COLLECTION ===');
      _printRoomDetails(room);
      
      // Print area-specific details
      print('Area Name: ${room.areaName}');
      print('Location: ${room.location.latitude}, ${room.location.longitude}');
      print('Radius: ${room.radius} km');
      print('Is Official: ${room.isOfficial}');
      print('Description: ${room.description}');
      exit(0);
    }
    
    // Not found in either collection
    print('\n=== ROOM NOT FOUND ===');
    print('The room with ID $roomId does not exist in either chatRooms or areaChatRooms collections.');
    
    // As a special check, try to find it in all collections with a different ID
    print('\n=== CHECKING FOR ROOMS WITH SIMILAR NAME ===');
    
    // Check for rooms with name containing "Surf and Chill"
    final publicRooms = await FirebaseFirestore.instance
        .collection('chatRooms')
        .where('isPublic', isEqualTo: true)
        .get();
        
    bool found = false;
    
    for (final doc in publicRooms.docs) {
      final room = ChatRoom.fromFirestore(doc);
      if (room.name.toLowerCase().contains('surf') && 
          room.name.toLowerCase().contains('chill')) {
        found = true;
        print('\nFound possible match in chatRooms:');
        print('ID: ${room.id}');
        print('Name: ${room.name}');
        print('Is Public: ${room.isPublic}');
      }
    }
    
    final publicAreaRooms = await FirebaseFirestore.instance
        .collection('areaChatRooms')
        .where('isPublic', isEqualTo: true)
        .get();
        
    for (final doc in publicAreaRooms.docs) {
      final room = AreaChatRoom.fromFirestore(doc);
      if (room.name.toLowerCase().contains('surf') && 
          room.name.toLowerCase().contains('chill')) {
        found = true;
        print('\nFound possible match in areaChatRooms:');
        print('ID: ${room.id}');
        print('Name: ${room.name}');
        print('Is Public: ${room.isPublic}');
      }
    }
    
    if (!found) {
      print('No rooms found with name containing "Surf and Chill".');
    }
    
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

void _printRoomDetails(ChatRoom room) {
  print('ID: ${room.id}');
  print('Name: ${room.name}');
  print('Is Public: ${room.isPublic}');
  print('Creator ID: ${room.creatorId ?? "No creator"}');
  print('Created At: ${room.createdAt}');
  print('Member Count: ${room.memberCount}');
  print('Member IDs: ${room.memberIds.join(", ")}');
  print('Last Message: ${room.lastMessage ?? "No messages"}');
  print('Last Activity: ${room.lastActivity ?? "No activity"}');
  print('Is Closed: ${room.isClosed}');
} 