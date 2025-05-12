import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/chat_room.dart';
import '../models/area_chat_room.dart';
import 'dart:io';

// Command-line tool to fix a chat room's visibility
// Run with: dart lib/tools/fix_room_visibility.dart <room_id>
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Please provide a room ID as argument.');
    exit(1);
  }
  
  final roomId = args[0];
  print('Fixing visibility for room with ID: $roomId');
  
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
      
      if (room.isPublic) {
        print('\nRoom is already public. No changes needed.');
      } else {
        print('\nSetting room to public...');
        await FirebaseFirestore.instance
            .collection('chatRooms')
            .doc(roomId)
            .update({'isPublic': true});
        print('Room visibility updated successfully!');
      }
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
      
      if (room.isPublic) {
        print('\nRoom is already public. No changes needed.');
      } else {
        print('\nSetting room to public...');
        await FirebaseFirestore.instance
            .collection('areaChatRooms')
            .doc(roomId)
            .update({'isPublic': true});
        print('Room visibility updated successfully!');
      }
      exit(0);
    }
    
    // Not found in either collection
    print('\n=== ROOM NOT FOUND ===');
    print('The room with ID $roomId does not exist in either chatRooms or areaChatRooms collections.');
    exit(1);
    
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
}