import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get user document reference
  DocumentReference getUserRef(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  // Get user data as stream
  Stream<UserModel?> getUserStream(String userId) {
    return getUserRef(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromFirestore(snapshot);
      }
      return null;
    });
  }

  // Get current user as stream
  Stream<UserModel?> get currentUserStream {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(null);
    }
    return getUserStream(userId);
  }

  // Get user data once
  Future<UserModel?> getUser(String userId) async {
    final doc = await getUserRef(userId).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // Get current user data
  Future<UserModel?> get currentUser {
    final userId = currentUserId;
    if (userId == null) {
      return Future.value(null);
    }
    return getUser(userId);
  }

  // Create new user in Firestore
  Future<void> createUser({
    required String userId,
    required String name,
    required String email,
  }) async {
    await getUserRef(userId).set({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // Update user's last login
  Future<void> updateLastLogin(String userId) async {
    await getUserRef(
      userId,
    ).update({'lastLogin': FieldValue.serverTimestamp()});
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;

    if (updates.isNotEmpty) {
      await getUserRef(userId).update(updates);
    }
  }

  // Ensure user exists in Firestore, create if not
  Future<void> ensureUserExists(User firebaseUser) async {
    final userId = firebaseUser.uid;
    final userDoc = await getUserRef(userId).get();

    if (!userDoc.exists) {
      // User doesn't exist in Firestore, create a new record
      await createUser(
        userId: userId,
        name: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
      );
    } else {
      // User exists, just update the login timestamp
      await updateLastLogin(userId);
    }
  }
}
