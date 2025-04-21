import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';

class ChatInviteDialog extends StatefulWidget {
  final String roomId;
  final String roomName;

  const ChatInviteDialog({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  // Static method to show the dialog
  static Future<void> show({
    required BuildContext context,
    required String roomId,
    required String roomName,
  }) async {
    return showDialog(
      context: context,
      builder:
          (context) => ChatInviteDialog(roomId: roomId, roomName: roomName),
    );
  }

  @override
  State<ChatInviteDialog> createState() => _ChatInviteDialogState();
}

class _ChatInviteDialogState extends State<ChatInviteDialog> {
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  final Set<String> _selectedUserIds = {};
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _isSearching = query.isNotEmpty;
    });

    if (query.length >= 3) {
      _searchUsers(query);
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _userService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _inviteSelectedUsers() async {
    if (_selectedUserIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _chatService.inviteUsersToChatRoom(
        roomId: widget.roomId,
        userIds: _selectedUserIds.toList(),
      );

      if (success && mounted) {
        Navigator.pop(context); // Close dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedUserIds.length} ${_selectedUserIds.length == 1 ? 'user' : 'users'} invited successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send invitations'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().split(': ').last}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Invite to "${widget.roomName}"',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users to invite...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedUserIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_selectedUserIds.length} ${_selectedUserIds.length == 1 ? 'user' : 'users'} selected',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Expanded(child: _buildUserList()),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      _selectedUserIds.isEmpty || _isLoading
                          ? null
                          : _inviteSelectedUsers,
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text('INVITE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoading && _searchResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          _isSearching ? 'No users found' : 'Search for users to invite',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final isSelected = _selectedUserIds.contains(user.id);

        return ListTile(
          title: Text(user.name),
          subtitle: Text(user.email ?? ''),
          leading: CircleAvatar(
            child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
          ),
          trailing: Checkbox(
            value: isSelected,
            onChanged: (value) => _toggleUserSelection(user.id),
          ),
          onTap: () => _toggleUserSelection(user.id),
        );
      },
    );
  }
}
