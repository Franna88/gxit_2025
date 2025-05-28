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
import '../models/chat_invitation.dart';

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
    'Chat Invites': [],
    'Active Chats': [],
  };

  // All contacts in a flat list for searching
  List<Map<String, dynamic>> _allContacts = [];

  late UserService _userService;
  late ContactsService _contactsService;
  late ChatService _chatService;

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
    _chatService = ChatService();
    _loadContacts();
    _loadChatInvitations();
    _loadDirectMessageChats();
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
      if (group != 'Chat Invites') { // Skip Chat Invites as we'll handle them separately
        _contactsService.getContactsByGroup(group).listen((contacts) {
          setState(() {
            _contactGroups[group] = contacts;
          });
        });
      }
    }
  }

  // Load chat invitations from ChatService
  void _loadChatInvitations() {
    _chatService.getChatInvitations().listen((invitations) async {
      final List<ContactModel> inviteContacts = [];
      
      for (var invite in invitations) {
        // Get inviter's information
        final inviter = await _userService.getUser(invite.inviterId);
        final inviterName = inviter?.name ?? 'Unknown User';
        
        inviteContacts.add(ContactModel(
          id: invite.id,
          name: "Chat with $inviterName",
          address: "Invitation to join \"${invite.roomName}\"",
          status: ContactStatus.online,
          messageType: "Invitation",
        ));
      }
      
      if (mounted) {
        setState(() {
          _contactGroups['Chat Invites'] = inviteContacts;
        });
      }
    });
  }

  // Load direct message chats into Active Chats section
  void _loadDirectMessageChats() {
    final userId = _chatService.currentUserId;
    if (userId == null) return;
    
    _chatService.getDirectMessageChatsStream(userId).listen((chats) {
      final directMessageContacts = chats.map((chat) {
        // For direct messages, we want to show the other user's name, NOT the room name
        String displayName = "Chat Contact"; // Default fallback
        
        // If we have participant IDs, try to get other user's name
        if (chat.participantIds != null && chat.participantIds!.length == 2) {
          // Filter out current user ID to get other participant
          final otherUserId = chat.participantIds!.firstWhere(
            (id) => id != userId,
            orElse: () => '', // Fallback if somehow we don't find another user
          );
          
          if (otherUserId.isNotEmpty) {
            _userService.getUser(otherUserId).then((otherUser) {
              if (otherUser != null && mounted) {
                // Update contact with real name if we have it
                setState(() {
                  final index = _contactGroups['Active Chats']?.indexWhere(
                    (contact) => contact.id == chat.id
                  ) ?? -1;
                  
                  if (index >= 0) {
                    _contactGroups['Active Chats']![index] = ContactModel(
                      id: chat.id,
                      name: otherUser.name, // Always use the other user's name
                      address: chat.lastMessage ?? "Start chatting now",
                      status: _userService.isUserOnline(otherUserId) 
                          ? ContactStatus.online 
                          : ContactStatus.offline,
                      messageType: "Direct Message",
                      chatRoomId: chat.id,
                    );
                  }
                });
              }
            });
          }
        } else if (chat.memberIds.length == 2) {
          // Fallback to memberIds if participantIds is not available
          final otherUserId = chat.memberIds.firstWhere(
            (id) => id != userId,
            orElse: () => '', // Fallback if somehow we don't find another user
          );
          
          if (otherUserId.isNotEmpty) {
            _userService.getUser(otherUserId).then((otherUser) {
              if (otherUser != null && mounted) {
                // Update contact with real name if we have it
                setState(() {
                  final index = _contactGroups['Active Chats']?.indexWhere(
                    (contact) => contact.id == chat.id
                  ) ?? -1;
                  
                  if (index >= 0) {
                    _contactGroups['Active Chats']![index] = ContactModel(
                      id: chat.id,
                      name: otherUser.name, // Always use the other user's name
                      address: chat.lastMessage ?? "Start chatting now",
                      status: _userService.isUserOnline(otherUserId) 
                          ? ContactStatus.online 
                          : ContactStatus.offline,
                      messageType: "Direct Message",
                      chatRoomId: chat.id,
                    );
                  }
                });
              }
            });
          }
        } else {
          // Fallback: if we don't have participant IDs, try to extract from room name
          // Remove "Chat with " prefix if it exists and it's not the current user's name
          if (chat.name.startsWith('Chat with ')) {
            final nameFromRoom = chat.name.substring('Chat with '.length);
            // Only use this if it's not empty and we can't get participant info
            if (nameFromRoom.isNotEmpty) {
              displayName = nameFromRoom;
            }
          } else if (chat.name.isNotEmpty && 
                     chat.name.toLowerCase() != "new people" && 
                     chat.name.trim().isNotEmpty) {
            displayName = chat.name;
          }
        }
        
        return ContactModel(
          id: chat.id,
          name: displayName,
          address: chat.lastMessage ?? "Start chatting now",
          status: ContactStatus.online,
          messageType: "Direct Message",
          chatRoomId: chat.id,
        );
      }).toList();
      
      setState(() {
        // Merge with existing contacts in Active Chats
        final existingContacts = _contactGroups['Active Chats'] ?? [];
        
        // Filter out existing direct message contacts (to avoid duplicates)
        final nonDirectMessageContacts = existingContacts
            .where((contact) => contact.messageType != "Direct Message")
            .toList();
        
        // Add direct message contacts
        _contactGroups['Active Chats'] = [...nonDirectMessageContacts, ...directMessageContacts];
      });
    });
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
                  'Chats',
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
                      isFavorite: groupName == 'Chat Invites',
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
      // Check if it's a chat invitation
      final invitationGroup = _contactGroups['Chat Invites'];
      final isInvitation = invitationGroup?.any((contact) => contact.name == contactName) ?? false;
      
      if (isInvitation) {
        // It's a chat invitation, show accept/decline dialog
        final invitation = invitationGroup!.firstWhere((contact) => contact.name == contactName);
        _showInvitationDialog(context, invitation);
        return;
      }
      
      // Check if it's an existing direct message chat in Active Chats
      final activeChatsGroup = _contactGroups['Active Chats'];
      final existingContact = activeChatsGroup?.firstWhere(
        (contact) => contact.name == contactName && contact.chatRoomId != null,
        orElse: () => ContactModel(id: '', name: '', address: ''),
      );
      
      // If we have an existing chat room ID, navigate directly to that chat
      if (existingContact != null && existingContact.chatRoomId != null) {
        // Use pushReplacement to avoid back button issues
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              contactName: contactName,
              chatRoomId: existingContact.chatRoomId!,
            ),
          ),
        );
        return;
      }
      
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

      // Check if we are handling a user from search results
      bool isFromSearchResults = false;
      UserModel? selectedUser;
      
      // Check if this is a user from search results
      if (_isSearchingUsers && _searchResults.isNotEmpty) {
        // Look for a user with matching name in search results
        for (final user in _searchResults) {
          if (user.name == contactName) {
            selectedUser = user;
            isFromSearchResults = true;
            break;
          }
        }
      }

      // Close loading indicator
      Navigator.of(context, rootNavigator: true).pop();

      if (isFromSearchResults && selectedUser != null) {
        // This is a user from search results, create a new direct message room and invitation
        final roomName = 'Chat with ${selectedUser.name}';
        
        // Check if we have enough tokens first
        final tokenBalance = await chatService.getUserTokenBalance();
        if (tokenBalance < ChatRoom.createRoomTokenCost) {
          if (mounted) {
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
        
        // Create the room and invitation
        try {
          // Create a new chat room for direct messaging
          chatRoomId = await chatService.createChatRoom(
            name: roomName,
            memberIds: [currentUser.id],
            isPublic: false, // Direct messages are always private (not public)
            isDirectMessage: true, // This marks it as a direct message (1-on-1 chat)
          );
          
          if (chatRoomId != null) {
            // Create invitation for the selected user
            await chatService.inviteUsersToChatRoom(
              roomId: chatRoomId,
              userIds: [selectedUser.id],
            );
            
            // Show success message and navigate to the chat
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Invitation sent to ${selectedUser.name}'),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Navigate to the new chat room
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    contactName: selectedUser!.name,
                    chatRoomId: chatRoomId!,
                  ),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            String errorMessage = e.toString();
            if (errorMessage.contains('invitation is already pending')) {
              errorMessage = 'An invitation has already been sent to this user';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage.split('Exception: ').last),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        return;
      }

      // If we get here, we're dealing with a contact that's not from search results
      // Proceed with regular contact handling (existing code)
      
      if (users.isNotEmpty) {
        // If there are multiple users with the same name, use the first one
        final user = users.first;
        
        // Create a direct message room name
        final roomName = 'Chat with ${user.name}';
        
        // Check if we have enough tokens
        final tokenBalance = await chatService.getUserTokenBalance();
        if (tokenBalance < ChatRoom.createRoomTokenCost) {
          if (mounted) {
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
        
        // Create a room and send invitation
        chatRoomId = await chatService.createChatRoom(
          name: roomName,
          memberIds: [currentUser.id],
          isPublic: false, // Direct messages are always private (not public)
          isDirectMessage: true, // This marks it as a direct message (1-on-1 chat)
        );
        
        if (chatRoomId != null) {
          // Invite the user to this room
          await chatService.inviteUsersToChatRoom(
            roomId: chatRoomId,
            userIds: [user.id],
          );
        }
      } else {
        // No real user found, create a placeholder contact
        // This would be replaced with a real implementation that handles
        // invitations to users who aren't on the platform yet
        chatRoomId = await chatService.createChatRoom(
          name: contactName,
          memberIds: [currentUser.id],
          isPublic: false,
          isDirectMessage: true, // Explicitly mark as a direct message
        );
      }
      
      if (chatRoomId != null) {
        // Save this as a contact
        final contact = ContactModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: contactName,
          address: "",
          status: ContactStatus.offline,
          chatRoomId: chatRoomId,
        );
        
        await _contactsService.saveContact(contact, 'Active Chats');
        
        // Navigate to the chat
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                contactName: contactName,
                chatRoomId: chatRoomId!,
              ),
            ),
          );
        }
      }

      if (mounted) {
        // Close loading indicator if still showing
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      // Close loading indicator if showing
      Navigator.of(context, rootNavigator: true).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().split(': ').last}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show dialog to accept or decline chat invitation
  void _showInvitationDialog(BuildContext context, ContactModel invitation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chat Invitation: ${invitation.name}'),
        content: const Text('Would you like to accept this chat invitation?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleInvitationResponse(invitation.id, false);
            },
            child: const Text('DECLINE', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleInvitationResponse(invitation.id, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('ACCEPT'),
          ),
        ],
      ),
    );
  }

  // Handle accepting or declining an invitation
  Future<void> _handleInvitationResponse(String invitationId, bool accept) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      bool success = false;
      String? chatRoomId;
      String roomName = '';
      String inviterId = '';

      if (accept) {
        // Get invitation details before accepting (for chat navigation)
        print("Fetching invitation details for ID: $invitationId");
        final invitation = await _chatService.getChatInvitationById(invitationId);
        
        if (invitation == null) {
          print("Error: Invitation not found with ID: $invitationId");
          throw Exception('Invitation not found');
        }
        
        print("Invitation found: roomId=${invitation.roomId}, roomName=${invitation.roomName}");
        roomName = invitation.roomName;
        chatRoomId = invitation.roomId;
        inviterId = invitation.inviterId;
        
        // Accept the invitation
        print("Accepting invitation: $invitationId");
        success = await _chatService.acceptChatInvitation(invitationId);
        print("Invitation acceptance result: $success");
        
        // If successful, add the chat to Active Chats
        if (success && chatRoomId != null && roomName.isNotEmpty) {
          // Get user info if possible for direct messages
          String displayName = roomName;
          ContactStatus status = ContactStatus.offline;
          
          // For direct messages, try to get the other user's information
          if (invitation.isDirectMessage) {
            try {
              print("Getting user info for inviter: $inviterId");
              final otherUser = await _userService.getUser(inviterId);
              if (otherUser != null) {
                displayName = otherUser.name;
                status = _userService.isUserOnline(inviterId) 
                    ? ContactStatus.online 
                    : ContactStatus.offline;
                print("Found user info: ${otherUser.name}");
              } else {
                print("Warning: User info not found for $inviterId, using room name instead");
              }
            } catch (e) {
              print('Error getting user info: $e');
              // Continue with room name as fallback
            }
          }
          
          try {
            // Create contact model
            final contact = ContactModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: displayName,
              address: "New conversation",
              status: status,
              messageType: invitation.isDirectMessage ? "Direct Message" : "Group Chat",
              chatRoomId: chatRoomId,
            );
            
            // Save to Contact service
            print("Saving contact to Active Chats");
            await _contactsService.saveContact(contact, 'Active Chats');
            print("Contact saved successfully");
          } catch (e) {
            print('Error saving contact: $e');
            // We'll still try to navigate to the chat even if saving the contact fails
          }
        }
      } else {
        // Decline the invitation
        success = await _chatService.declineChatInvitation(invitationId);
      }

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Invitation accepted' : 'Invitation declined'),
            backgroundColor: accept ? Colors.green : Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );

        // If accepted, navigate to the chat
        if (accept && chatRoomId != null && roomName.isNotEmpty) {
          print("Navigating to chat: $roomName, $chatRoomId");
          // Use pushReplacement to avoid back button issues
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                contactName: roomName,
                chatRoomId: chatRoomId!,
              ),
            ),
          );
        }
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Failed to accept invitation' : 'Failed to decline invitation'),
            backgroundColor: Colors.red,
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
    String selectedGroup = 'Active Chats';

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
