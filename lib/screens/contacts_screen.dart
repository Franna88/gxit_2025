import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/contact_item.dart';
import '../widgets/contact_group_header.dart';
import '../models/contact.dart';
import 'chat_screen.dart';
import 'contact_invitation_screen.dart';

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

  // Animation for status glow effects
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Predefined contact groups
  final Map<String, List<Map<String, dynamic>>> _contactGroups = {
    'Favorites': [
      {
        'name': 'JoeBanker',
        'status': ContactStatus.online,
        'messageType': 'Urgent',
      },
      {'name': 'TradePost', 'status': ContactStatus.online},
    ],
    'Trading': [
      {
        'name': 'Alex Trader',
        'status': ContactStatus.online,
        'messageType': 'New Message',
      },
      {'name': 'Sam Markets', 'status': ContactStatus.away},
      {
        'name': 'Jamie Forex',
        'status': ContactStatus.offline,
        'messageType': 'Question',
      },
    ],
    'Analysts': [
      {'name': 'Rachel Finance', 'status': ContactStatus.online},
      {'name': 'Mike Analyst', 'status': ContactStatus.offline},
    ],
    'Team': [
      {
        'name': 'Lisa Manager',
        'status': ContactStatus.online,
        'messageType': 'Follow-up',
      },
      {'name': 'John Dev', 'status': ContactStatus.away},
      {'name': 'Sarah Design', 'status': ContactStatus.offline},
    ],
    'Other': [
      {'name': 'Info', 'status': ContactStatus.online},
      {'name': 'Gallery', 'status': ContactStatus.online},
      {
        'name': 'Support',
        'status': ContactStatus.online,
        'messageType': 'Urgent',
      },
    ],
  };

  // All contacts in a flat list for searching
  List<Map<String, dynamic>> _allContacts = [];

  @override
  void initState() {
    super.initState();
    // Flatten contacts for search functionality
    for (var group in _contactGroups.values) {
      _allContacts.addAll(group);
    }
    _searchController.addListener(_onSearchChanged);

    // Initialize pulse animation for status indicators
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
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
        child: _isSearching ? _buildSearchResults() : _buildGroupedContacts(),
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
                  final isOnline = contact['status'] == ContactStatus.online;
                  final messageType = contact['messageType'] as String?;
                  return ContactItem(
                    contact: Contact(
                      id: contact['name'],
                      name: contact['name'],
                      address: "",
                      isFavorite: groupName == 'Favorites',
                    ),
                    status: contact['status'] as ContactStatus,
                    messageType: messageType,
                    onTap: () => _navigateToChat(context, contact['name']),
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

  void _navigateToChat(BuildContext context, String contactName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatScreen(
              contactName: contactName,
              chatRoomId: 'demoRoom', // Use demo room for now
            ),
      ),
    );
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

  void _addContact(String name, String group) {
    setState(() {
      final newContact = {'name': name, 'status': ContactStatus.offline};
      _contactGroups[group]!.add(newContact);
      _allContacts.add(newContact);
    });
  }

  void _navigateToInviteFriends(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ContactInvitationScreen()),
    );
  }
}
