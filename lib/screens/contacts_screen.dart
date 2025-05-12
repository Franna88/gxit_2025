import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/contact_item.dart';
import '../widgets/contact_group_header.dart';
import '../models/contact.dart';
import 'chat_screen.dart';
import 'contact_invitation_screen.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../models/contact_model.dart';
import '../services/user_service.dart';
import '../services/contacts_service.dart';
import '../widgets/not_enough_tokens_dialog.dart';
import '../models/chat_room.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with SingleTickerProviderStateMixin {
  // Filtered contacts list
  List<Map<String, dynamic>> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isSearchingUsers = false;
  List<UserModel> _searchResults = [];

  // Animation for status glow effects
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Contact groups
  final Map<String, List<ContactModel>> _contactGroups = {
    'Favorites': [],
    'Trading': [],
    'Analysts': [],
    'Team': [],
    'Other': [],
  };

  // All contacts in a flat list for searching
  List<Map<String, dynamic>> _allContacts = [];

  late UserService _userService;
  late ContactsService _contactsService;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Initialize pulse animation for status indicators
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _userService = UserService();
    _contactsService = ContactsService();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _filteredContacts =
            _allContacts
                .where(
                  (contact) => contact['name'].toLowerCase().contains(query),
                )
                .toList();
      }
    });

    // If the query is 3 or more characters, search for users in Firestore
    if (query.length >= 3) {
      // Debounce to avoid too many requests
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_searchController.text.trim() == query) {
          _performSearch(query);
        }
      });
    } else {
      setState(() {
        _isSearchingUsers = false;
        _searchResults = [];
      });
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _isSearchingUsers = query.isNotEmpty;
    });

    if (query.isNotEmpty) {
      _searchUsersInFirestore(query);
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  Future<void> _searchUsersInFirestore(String query) async {
    final results = await _userService.searchUsers(query);
    setState(() {
      _searchResults = results;
    });
  }

  Future<void> _loadContacts() async {
    // Load contacts for each group
    for (final group in _contactGroups.keys) {
      _contactsService.getContactsByGroup(group).listen((contacts) {
        setState(() {
          _contactGroups[group] = contacts;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Only filter contacts if we're not searching for users
    final List<ContactModel> filteredContacts =
        !_isSearchingUsers ? _getFilteredContacts() : [];

    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search contacts or find users...',
                    hintStyle: TextStyle(
                      color:
                          isDarkMode
                              ? AppColors.subtleText
                              : Colors.grey.shade600,
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : AppColors.darkText,
                  ),
                  onSubmitted: _performSearch,
                )
                : const Text(
                  'Contacts',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        leading:
            _isSearching
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                    });
                  },
                )
                : null,
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            // Add Contact button
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Add Contact',
              onPressed: () {
                _showAddContactDialog(context);
              },
            ),
            // Invite Friends button
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Invite Friends',
              onPressed: () {
                _navigateToInviteFriends(context);
              },
            ),
            // More options menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'createGroup') {
                  _showCreateGroupDialog(context);
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'createGroup',
                      child: Row(
                        children: [
                          Icon(Icons.group_add, size: 20),
                          SizedBox(width: 8),
                          Text('Create Group'),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ],
        backgroundColor:
            isDarkMode ? AppColors.darkBackground : Colors.grey.shade100,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDarkMode ? AppColors.darkBackground : Colors.grey.shade100,
              isDarkMode
                  ? AppColors.darkBackground.withOpacity(0.9)
                  : Colors.white,
            ],
          ),
        ),
        child:
            _isSearchingUsers
                ? _buildUserSearchResults()
                : (_isSearching
                    ? _buildSearchResults()
                    : _buildGroupedContacts()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddContactDialog(context);
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildSearchResults() {
    return _filteredContacts.isEmpty
        ? Center(
          child: Text(
            'No matching contacts found',
            style: TextStyle(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.subtleText
                      : Colors.grey.shade600,
            ),
          ),
        )
        : ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          itemCount: _filteredContacts.length,
          itemBuilder: (context, index) {
            final contact = _filteredContacts[index];
            final messageType = contact['messageType'] as String?;
            return ContactItem(
              contact: Contact(
                id: index.toString(),
                name: contact['name'],
                address: "",
                isFavorite: false,
              ),
              status: contact['status'] as ContactStatus,
              messageType: messageType,
              onTap: () => _navigateToChat(context, contact['name']),
            );
          },
        );
  }

  Widget _buildGroupedContacts() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          itemCount: _contactGroups.length,
          itemBuilder: (context, index) {
            final groupName = _contactGroups.keys.elementAt(index);
            final contactsInGroup = _contactGroups[groupName]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ContactGroupHeader(
                  title: groupName,
                  count: contactsInGroup.length,
                ),
                ...contactsInGroup.map((contact) {
                  return ContactItem(
                    contact: Contact(
                      id: contact.id,
                      name: contact.name,
                      address: contact.address,
                      isFavorite: groupName == 'Favorites',
                    ),
                    status: contact.status,
                    messageType: contact.messageType,
                    onTap: () => _navigateToChat(context, contact.name),
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToChat(BuildContext context, String contactName) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // First try to find a real user with this name
      final userService = UserService();
      final users = await userService.searchUsers(contactName);

      // Get current user
      final currentUser = await userService.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to start a chat');
      }

      // Initialize chat service
      final chatService = ChatService();
      String? chatRoomId;

      if (users.isNotEmpty) {
        // We found a real user, create or find a private chat with them
        chatRoomId = await chatService.findOrCreatePrivateChatRoom(
          otherUserId: users.first.id,
          otherUserName: users.first.name,
        );
      } else {
        // Check if user has enough tokens for creating a room
        final tokenBalance = await chatService.getUserTokenBalance();
        if (tokenBalance < ChatRoom.createRoomTokenCost) {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            NotEnoughTokensDialog.show(
              context: context,
              requiredTokens: ChatRoom.createRoomTokenCost,
              currentTokens: tokenBalance,
              onBuyTokens: () {
                // Handle token purchase (implement this later)
              },
            );
          }
          return;
        }

        // No real user found, create a private chat room with the contact
        chatRoomId = await chatService.createChatRoom(
          name: contactName,
          memberIds: [currentUser.id],
          isPublic: false,
        );
      }
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (chatRoomId != null && mounted) {
        // Show a success message for creating a new chat
        if (users.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created new chat with $contactName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        // Navigate to chat screen with the room ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              contactName: contactName,
              chatRoomId: chatRoomId!,
            ),
          ),
        );
      } else if (mounted) {
        // If we couldn't create a chat room, create a demo one instead
        final demoRoomId = "demoRoom";
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using demo mode for this chat'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              contactName: contactName,
              chatRoomId: demoRoomId,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if error occurs
      if (mounted) {
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().split(': ').last}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddContactDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    String selectedGroup = 'Other';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Add New Contact'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedGroup,
                        decoration: const InputDecoration(
                          labelText: 'Group',
                          prefixIcon: Icon(Icons.group_outlined),
                        ),
                        items:
                            _contactGroups.keys.map((group) {
                              return DropdownMenuItem<String>(
                                value: group,
                                child: Text(group),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedGroup = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          _addContact(name, selectedGroup);
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('ADD'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final TextEditingController groupNameController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New Group'),
            content: TextField(
              controller: groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                prefixIcon: Icon(Icons.group_outlined),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  final groupName = groupNameController.text.trim();
                  if (groupName.isNotEmpty &&
                      !_contactGroups.containsKey(groupName)) {
                    setState(() {
                      _contactGroups[groupName] = [];
                    });
                  }
                  Navigator.pop(context);
                },
                child: const Text('CREATE'),
              ),
            ],
          ),
    );
  }

  void _addContact(String name, String group) async {
    try {
      // Create a new contact model
      final contact = ContactModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        address: "",
        status: ContactStatus.offline,
      );

      // Save to Firebase
      await _contactsService.saveContact(contact, group);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding contact: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToInviteFriends(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ContactInvitationScreen()),
    );
  }

  List<ContactModel> _getFilteredContacts() {
    final contacts = [
      ContactModel(
        id: '1',
        name: 'Alice Johnson',
        address: 'address1',
        phone: '+1 234 567 890',
      ),
      ContactModel(
        id: '2',
        name: 'Bob Smith',
        address: 'address2',
        phone: '+1 345 678 901',
      ),
      ContactModel(
        id: '3',
        name: 'Charlie Brown',
        address: 'address3',
        phone: '+1 456 789 012',
      ),
      ContactModel(
        id: '4',
        name: 'David Miller',
        address: 'address4',
        phone: '+1 567 890 123',
      ),
      ContactModel(
        id: '5',
        name: 'Eve Davis',
        address: 'address5',
        phone: '+1 678 901 234',
      ),
    ];

    if (_searchQuery.isEmpty) {
      return contacts;
    }

    return contacts.where((contact) {
      return contact.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (contact.phone != null && contact.phone!.contains(_searchQuery));
    }).toList();
  }

  Widget _buildUserSearchResults() {
    return _searchResults.isEmpty
        ? Center(
          child: Text(
            'No matching users found',
            style: TextStyle(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.subtleText
                      : Colors.grey.shade600,
            ),
          ),
        )
        : ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final user = _searchResults[index];
            return ContactItem(
              contact: Contact(
                id: user.id,
                name: user.name,
                address: user.email ?? "",
                isFavorite: false,
              ),
              status: ContactStatus.online,
              messageType: null,
              onTap: () => _navigateToChat(context, user.name),
            );
          },
        );
  }
}
