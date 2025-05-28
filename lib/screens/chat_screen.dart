import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/user_mood.dart';
import '../services/chat_service.dart';
import '../constants.dart';
import '../widgets/message_bubble.dart';
import '../widgets/token_balance.dart';
import '../widgets/mood_selector.dart';
import '../widgets/not_enough_tokens_dialog.dart';
import '../widgets/chat_invite_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

// Define Message class for backward compatibility with MessageBubble
class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final MoodType? mood;
  final bool isMe;
  final List<String>? reactions;

  // Make constructor const for better caching
  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isMe,
    this.mood,
    this.reactions,
  });

  factory Message.fromChatMessage(ChatMessage chatMessage, String currentUserId, {String? otherParticipantName}) {
    final isCurrentUser = chatMessage.senderId == currentUserId;
    
    // For direct messages, use the other participant's name for non-current user messages
    String displayName;
    if (isCurrentUser) {
      displayName = 'You';
    } else if (otherParticipantName != null && otherParticipantName.isNotEmpty) {
      // Use the other participant's name for direct messages
      displayName = otherParticipantName;
    } else {
      // Fallback to the stored sender name
      displayName = chatMessage.senderName;
    }
    
    return Message(
      id: chatMessage.id,
      senderId: chatMessage.senderId,
      senderName: displayName,
      content: chatMessage.content,
      timestamp: chatMessage.timestamp,
      isMe: isCurrentUser,
      mood: chatMessage.mood,
      reactions: chatMessage.reactions,
    );
  }
  
  // Override equality to prevent unnecessary rebuilds
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.content == content &&
        other.isMe == isMe;
  }

  @override
  int get hashCode => Object.hash(id, content, isMe);
}

class ChatScreen extends StatefulWidget {
  final String contactName;
  final String chatRoomId;

  const ChatScreen({
    super.key,
    required this.contactName,
    required this.chatRoomId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  final ChatService _chatService = ChatService();
  bool _isLoading = true;
  bool _sendingMessage = false;
  String? _errorMessage;
  MoodType? _selectedMood;

  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Create a local map to store the latest message from each user
  final Map<String, ChatMessage> _latestUserMessages = {};

  // Cache for other participant's name in direct messages
  String? _otherParticipantName;

  @override
  void initState() {
    super.initState();
    
    // Load other participant's name for direct messages
    _loadOtherParticipantName();
    
    // First attempt to load from Firestore
    _loadInitialMessages();
    
    // Schedule a force refresh after a short delay to ensure all messages load
    // This is especially important for accounts with sync issues like Litha's
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _forceRefreshMessages();
      }
    });
    
