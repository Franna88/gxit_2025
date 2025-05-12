import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final int tokens;
  final bool isSystemBot;
  final String? description;
  final String? preferences;
  final String? wants;
  final String? needs;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.createdAt,
    this.lastLogin,
    this.tokens = 500,
    this.isSystemBot = false,
    this.description,
    this.preferences,
    this.wants,
    this.needs,
  });

  // Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Document data was null');
    }

    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      tokens: data['tokens'] ?? 500,
      isSystemBot: data['isSystemBot'] ?? false,
      description: data['description'],
      preferences: data['preferences'],
      wants: data['wants'],
      needs: data['needs'],
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
      'lastLogin':
          lastLogin != null
              ? Timestamp.fromDate(lastLogin!)
              : FieldValue.serverTimestamp(),
      'tokens': tokens,
      'isSystemBot': isSystemBot,
      'description': description,
      'preferences': preferences,
      'wants': wants,
      'needs': needs,
    };
  }

  // Create updated user model
  UserModel copyWith({
    String? name,
    String? email,
    DateTime? lastLogin,
    int? tokens,
    bool? isSystemBot,
    String? description,
    String? preferences,
    String? wants,
    String? needs,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      tokens: tokens ?? this.tokens,
      isSystemBot: isSystemBot ?? this.isSystemBot,
      description: description ?? this.description,
      preferences: preferences ?? this.preferences,
      wants: wants ?? this.wants,
      needs: needs ?? this.needs,
    );
  }
}
