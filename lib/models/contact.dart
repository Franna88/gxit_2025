import 'package:flutter/material.dart';

class Contact {
  final String id;
  final String name;
  final String address;
  final String? avatarUrl;
  final Color? avatarColor;
  final bool isFavorite;
  final String? phone;
  final String? email;

  Contact({
    required this.id,
    required this.name,
    required this.address,
    this.avatarUrl,
    this.avatarColor,
    this.isFavorite = false,
    this.phone,
    this.email,
  });

  Contact copyWith({
    String? id,
    String? name,
    String? address,
    String? avatarUrl,
    Color? avatarColor,
    bool? isFavorite,
    String? phone,
    String? email,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarColor: avatarColor ?? this.avatarColor,
      isFavorite: isFavorite ?? this.isFavorite,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
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
    );
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
    };
  }
}
