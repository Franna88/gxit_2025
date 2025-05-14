import 'package:flutter/material.dart';
import '../widgets/contact_item.dart';
import 'contact.dart';

class ContactModel {
  final String id;
  final String name;
  final String address;
  final String? avatarUrl;
  final Color? avatarColor;
  final bool isFavorite;
  final String? phone;
  final String? email;
  final ContactStatus status;
  final String? messageType;
  final String? chatRoomId;

  ContactModel({
    required this.id,
    required this.name,
    required this.address,
    this.avatarUrl,
    this.avatarColor,
    this.isFavorite = false,
    this.phone,
    this.email,
    this.status = ContactStatus.offline,
    this.messageType,
    this.chatRoomId,
  });

  ContactModel copyWith({
    String? id,
    String? name,
    String? address,
    String? avatarUrl,
    Color? avatarColor,
    bool? isFavorite,
    String? phone,
    String? email,
    ContactStatus? status,
    String? messageType,
    String? chatRoomId,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarColor: avatarColor ?? this.avatarColor,
      isFavorite: isFavorite ?? this.isFavorite,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      messageType: messageType ?? this.messageType,
      chatRoomId: chatRoomId ?? this.chatRoomId,
    );
  }

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      avatarColor:
          json['avatarColor'] != null
              ? Color(json['avatarColor'] as int)
              : null,
      isFavorite: json['isFavorite'] as bool? ?? false,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      status: _parseStatus(json['status']),
      messageType: json['messageType'] as String?,
      chatRoomId: json['chatRoomId'] as String?,
    );
  }

  static ContactStatus _parseStatus(dynamic status) {
    if (status == null) return ContactStatus.offline;

    if (status is String) {
      switch (status.toLowerCase()) {
        case 'online':
          return ContactStatus.online;
        case 'away':
          return ContactStatus.away;
        default:
          return ContactStatus.offline;
      }
    } else if (status is int) {
      return ContactStatus.values[status];
    }

    return ContactStatus.offline;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'avatarUrl': avatarUrl,
      'avatarColor': avatarColor?.value,
      'isFavorite': isFavorite,
      'phone': phone,
      'email': email,
      'status': status.index,
      'messageType': messageType,
      'chatRoomId': chatRoomId,
    };
  }

  // Convert from Contact model
  factory ContactModel.fromContact(
    Contact contact, {
    ContactStatus status = ContactStatus.offline,
    String? messageType,
    String? chatRoomId,
  }) {
    return ContactModel(
      id: contact.id,
      name: contact.name,
      address: contact.address,
      avatarUrl: contact.avatarUrl,
      avatarColor: contact.avatarColor,
      isFavorite: contact.isFavorite,
      phone: contact.phone,
      email: contact.email,
      status: status,
      messageType: messageType,
      chatRoomId: chatRoomId,
    );
  }
}
