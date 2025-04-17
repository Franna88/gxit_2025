import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class ContactsService {
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
