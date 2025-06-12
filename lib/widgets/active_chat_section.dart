import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import '../services/chat_service.dart';
import '../models/chat_room.dart';

class ActiveChatSection extends StatefulWidget {
  final Function(String) onChatTap;
  final Function(String, String)? onChatRoomTap;

  const ActiveChatSection({
    super.key,
    required this.onChatTap,
    this.onChatRoomTap,
  });

  @override
  State<ActiveChatSection> createState() => _ActiveChatSectionState();
}

class _ActiveChatSectionState extends State<ActiveChatSection> {
  final ChatService _chatService = ChatService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  // Cache the active chats to prevent flickering
  List<ChatRoom> _cachedActiveChats = [];
  bool _hasInitialData = false;

  // Cache for resolved display names to avoid repeated lookups
  final Map<String, String> _displayNameCache = {};

  // Public method to refresh data from parent
  Future<void> refresh() async {
    setState(() {
      _hasInitialData = false;
      _cachedActiveChats.clear();
      _displayNameCache.clear(); // Clear name cache when refreshing
    });
  }

  // Method to get the display name for a chat room
  Future<String> _getDisplayName(ChatRoom chatRoom) async {
    // Return cached name if available
    if (_displayNameCache.containsKey(chatRoom.id)) {
      return _displayNameCache[chatRoom.id]!;
    }

    String displayName;

    if (chatRoom.isDirectMessage && _userId != null) {
      // For direct messages, resolve the other participant's name
      displayName =
          await _chatService.resolveDirectMessageDisplayName(chatRoom, _userId);
    } else {
      // For group chats, use the room name as-is
      displayName = chatRoom.name.isNotEmpty ? chatRoom.name : 'Unnamed Chat';
    }

    // Cache the resolved name
    _displayNameCache[chatRoom.id] = displayName;
    return displayName;
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Chat List
          StreamBuilder<List<ChatRoom>>(
            key: ValueKey('active_chats_$_userId'),
            stream: _chatService.getUserChatRoomsStream(_userId),
            builder: (context, snapshot) {
              // Handle errors
              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[400],
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error loading chats',
                        style: TextStyle(
                          color: Colors.red[400],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please try again later',
                        style: TextStyle(
                          color: Colors.red[300],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Show loading only if we don't have cached data
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !_hasInitialData) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Process new data if available
              if (snapshot.hasData) {
                final chatRooms = snapshot.data!;

                // Filter to show all active chats:
                // 1. All direct messages (isDirectMessage = true)
                // 2. Public group chats with recent activity (last 7 days)
                // 3. Private group chats with recent activity (last 7 days) - these should appear here, not in Private Rooms
                final activeChats = chatRooms
                    .where((room) =>
                        !room.isClosed &&
                        (room.isDirectMessage || // Include all direct messages
                            (room
                                    .isPublic && // Only include PUBLIC group chats with recent activity
                                room.lastActivity != null &&
                                DateTime.now()
                                        .difference(room.lastActivity!)
                                        .inDays <
                                    7) // Include public group chats with recent activity
                        ))
                    .toList()
                  ..sort((a, b) {
                    final aTime = a.lastActivity ?? a.createdAt;
                    final bTime = b.lastActivity ?? b.createdAt;
                    return bTime.compareTo(aTime);
                  });

                // Update cache only if data has actually changed
                if (_shouldUpdateCache(activeChats)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _cachedActiveChats = activeChats;
                        _hasInitialData = true;
                      });
                    }
                  });
                }
              }

              // Use cached data for display to prevent flickering
              final displayChats = _cachedActiveChats;

              if (displayChats.isEmpty) {
                return _buildEmptyState();
              }

              return _buildChatList(displayChats);
            },
          ),
        ],
      ),
    );
  }

  // Check if we should update the cache (to prevent unnecessary rebuilds)
  bool _shouldUpdateCache(List<ChatRoom> newChats) {
    if (_cachedActiveChats.length != newChats.length) return true;

    for (int i = 0; i < newChats.length; i++) {
      final newChat = newChats[i];
      final cachedChat =
          _cachedActiveChats.length > i ? _cachedActiveChats[i] : null;

      if (cachedChat == null ||
          newChat.id != cachedChat.id ||
          newChat.lastMessage != cachedChat.lastMessage ||
          newChat.lastActivity != cachedChat.lastActivity ||
          newChat.memberCount != cachedChat.memberCount) {
        return true;
      }
    }

    return false;
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue.withOpacity(0.05),
            AppColors.primaryPurple.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Colors.white.withOpacity(0.3),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No active chats',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Direct messages and recently active public chats appear here.\nPrivate rooms are in the Private Rooms section.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(List<ChatRoom> activeChats) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue.withOpacity(0.1),
            AppColors.primaryPurple.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activeChats.length,
        separatorBuilder: (context, index) => _buildDivider(),
        itemBuilder: (context, index) {
          final chatRoom = activeChats[index];
          return _buildActiveChatTile(
            chatRoom,
            key: ValueKey('chat_tile_${chatRoom.id}'),
          );
        },
      ),
    );
  }

  Widget _buildActiveChatTile(
    ChatRoom chatRoom, {
    Key? key,
  }) {
    final lastActivity = chatRoom.lastActivity ?? chatRoom.createdAt;
    final isRecentlyActive =
        DateTime.now().difference(lastActivity).inMinutes < 30;

    return InkWell(
      key: key,
      onTap: () {
        // Use the new callback if available, otherwise fall back to the old one
        if (widget.onChatRoomTap != null) {
          widget.onChatRoomTap!(chatRoom.id, chatRoom.name);
        } else {
          widget.onChatTap(chatRoom.name);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Chat Avatar with Active Indicator
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryPurple,
                        AppColors.primaryBlue,
                      ],
                    ),
                  ),
                  child: Center(
                    child: chatRoom.isDirectMessage
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          )
                        : Text(
                            chatRoom.name.isNotEmpty
                                ? chatRoom.name[0].toUpperCase()
                                : 'C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (isRecentlyActive)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Chat Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<String>(
                          future: _getDisplayName(chatRoom),
                          builder: (context, snapshot) {
                            String displayText;
                            if (snapshot.hasData) {
                              displayText = snapshot.data!;
                            } else {
                              // Show loading state or fallback while resolving name
                              displayText = chatRoom.isDirectMessage
                                  ? (chatRoom.name.startsWith('Chat with ')
                                      ? chatRoom.name
                                          .substring('Chat with '.length)
                                          .trim()
                                      : 'Loading...')
                                  : (chatRoom.name.isNotEmpty
                                      ? chatRoom.name
                                      : 'Unnamed Chat');
                            }

                            return Text(
                              displayText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                      if (chatRoom.isDirectMessage)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'DM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (!chatRoom.isPublic)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Private',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Public',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chatRoom.lastMessage?.isNotEmpty == true
                        ? chatRoom.lastMessage!
                        : 'No messages yet',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Time and Member Count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getTimeString(lastActivity),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                if (chatRoom.memberCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          chatRoom.memberCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: 1,
      color: AppColors.primaryBlue.withOpacity(0.1),
    );
  }

  String _getTimeString(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
