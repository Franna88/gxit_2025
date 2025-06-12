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
    String? description,
    String? preferences,
    String? wants,
    String? needs,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (description != null) updates['description'] = description;
    if (preferences != null) updates['preferences'] = preferences;
    if (wants != null) updates['wants'] = wants;
    if (needs != null) updates['needs'] = needs;

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

  // Check if user has completed the self-description step
  Future<bool> hasCompletedSelfDescription(String userId) async {
    try {
      final user = await getUser(userId);
      return user?.description != null;
    } catch (e) {
      print('Error checking user description: $e');
      return false;
    }
  }

  // Check if user has completed the preferences step
  Future<bool> hasCompletedPreferences(String userId) async {
    try {
      final user = await getUser(userId);
      return user?.preferences != null;
    } catch (e) {
      print('Error checking user preferences: $e');
      return false;
    }
  }

  // Check if user has completed the wants step
  Future<bool> hasCompletedWants(String userId) async {
    try {
      final user = await getUser(userId);
      return user?.wants != null;
    } catch (e) {
      print('Error checking user wants: $e');
      return false;
    }
  }

  // Check if user has completed the needs step
  Future<bool> hasCompletedNeeds(String userId) async {
    try {
      final user = await getUser(userId);
      return user?.needs != null;
    } catch (e) {
      print('Error checking user needs: $e');
      return false;
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
      final nameQuerySnapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where(
            'name',
            isLessThanOrEqualTo: '$query\uf8ff',
          ) // Unicode trick for prefix search
          .limit(10)
          .get();

      // Search by email
      final emailQuerySnapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: '$query\uf8ff')
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

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);
  }

  // Check if a user is online (placeholder implementation - would need a real presence system)
  bool isUserOnline(String userId) {
    // In a real app, this would check against a presence system
    // For now, we'll just return a placeholder value
    // You would typically use a system that tracks user activity timestamps
    // or uses a real-time presence system like Firebase Realtime Database

    // For demonstration purposes only
    return userId.isNotEmpty; // Consider all valid users as online
  }

  // Get all registered users with pagination and filtering
  Future<List<UserModel>> getAllUsers({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    bool excludeCurrentUser = true,
    bool excludeSystemBots = true,
  }) async {
    try {
      print('getAllUsers called with:');
      print('  limit: $limit');
      print('  searchQuery: $searchQuery');
      print('  excludeCurrentUser: $excludeCurrentUser');
      print('  excludeSystemBots: $excludeSystemBots');
      print('  currentUserId: $currentUserId');

      Query query = _firestore.collection('users');

      // For now, use simpler queries to avoid index issues
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Search by name (case-insensitive prefix search)
        final searchLower = searchQuery.toLowerCase();
        query = query
            .where('name', isGreaterThanOrEqualTo: searchLower)
            .where('name', isLessThanOrEqualTo: '$searchLower\uf8ff');
        print('  Added search filter for: $searchLower');
      } else {
        // Only add ordering if not searching to avoid index issues
        query = query.orderBy('createdAt', descending: true);
        print('  Added orderBy: createdAt desc');
      }

      // Add pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
        print('  Added pagination: startAfter ${lastDocument.id}');
      }

      // Limit results
      query = query.limit(limit * 2); // Get more to account for filtering
      print('  Added limit: ${limit * 2}');

      print('  Executing query...');
      final querySnapshot = await query.get();
      print('  Query returned ${querySnapshot.docs.length} documents');

      final allUsers = querySnapshot.docs
          .map((doc) {
            try {
              final user = UserModel.fromFirestore(doc);
              print(
                  '  Parsed user: ${user.id} - ${user.name} (isSystemBot: ${user.isSystemBot})');
              return user;
            } catch (e) {
              print('  Error parsing user ${doc.id}: $e');
              return null;
            }
          })
          .where((user) => user != null)
          .cast<UserModel>()
          .toList();

      print('  Successfully parsed ${allUsers.length} users');

      // Filter manually
      var filteredUsers = allUsers;

      // Exclude system bots if requested
      if (excludeSystemBots) {
        final beforeCount = filteredUsers.length;
        filteredUsers =
            filteredUsers.where((user) => !user.isSystemBot).toList();
        final afterCount = filteredUsers.length;
        print('  Excluded system bots: $beforeCount -> $afterCount users');
      }

      // Exclude current user if requested
      if (excludeCurrentUser && currentUserId != null) {
        final beforeCount = filteredUsers.length;
        filteredUsers =
            filteredUsers.where((user) => user.id != currentUserId).toList();
        final afterCount = filteredUsers.length;
        print('  Excluded current user: $beforeCount -> $afterCount users');
      }

      // Apply limit after filtering
      if (filteredUsers.length > limit) {
        filteredUsers = filteredUsers.take(limit).toList();
        print('  Applied limit: ${filteredUsers.length} users');
      }

      print('  Final result: ${filteredUsers.length} users');
      for (final user in filteredUsers) {
        print('    - ${user.id}: ${user.name} (${user.email})');
      }

      return filteredUsers;
    } catch (e, stackTrace) {
      print('Error getting all users: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Get all registered users as a stream
  Stream<List<UserModel>> getAllUsersStream({
    int limit = 50,
    String? searchQuery,
    bool excludeCurrentUser = true,
    bool excludeSystemBots = true,
  }) {
    try {
      Query query = _firestore.collection('users');

      // Exclude system bots if requested
      if (excludeSystemBots) {
        query = query.where('isSystemBot', isEqualTo: false);
      }

      // Add search functionality if query is provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        query = query
            .where('name', isGreaterThanOrEqualTo: searchLower)
            .where('name', isLessThanOrEqualTo: '$searchLower\uf8ff');
      }

      // Order by creation date (newest first)
      query = query.orderBy('createdAt', descending: true);

      // Limit results
      query = query.limit(limit);

      return query.snapshots().map((snapshot) {
        final users =
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

        // Exclude current user if requested
        if (excludeCurrentUser && currentUserId != null) {
          users.removeWhere((user) => user.id == currentUserId);
        }

        return users;
      });
    } catch (e) {
      print('Error getting users stream: $e');
      return Stream.value([]);
    }
  }

  // Get user count statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      print('getUserStatistics called');

      // Get total users (excluding system bots) - use simpler query
      print('  Querying total users...');
      final totalUsersQuery = await _firestore.collection('users').get();

      // Filter out system bots manually
      final totalUsers = totalUsersQuery.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return data != null && (data['isSystemBot'] ?? false) == false;
      }).toList();

      print(
          '  Total users query returned: ${totalUsers.length} documents (after filtering)');

      // Calculate today and week counts manually
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay =
          DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      int todayCount = 0;
      int weekCount = 0;

      for (var doc in totalUsers) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final createdAt = data['createdAt'] as Timestamp?;
          if (createdAt != null) {
            final createdDate = createdAt.toDate();
            if (createdDate.isAfter(startOfDay)) {
              todayCount++;
            }
            if (createdDate.isAfter(startOfWeekDay)) {
              weekCount++;
            }
          }
        }
      }

      print('  Today count: $todayCount');
      print('  Week count: $weekCount');

      final stats = {
        'total': totalUsers.length,
        'today': todayCount,
        'thisWeek': weekCount,
      };

      print('  Final statistics: $stats');
      return stats;
    } catch (e, stackTrace) {
      print('Error getting user statistics: $e');
      print('Stack trace: $stackTrace');
      return {
        'total': 0,
        'today': 0,
        'thisWeek': 0,
      };
    }
  }
}