    // Do another refresh after 3 seconds to catch any delayed messages
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _forceRefreshMessages();
      }
    });
    
    // Final refresh attempt to ensure we have all messages
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _forceRefreshMessages();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First try to get messages directly
      final initialMessages = await _chatService.getInitialMessages(
        widget.chatRoomId,
        30,
      );

      // Store any messages we receive to preserve them per user
      if (initialMessages.isNotEmpty) {
        _updateLatestUserMessages(initialMessages);
      }

      // Check if we got messages
      if (initialMessages.isNotEmpty) {
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(initialMessages);
            _isLoading = false;
          });
        }
      } else {
        // If no messages found, try a fallback approach specifically for Litha's account
        debugPrint('No messages found with initial approach, trying fallback...');

        try {
          // Force reload with a slight delay to ensure Firebase returns results
          await Future.delayed(const Duration(milliseconds: 500));
          final fallbackMessages = await FirebaseFirestore.instance
              .collection('messages')
              .where('chatRoomId', isEqualTo: widget.chatRoomId)
              .orderBy('timestamp', descending: true)
              .limit(30)
              .get();
              
          final parsedMessages = fallbackMessages.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
          
          // Store these messages too
          if (parsedMessages.isNotEmpty) {
            _updateLatestUserMessages(parsedMessages);
          }
          
          if (mounted) {
            setState(() {
              if (parsedMessages.isNotEmpty) {
                _messages.clear();
                _messages.addAll(parsedMessages);
              }
              _isLoading = false;
            });
          }
        } catch (fallbackError) {
          debugPrint('Fallback approach failed: $fallbackError');
          // Continue with empty messages if both approaches fail
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load messages';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    // Clear text field first for better UX
    _textController.clear();
    _focusNode.requestFocus();

    // Create a local temporary message to show immediately
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${_currentUserId.hashCode}';
    final tempMessage = ChatMessage(
      id: tempId,
      content: message,
      senderId: _currentUserId,
      senderName: 'You',
      chatRoomId: widget.chatRoomId,
      timestamp: DateTime.now(),
      mood: _selectedMood,
    );
    
    // Single setState to add the message and set sending state
    setState(() {
      _messages.insert(0, tempMessage); // Add at the beginning since we display in reverse
      _sendingMessage = true;
      _errorMessage = null;
    });
    
    // Also add to our latest user messages map for persistence
    _latestUserMessages[_currentUserId] = tempMessage;
    
    // Try to immediately persist this message using chatService's cache - do this outside setState
    await _chatService.addToLocalCache(widget.chatRoomId, [tempMessage]);

    try {
      final finalMood = _selectedMood; // Capture current mood before resetting
      
      // Reset mood state separately to avoid flickering in the main list
      setState(() {
        _selectedMood = null;
      });
      
      try {
        final success = await _chatService.sendMessage(
          chatRoomId: widget.chatRoomId,
          content: message,
          mood: finalMood,
        );

        if (!success) {
          // Only update the error state, don't touch the messages
          setState(() {
            _errorMessage = 'Failed to send message';
          });
        }
      } catch (e) {
        debugPrint('Error sending message to Firebase: $e');
        // Only update the error state
        setState(() {
          _errorMessage = 'Error sending to server, message saved locally';
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      
      setState(() {
        _errorMessage = 'Error: ${e.toString().split(': ').last}';
      });

      // Show not enough tokens dialog if that's the error
      if (e.toString().contains('tokens') && mounted) {
        // Get the current token balance
        final tokenBalance = await _chatService.getUserTokenBalance();
        if (mounted) {
          NotEnoughTokensDialog.show(
            context: context,
            requiredTokens: ChatRoom.messageTokenCost,
            currentTokens: tokenBalance,
            onBuyTokens: () {
              // Navigate to token purchase screen
            },
          );
        }
      }
    } finally {
      // Final state update to indicate sending is complete
      setState(() {
        _sendingMessage = false;
      });
    }
  }

  void _onMoodSelected(MoodType mood) {
    setState(() {
      _selectedMood = mood;
    });
    _focusNode.requestFocus(); // Focus back to text input
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<ChatRoom?>(
      stream: _chatService.getChatRoomStream(widget.chatRoomId),
      builder: (context, roomSnapshot) {
        if (roomSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.contactName),
              backgroundColor: const Color(0xFF1A1A2E),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final chatRoom = roomSnapshot.data;
        if (chatRoom == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.contactName),
              backgroundColor: const Color(0xFF1A1A2E),
            ),
            body: const Center(
              child: Text('Chat room not found', style: TextStyle(color: Colors.white)),
            ),
          );
        }

        final isAdmin = chatRoom.creatorId == _currentUserId;

        return WillPopScope(
          onWillPop: () async {
            // Return true to allow back navigation to work properly
            // Make sure we're really popping and not being pushed back immediately
            if (Navigator.of(context).canPop()) {
              return true;
            }
            // If we can't pop, make sure we explicitly exit the screen
            Navigator.of(context).pushReplacementNamed('/home');
            return false;
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Handle back button explicitly to ensure proper navigation
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacementNamed('/home');
                  }
                },
              ),
              title: Row(
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      // For direct messages, prioritize the other participant's name
                      chatRoom.isDirectMessage && _otherParticipantName != null
                          ? _otherParticipantName!
                          : (chatRoom.name.toLowerCase() == "new people" || 
                             (chatRoom.isDirectMessage && widget.contactName.isNotEmpty && widget.contactName != "Chat") ||
                             chatRoom.name.trim().isEmpty) 
                                ? widget.contactName 
                                : chatRoom.name,
                      overflow: TextOverflow.ellipsis
                    ),
                  ),
                ],
              ),
              actions: [
                // Invite users button (only visible for room creator/admin)
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    tooltip: 'Invite Users',
                    onPressed: () => _showInviteUsersDialog(context, chatRoom),
                  ),
                  
                // Share Room ID button
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share Room ID',
                  onPressed: () => _showShareRoomDialog(context, chatRoom),
                ),
                // Token balance
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: TokenBalance(isCompact: true, showLabel: false),
                ),
              ],
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
              child: Column(
                children: [
                  // Messages list
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                            : StreamBuilder<List<ChatMessage>>(
                                key: ValueKey<String>('message_stream_${widget.chatRoomId}'),
                                stream: _chatService.getChatMessagesStream(widget.chatRoomId),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting &&
                                      _messages.isEmpty) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  // Create a combined list that prioritizes snapshot data but falls back to local messages
                                  List<ChatMessage> combinedMessages = [];
                                  
                                  // First add messages from the stream if available
                                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                    // Don't modify combinedMessages directly if it's the same as before
                                    final newMessages = snapshot.data!;
                                    
                                    // Use our optimized method to check if we need to rebuild
                                    final needsRebuild = _shouldRebuildMessagesList(_messages, newMessages);
                                    
                                    if (needsRebuild) {
                                      combinedMessages.addAll(newMessages);
                                      // Store latest message from each sender
                                      _updateLatestUserMessages(newMessages);
                                      
                                      // Update _messages but avoid triggering a rebuild
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (mounted) {
                                          _messages.clear();
                                          _messages.addAll(combinedMessages);
                                        }
                                      });
                                    } else {
                                      // If messages haven't changed, just use the existing list
                                      combinedMessages.addAll(_messages);
                                    }
                                  } else if (_messages.isNotEmpty) {
                                    // If no stream data, use existing messages
                                    debugPrint("Using local cached messages instead of empty stream data");
                                    combinedMessages.addAll(_messages);
                                    // Also store these in our latest messages map
                                    _updateLatestUserMessages(_messages);
                                  }
                                  
                                  // Check for missing senders in this update
                                  if (snapshot.hasData && combinedMessages.isNotEmpty) {
                                    // Get set of sender IDs in current messages
                                    final currentSenderIds = combinedMessages.map((m) => m.senderId).toSet();
                                    
                                    // Add back any missing user messages (like Betty's)
                                    List<ChatMessage> missingMessages = [];
                                    _latestUserMessages.forEach((senderId, message) {
                                      if (!currentSenderIds.contains(senderId)) {
                                        debugPrint("Re-adding message from missing sender: $senderId");
                                        missingMessages.add(message);
                                      }
                                    });
                                    
                                    // Add missing messages without rebuilding if possible
                                    if (missingMessages.isNotEmpty) {
                                      combinedMessages.addAll(missingMessages);
                                      // Re-sort the messages by timestamp
                                      combinedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                                      
                                      // Update _messages in the background
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (mounted) {
                                          _messages.clear();
                                          _messages.addAll(combinedMessages);
                                        }
                                      });
                                    }
                                  }
                                  
                                  // Detect when messages disappear for specific accounts
                                  if (snapshot.hasData && snapshot.data!.isEmpty && _messages.isNotEmpty) {
                                    debugPrint("WARNING: Stream returned empty messages when we had local messages");
                                  }
                                  
                                  // Always use the combined messages for display
                                  final messagesToShow = combinedMessages.isNotEmpty ? combinedMessages : _messages;
                                  
                                  // If we have any messages to show, display them
                                  if (messagesToShow.isNotEmpty) {
                                    return RefreshIndicator(
                                      onRefresh: _forceRefreshMessages,
                                      color: AppColors.primaryBlue,
                                      child: ListView.builder(
                                        key: ValueKey<int>(messagesToShow.length), // Key based on length to preserve scroll
                                        padding: const EdgeInsets.all(8.0),
                                        reverse: true,
                                        itemCount: messagesToShow.length,
                                        itemBuilder: (context, index) {
                                          final message = messagesToShow[index];
                                          final isCurrentUser =
                                              message.senderId == _currentUserId;

                                          return MessageBubble(
                                            key: ValueKey<String>(message.id), // Key helps avoid rebuilds for unchanged messages
                                            message: Message.fromChatMessage(message, _currentUserId, otherParticipantName: _otherParticipantName),
                                            isCurrentUser: isCurrentUser,
                                          );
                                        },
                                      ),
                                    );
                                  } else {
                                    // Show empty state if we have no messages at all
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.message,
                                            size: 48,
                                            color: Colors.grey.withOpacity(0.5),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            "No messages yet. Be the first to send one!",
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                              ),
                  ),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: Colors.red.withOpacity(0.1),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  // Mood selector
                  if (_selectedMood != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: isDarkMode ? Colors.black12 : Colors.grey.shade200,
                      child: Row(
                        children: [
                          Icon(
                            getMoodIcon(_selectedMood!),
                            color: getMoodColor(_selectedMood!),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mood: ${getMoodName(_selectedMood!)}',
                            style: TextStyle(
                              color: getMoodColor(_selectedMood!),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() {
                                _selectedMood = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                  // Message input
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, -2),
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Mood selector button
                        IconButton(
                          icon: Icon(
                            _selectedMood != null
                                ? getMoodIcon(_selectedMood!)
                                : Icons.mood,
                            color: _selectedMood != null
                                ? getMoodColor(_selectedMood!)
                                : Colors.grey,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => MoodSelector(
                                onMoodSelected: _onMoodSelected,
                                selectedMood: _selectedMood,
                              ),
                            );
                          },
                        ),

                        // Text input
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF252836) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(
                                  color:
                                      isDarkMode ? Colors.grey : Colors.grey.shade600,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                              maxLines: null,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Send button
                        Material(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: _sendingMessage ? null : _sendMessage,
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              child: _sendingMessage
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Show dialog to share room ID
  void _showShareRoomDialog(BuildContext context, ChatRoom chatRoom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primaryPurple, width: 1),
        ),
        title: Row(
          children: [
            Icon(Icons.share, color: AppColors.primaryPurple),
            const SizedBox(width: 8),
            const Text(
              'Share Chat Room',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share this Room ID with friends to invite them to join:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Room ID:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chatRoom.id,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.copy,
                          color: AppColors.primaryPurple,
                          size: 20,
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: chatRoom.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Room ID copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        tooltip: 'Copy to clipboard',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Instructions:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Send this Room ID to your friend\n'
              '2. Ask them to go to the Chat Rooms screen\n'
              '3. Tap the "Join Room" button in the top-right\n'
              '4. Enter this Room ID to join the conversation',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('SHARE ID'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: chatRoom.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Room ID copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  // Add this new method to show the invite users dialog
  void _showInviteUsersDialog(BuildContext context, ChatRoom chatRoom) {
    ChatInviteDialog.show(
      context: context,
      roomId: chatRoom.id,
      roomName: chatRoom.name,
    );
  }

  Future<void> _forceRefreshMessages() async {
    try {
      final refreshedMessages = await _chatService.forceRefreshMessages(widget.chatRoomId);
      
      if (refreshedMessages.isNotEmpty && mounted) {
        // Before updating all messages, make sure we preserve our latest user messages
        _updateLatestUserMessages(refreshedMessages);
        
        // Check if any senders from our tracked list are missing in the fresh results
        final senderIds = refreshedMessages.map((m) => m.senderId).toSet();
        List<ChatMessage> messagesToAdd = [];
        
        _latestUserMessages.forEach((senderId, message) {
          if (!senderIds.contains(senderId)) {
            // This sender (like Betty) is missing in the refresh, add their message back
            messagesToAdd.add(message);
            debugPrint("Preserving message from sender $senderId during refresh");
          }
        });
        
        setState(() {
          // Update with the refreshed messages plus any preserved messages
          _messages.clear();
          _messages.addAll(refreshedMessages);
          
          // Add any missing sender messages back
          if (messagesToAdd.isNotEmpty) {
            _messages.addAll(messagesToAdd);
            // Sort by timestamp again since we added new messages
            _messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          }
        });
      }
    } catch (e) {
      debugPrint('Error force refreshing messages: $e');
      // Don't show error to user, fail silently as this is a background refresh
    }
  }

  // Store latest message from each sender to prevent message loss
  void _updateLatestUserMessages(List<ChatMessage> messages) {
    for (final message in messages) {
      // Only update if this is a newer message
      if (!_latestUserMessages.containsKey(message.senderId) ||
          _latestUserMessages[message.senderId]!.timestamp.isBefore(message.timestamp)) {
        _latestUserMessages[message.senderId] = message;
      }
    }
  }

  // Check if we need to rebuild the messages list
  bool _shouldRebuildMessagesList(List<ChatMessage> oldMessages, List<ChatMessage> newMessages) {
    // Quick length check
    if (oldMessages.length != newMessages.length) return true;
    if (oldMessages.isEmpty) return newMessages.isNotEmpty;
    if (newMessages.isEmpty) return oldMessages.isNotEmpty;
    
    // Check the first and last messages for changes
    // This is a quick approximation that works well for chat apps
    final firstOldMsg = oldMessages.first;
    final firstNewMsg = newMessages.first;
    final lastOldMsg = oldMessages.last;
    final lastNewMsg = newMessages.last;
    
    // If the first or last messages are different, rebuild
    if (firstOldMsg.id != firstNewMsg.id) return true;
    if (lastOldMsg.id != lastNewMsg.id) return true;
    
    // If the length of messages and first/last are the same, likely no changes
    return false;
  }

  // Load the other participant's name for direct messages
  Future<void> _loadOtherParticipantName() async {
    try {
      final chatRoom = await _chatService.getChatRoomById(widget.chatRoomId);
      if (chatRoom != null && chatRoom.isDirectMessage) {
        String? otherUserId;
        
        // Try participantIds first, then fall back to memberIds
        if (chatRoom.participantIds != null && chatRoom.participantIds!.length == 2) {
          otherUserId = chatRoom.participantIds!.firstWhere(
            (id) => id != _currentUserId,
            orElse: () => '',
          );
        } else if (chatRoom.memberIds.length == 2) {
          otherUserId = chatRoom.memberIds.firstWhere(
            (id) => id != _currentUserId,
            orElse: () => '',
          );
        }
        
        if (otherUserId != null && otherUserId.isNotEmpty) {
          final userService = UserService();
          final otherUser = await userService.getUser(otherUserId);
          if (otherUser != null && mounted) {
            setState(() {
              _otherParticipantName = otherUser.name;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading other participant name: $e');
    }
  }
}

// Helper functions for mood handling
IconData getMoodIcon(MoodType mood) {
  switch (mood) {
    case MoodType.happy:
      return Icons.sentiment_satisfied;
    case MoodType.excited:
      return Icons.sentiment_very_satisfied;
    case MoodType.calm:
      return Icons.sentiment_neutral;
    case MoodType.bored:
      return Icons.sentiment_neutral;
    case MoodType.annoyed:
      return Icons.sentiment_dissatisfied;
    case MoodType.angry:
      return Icons.sentiment_very_dissatisfied;
    case MoodType.sad:
      return Icons.sentiment_dissatisfied;
    case MoodType.neutral:
    default:
      return Icons.sentiment_neutral;
  }
}

Color getMoodColor(MoodType mood) {
  switch (mood) {
    case MoodType.happy:
      return Colors.amber;
    case MoodType.excited:
      return AppColors.primaryPurple;
    case MoodType.calm:
      return AppColors.primaryBlue;
    case MoodType.bored:
      return Colors.grey;
    case MoodType.annoyed:
      return AppColors.primaryOrange;
    case MoodType.angry:
      return Colors.red;
    case MoodType.sad:
      return Colors.blueGrey;
    case MoodType.neutral:
    default:
      return Colors.teal;
  }
}

String getMoodName(MoodType mood) {
  switch (mood) {
    case MoodType.happy:
      return 'Happy';
    case MoodType.excited:
      return 'Excited';
    case MoodType.calm:
      return 'Calm';
    case MoodType.bored:
      return 'Bored';
    case MoodType.annoyed:
      return 'Annoyed';
    case MoodType.angry:
      return 'Angry';
    case MoodType.sad:
      return 'Sad';
    case MoodType.neutral:
    default:
      return 'Neutral';
  }
}
