import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebugUsersScreen extends StatefulWidget {
  const DebugUsersScreen({super.key});

  @override
  State<DebugUsersScreen> createState() => _DebugUsersScreenState();
}

class _DebugUsersScreenState extends State<DebugUsersScreen> {
  List<Map<String, dynamic>> _allDocuments = [];
  List<Map<String, dynamic>> _filteredDocuments = [];
  bool _isLoading = true;
  String _error = '';
  Map<String, int> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadDebugData();
  }

  Future<void> _loadDebugData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      print('Starting debug data load...');
      
      // Check Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      print('Current user: ${currentUser?.uid} (${currentUser?.email})');

      // Get ALL documents from users collection (no filters)
      final allUsersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      print('Total documents in users collection: ${allUsersSnapshot.docs.length}');

      final allDocs = allUsersSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Get filtered documents (excluding system bots)
      final filteredSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isSystemBot', isEqualTo: false)
          .get();
      
      print('Filtered documents (excluding system bots): ${filteredSnapshot.docs.length}');

      final filteredDocs = filteredSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Calculate statistics
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      int todayCount = 0;
      int weekCount = 0;

      for (var doc in filteredDocs) {
        final createdAt = doc['createdAt'] as Timestamp?;
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

      setState(() {
        _allDocuments = allDocs;
        _filteredDocuments = filteredDocs;
        _statistics = {
          'total': filteredDocs.length,
          'today': todayCount,
          'thisWeek': weekCount,
        };
        _isLoading = false;
      });

      print('Debug data loaded successfully');
    } catch (e, stackTrace) {
      print('Error loading debug data: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestUsers() async {
    try {
      print('Creating test users...');
      
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      
      // Create 3 test users
      final testUsers = [
        {
          'name': 'Alice Johnson',
          'email': 'alice@example.com',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'tokens': 500,
          'isSystemBot': false,
        },
        {
          'name': 'Bob Smith',
          'email': 'bob@example.com',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'tokens': 500,
          'isSystemBot': false,
        },
        {
          'name': 'Charlie Brown',
          'email': 'charlie@example.com',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'tokens': 500,
          'isSystemBot': false,
        },
      ];
      
      for (int i = 0; i < testUsers.length; i++) {
        final docRef = firestore.collection('users').doc('test_user_$i');
        batch.set(docRef, testUsers[i]);
      }
      
      await batch.commit();
      print('Test users created successfully');
      
      // Reload data
      _loadDebugData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test users created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error creating test users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating test users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Users'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createTestUsers,
            tooltip: 'Create Test Users',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugData,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $_error',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDebugData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics
                      Card(
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Statistics',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Total Users: ${_statistics['total']}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                'Today: ${_statistics['today']}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                'This Week: ${_statistics['thisWeek']}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // All Documents
                      Card(
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All Documents (${_allDocuments.length})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._allDocuments.map((doc) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ID: ${doc['id']}',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Name: ${doc['name'] ?? 'N/A'}',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          Text(
                                            'Email: ${doc['email'] ?? 'N/A'}',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          Text(
                                            'System Bot: ${doc['isSystemBot'] ?? false}',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          if (doc['createdAt'] != null)
                                            Text(
                                              'Created: ${(doc['createdAt'] as Timestamp).toDate()}',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                        ],
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Filtered Documents
                      Card(
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filtered Documents (${_filteredDocuments.length})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_filteredDocuments.isEmpty)
                                const Text(
                                  'No filtered documents found',
                                  style: TextStyle(color: Colors.orange),
                                )
                              else
                                ..._filteredDocuments.map((doc) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'ID: ${doc['id']}',
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Name: ${doc['name'] ?? 'N/A'}',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                            Text(
                                              'Email: ${doc['email'] ?? 'N/A'}',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                            if (doc['createdAt'] != null)
                                              Text(
                                                'Created: ${(doc['createdAt'] as Timestamp).toDate()}',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                          ],
                                        ),
                                      ),
                                    )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
} 