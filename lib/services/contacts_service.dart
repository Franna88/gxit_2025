import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact_model.dart';

class ContactsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get contacts from device (requires permissions)
  Future<List<Contact>?> getDeviceContacts() async {
    // Request contacts permission
    var status = await Permission.contacts.status;
    if (!status.isGranted) {
      status = await Permission.contacts.request();
      if (!status.isGranted) {
        return null; // Permission denied
      }
    }

    try {
      // Load contacts with phone numbers
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      return contacts;
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      return null;
    }
  }

  // Save contact to Firebase
  Future<void> saveContact(ContactModel contact, String group) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Create a new contact document
      final contactRef = _firestore.collection('users').doc(userId).collection('contacts').doc();
      
      // Save the contact with group information
      await contactRef.set({
        ...contact.toJson(),
        'groupId': group,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Contact saved successfully');
    } catch (e) {
      debugPrint('Error saving contact: $e');
      throw Exception('Failed to save contact');
    }
  }

  // Get all contacts from Firebase
  Stream<List<ContactModel>> getContacts() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ContactModel.fromJson(data);
      }).toList();
    });
  }

  // Get contacts by group
  Stream<List<ContactModel>> getContactsByGroup(String group) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .where('groupId', isEqualTo: group)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ContactModel.fromJson(data);
      }).toList();
    });
  }

  // Delete contact
  Future<void> deleteContact(String contactId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .delete();

      debugPrint('Contact deleted successfully');
    } catch (e) {
      debugPrint('Error deleting contact: $e');
      throw Exception('Failed to delete contact');
    }
  }

  // Send SMS invitation
  Future<bool> sendSmsInvitation(String phoneNumber, String message) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      return false;
    }
  }

  // Share app invitation via any platform
  Future<void> shareAppInvitation(String message) async {
    try {
      await Share.share(message, subject: 'Join me on GXIT!');
    } catch (e) {
      debugPrint('Error sharing invitation: $e');
    }
  }
}
