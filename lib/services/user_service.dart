import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
    required String id,
    required String name,
    required String email,
    bool isSystemBot = false,
  }) async {
    await getUserRef(id).set({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'tokens': 500, // Initialize with 500 tokens
      'isSystemBot': isSystemBot,
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
        id: userId,
        name: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
      );
    } else {
      // User exists, just update the login timestamp
      await updateLastLogin(userId);
    }
  }

  // Get user tokens
  Future<int> getUserTokens(String userId) async {
    try {
      // For demo purposes, if user doesn't exist in Firebase
      if (_auth.currentUser == null || userId == 'demoUser') {
        print('Using demo token balance');
        return 500; // Default token balance for demo
      }

      final user = await getUser(userId);
      return user?.tokens ?? 0;
    } catch (e) {
      print('Error getting user tokens: $e');
      return 500; // Default token balance in case of error
    }
  }

  // Check if user has enough tokens
  Future<bool> hasEnoughTokens(String userId, int requiredTokens) async {
    try {
      // For demo purposes
      if (_auth.currentUser == null || userId == 'demoUser') {
        print('Using demo tokens check');
        return true; // Always have enough tokens in demo mode
      }

      final userTokens = await getUserTokens(userId);
      return userTokens >= requiredTokens;
    } catch (e) {
      print('Error checking tokens: $e');
      return true; // Default to true in case of error for demo purposes
    }
  }

  // Use tokens for an action
  Future<bool> useTokens(String userId, int tokenAmount) async {
    try {
      // For demo purposes
      if (_auth.currentUser == null || userId == 'demoUser') {
        print('Using demo tokens usage');
        return true; // Pretend token usage was successful in demo mode
      }

      // First check if user has enough tokens
      final hasTokens = await hasEnoughTokens(userId, tokenAmount);
      if (!hasTokens) {
        return false;
      }

      // Get current token count
      final user = await getUser(userId);
      if (user == null) {
        return false;
      }

      // Update tokens
      final newTokenCount = user.tokens - tokenAmount;
      await getUserRef(userId).update({'tokens': newTokenCount});
      return true;
    } catch (e) {
      print('Error using tokens: $e');
      return true; // Default to true in case of error for demo purposes
    }
  }

  // Add tokens to user
  Future<void> addTokens(String userId, int tokenAmount) async {
    final user = await getUser(userId);
    if (user != null) {
      final newTokenCount = user.tokens + tokenAmount;
      await getUserRef(userId).update({'tokens': newTokenCount});
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Begin the interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in flow
        return null;
      }

      // Get authentication details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credentials for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Ensure user exists in Firestore
      if (userCredential.user != null) {
        await ensureUserExists(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow; // Re-throw the exception for the UI to handle
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Sign out from Google
    await _auth.signOut(); // Sign out from Firebase
  }

  // Search for users by name or email
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      // Search by name
      final nameQuerySnapshot =
          await _firestore
              .collection('users')
              .where('name', isGreaterThanOrEqualTo: query)
              .where(
                'name',
                isLessThanOrEqualTo: query + '\uf8ff',
              ) // Unicode trick for prefix search
              .limit(10)
              .get();

      // Search by email
      final emailQuerySnapshot =
          await _firestore
              .collection('users')
              .where('email', isGreaterThanOrEqualTo: query)
              .where('email', isLessThanOrEqualTo: query + '\uf8ff')
              .limit(10)
              .get();

      // Combine results
      final List<UserModel> users = [];

      for (var doc in nameQuerySnapshot.docs) {
        final user = UserModel.fromFirestore(doc);
        // Don't add current user to search results
        if (user.id != currentUserId) {
          users.add(user);
        }
      }

      for (var doc in emailQuerySnapshot.docs) {
        final user = UserModel.fromFirestore(doc);
        // Only add if not already added and not current user
        if (!users.any((u) => u.id == user.id) && user.id != currentUserId) {
          users.add(user);
        }
      }

      return users;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Ensure the system bot user exists in Firestore
  Future<void> ensureSystemBotExists() async {
    final systemBotId = 'system_bot';
    final userDoc = await getUserRef(systemBotId).get();

    if (!userDoc.exists) {
      // Create the system bot user
      await createUser(
        id: systemBotId,
        name: 'Chat Bot',
        email: 'system@gxit.app',
        isSystemBot: true,
      );
    }
  }
}
