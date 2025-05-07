import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants.dart';
import '../widgets/message_bubble.dart';
import '../models/user_mood.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../widgets/mood_visualizer.dart';
import '../widgets/mood_wave.dart';
import '../services/chat_service.dart';
import '../widgets/token_balance.dart';
import '../widgets/not_enough_tokens_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Define Message class for backward compatibility with MessageBubble
class Message {
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final String senderName;
  final UserMood mood;
  final List<String>? reactions;

  Message({
    required this.content,
    required this.timestamp,
    required this.isMe,
    required this.senderName,
    required this.mood,
    this.reactions,
  });

  Message copyWith({
    String? content,
    DateTime? timestamp,
    bool? isMe,
    String? senderName,
    UserMood? mood,
    List<String>? reactions,
  }) {
    return Message(
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      senderName: senderName ?? this.senderName,
      mood: mood ?? this.mood,
      reactions: reactions ?? this.reactions,
    );
  }
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

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ChatService _chatService = ChatService();
  bool _isLoading = true;
  bool _hasLoadedInitialMessages = false;

  String? _currentUserId;

  // Chat room data
  ChatRoom? _chatRoom;

  // Current user mood
  late UserMood _currentMood;

  // Chat room participants with their moods
  final Map<String, UserMood> _participants = {};

  // Animation controller for mood transitions
  late AnimationController _moodAnimationController;
  late Animation<double> _moodAnimation;

  // Chat activity level (0.0 to 1.0) indicating how active the conversation is
  double _chatActivityLevel = 0.3;
  late AnimationController _activityPulseController;

  @override
  void initState() {
    super.initState();
    _currentMood = MoodOptions.happy;
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Setup animations
    _moodAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _moodAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _moodAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _activityPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Load chat room data and messages
    _loadChatRoom();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _moodAnimationController.dispose();
    _activityPulseController.dispose();
    super.dispose();
  }

  // Load chat room data
  Future<void> _loadChatRoom() async {
    try {
      if (widget.chatRoomId == 'demoRoom') {
        // For demo room, create a fake chat room
        setState(() {
          _chatRoom = ChatRoom(
            id: 'demoRoom',
            name: widget.contactName,
            memberIds: ['demo_user'],
            lastMessage: 'This is a demo chat room',
            lastSenderId: 'demo_user',
            lastActivity: DateTime.now(),
            isPublic: true,
          );
          _setupDemoParticipants();
        });
        return;
      }

      // Subscribe to the chat room stream
      _chatService.getChatRoomStream(widget.chatRoomId).listen((chatRoom) {
        if (chatRoom != null && mounted) {
          setState(() {
            _chatRoom = chatRoom;
            _chatActivityLevel = 0.3 + (math.Random().nextDouble() * 0.4);
          });
        }
      });
    } catch (e) {
      print('Error loading chat room: $e');
    }
  }

  // Load messages from Firebase
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.chatRoomId == 'demoRoom') {
        // For demo room, add sample messages
        _loadInitialMessages();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // First check if there are any messages quickly
      final initialMessages = await _chatService.getInitialMessages(widget.chatRoomId, 1);
      
      if (initialMessages.isEmpty) {
        // No messages found, update UI immediately
        setState(() {
          _messages.clear();
          _isLoading = false;
        });
      }

      // Subscribe to the messages stream regardless
      _chatService.getChatMessagesStream(widget.chatRoomId).listen((messages) {
        if (mounted) {
          setState(() {
            _messages.clear();
            if (messages.isNotEmpty) {
              _messages.addAll(messages);
            }
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupDemoParticipants() {
    // Add some fake participants with different moods for demo room
    _participants.addAll({
      'Alex': MoodOptions.excited,
      'Emma': MoodOptions.curious,
      'Michael': MoodOptions.relaxed,
      'Rachel': MoodOptions.bored,
      'Jamie': MoodOptions.annoyed,
    });

    // Simulate mood changes every 20 seconds
    _simulateParticipantMoodChanges();
  }

  void _simulateParticipantMoodChanges() {
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) {
        setState(() {
          // Randomly change 1-2 participants' moods
          final participants = _participants.keys.toList();
          participants.shuffle();

          for (int i = 0; i < math.min(2, participants.length); i++) {
            final participant = participants[i];
            _participants[participant] = MoodOptions.getRandomMood();
          }
        });

        _simulateParticipantMoodChanges();
      }
    });
  }

  Future<void> _loadInitialMessages() async {
    // Sample messages for demo with moods and reactions
    final messages = [
      ChatMessage(
        id: '1',
        content: 'Hey, how are you doing?',
        senderId: 'demo_sender',
        senderName: widget.contactName,
        chatRoomId: widget.chatRoomId,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        mood: MoodType.happy,
        reactions: ['👍', '❤️'],
      ),
      ChatMessage(
        id: '2',
        content: 'I\'m good, thanks! How about you?',
        senderId: _currentUserId ?? 'current_user',
        senderName: 'Me',
        chatRoomId: widget.chatRoomId,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        mood: MoodType.happy,
      ),
      ChatMessage(
        id: '3',
        content: 'Just wanted to check if we\'re still on for tomorrow?',
        senderId: 'demo_sender',
        senderName: widget.contactName,
        chatRoomId: widget.chatRoomId,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        mood: MoodType.happy,
      ),
      ChatMessage(
        id: '4',
        content: 'Yes, definitely! Looking forward to it!',
        senderId: _currentUserId ?? 'current_user',
        senderName: 'Me',
        chatRoomId: widget.chatRoomId,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        mood: MoodType.excited,
        reactions: ['🎉'],
      ),
    ];

    // Add messages to local state
    _messages.addAll(messages);

    // Save messages to Firebase if this is not the demo room
    if (widget.chatRoomId != 'demoRoom') {
      for (final message in messages) {
        await _chatService.sendMessage(
          chatRoomId: widget.chatRoomId,
          content: message.content,
          mood: message.mood,
        );
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();

    try {
      // Check if user has enough tokens
      final tokenBalance = await _chatService.getUserTokenBalance();

      if (tokenBalance < ChatRoom.messageTokenCost) {
        if (mounted) {
          NotEnoughTokensDialog.show(
            context: context,
            requiredTokens: ChatRoom.messageTokenCost,
            currentTokens: tokenBalance,
            onBuyTokens: () {
              _refreshAfterTokenPurchase();
            },
          );
        }
        return;
      }

      // Send message to Firebase
      final success = await _chatService.sendMessage(
        chatRoomId: widget.chatRoomId,
        content: content,
        mood: _currentMood.type,
      );

      if (success) {
        // Clear input field
        _messageController.clear();

        // In demo mode, add message locally
        if (widget.chatRoomId == 'demoRoom') {
          setState(() {
            _messages.add(
              ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                content: content,
                senderId: _currentUserId ?? 'current_user',
                senderName: 'Me',
                chatRoomId: 'demoRoom',
                timestamp: DateTime.now(),
                mood: _currentMood.type,
              ),
            );

            // Increase chat activity when new message is sent
            _chatActivityLevel = math.min(1.0, _chatActivityLevel + 0.2);
          });

          // Simulate response for demo purposes
          _simulateResponse();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send message. Please try again later.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _sendMessage: $e');
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

  void _simulateResponse() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && widget.chatRoomId == 'demoRoom') {
        setState(() {
          // Simulated response with a random mood
          final responseMood = MoodOptions.getRandomMood();

          _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content: 'Thanks for your message. I\'ll get back to you soon!',
              senderId: 'demo_sender',
              senderName: widget.contactName,
              chatRoomId: 'demoRoom',
              timestamp: DateTime.now(),
              mood: responseMood.type,
            ),
          );
        });
      }
    });
  }

  void _refreshAfterTokenPurchase() {
    // Refresh token balance and try again
    setState(() {
      // Token purchase complete, refresh UI
    });
  }

  // Add reaction to a message
  void _addReaction(String messageId, String reaction) async {
    await _chatService.addReaction(messageId, reaction);
  }

  // User selected mood changed
  void _onMoodChanged(UserMood mood) {
    setState(() {
      _currentMood = mood;
    });
    _moodAnimationController.forward(from: 0.0);
  }

  // Get UserMood from MoodType
  UserMood _getMoodFromType(MoodType? moodType) {
    if (moodType == null) return MoodOptions.relaxed;

    switch (moodType) {
      case MoodType.happy:
        return MoodOptions.happy;
      case MoodType.sad:
        return MoodOptions.sad;
      case MoodType.angry:
        return MoodOptions.angry;
      case MoodType.excited:
        return MoodOptions.excited;
      case MoodType.bored:
        return MoodOptions.bored;
      case MoodType.annoyed:
        return MoodOptions.annoyed;
      case MoodType.calm:
        return MoodOptions.relaxed;
      case MoodType.neutral:
      default:
        return MoodOptions.relaxed;
    }
  }

  // Convert ChatMessage to Message format for MessageBubble
  Message _convertToMessage(ChatMessage chatMessage) {
    final isMe = chatMessage.senderId == _currentUserId;

    return Message(
      content: chatMessage.content,
      timestamp: chatMessage.timestamp,
      isMe: isMe,
      senderName: isMe ? 'You' : chatMessage.senderName,
      mood: _getMoodFromType(chatMessage.mood),
      reactions: chatMessage.reactions,
    );
  }

  // Build the message list
  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? Colors.blue.withOpacity(0.1) 
                    : Colors.blue.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: AppColors.primaryBlue.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Be the first to say hello to ${widget.contactName}!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Pre-fill a greeting message
                _messageController.text = "Hello! 👋";
                
                // Focus the message input field
                FocusScope.of(context).requestFocus(
                  FocusNode()
                );
                
                // Simulate button tap animation and give a hint to the user
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message prepared. Tap send when ready!'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppColors.primaryBlue,
                  ),
                );
              },
              icon: const Icon(Icons.message),
              label: const Text('START CONVERSATION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.only(top: 15, bottom: 70),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final chatMessage = _messages[index];
        final message = _convertToMessage(chatMessage);

        return GestureDetector(
          onLongPress: () {
            // Show reactions menu
          },
          child: MessageBubble(
            message: message,
            onReactionTap: (reaction) => _addReaction(chatMessage.id, reaction),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.person),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.contactName, overflow: TextOverflow.ellipsis),
            ),
            // Add token balance in the AppBar
            const TokenBalance(isCompact: true, showLabel: false),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
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
            // Participants with mood indicators
            _buildParticipantsRow(),

            // Messages list
            Expanded(child: _buildMessageList()),

            // Message input bar
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF252836) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Mood indicator for current message
                  GestureDetector(
                    onTap: _showMoodSelector,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: MoodIcon(mood: _currentMood, size: 28),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _messages.isEmpty 
                            ? 'Type "Hello" to start the conversation...' 
                            : 'Type a message',
                        hintStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey : Colors.grey.shade600,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      maxLines: null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    color: Colors.grey,
                    onPressed: () {},
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoodSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSecondaryBackground
                      : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'How are you feeling?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children:
                      MoodOptions.allMoods
                          .map(
                            (mood) => GestureDetector(
                              onTap: () {
                                _onMoodChanged(mood);
                                Navigator.pop(context);
                              },
                              child: MoodVisualizer(
                                mood: mood,
                                size: 60,
                                label: mood.name,
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildActivityIndicator() {
    return AnimatedBuilder(
      animation: _activityPulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, color: Colors.white70, size: 14),
              const SizedBox(width: 2),
              Text(
                '${(_chatActivityLevel * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getActivityColor(double activity) {
    if (activity < 0.3) return Colors.blue;
    if (activity < 0.6) return Colors.green;
    if (activity < 0.8) return Colors.amber;
    return Colors.red;
  }

  Widget _buildParticipantsRow() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mood wave visualization
        Container(
          height: 50,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1F2130) : Colors.grey.shade200,
            border: Border(
              bottom: BorderSide(
                color: isDarkMode ? Colors.white10 : Colors.black12,
                width: 0.5,
              ),
            ),
          ),
          child: MoodWave(
            participants: _participants,
            height: 50,
            activityLevel: _chatActivityLevel,
          ),
        ),

        // Mood selection row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black12 : Colors.white10,
            border: Border(
              bottom: BorderSide(
                color: isDarkMode ? Colors.white10 : Colors.black12,
                width: 0.5,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildInfoText(),
                const SizedBox(width: 8),
                ...MoodOptions.allMoods.take(6).map((mood) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => _onMoodChanged(mood),
                      child: MoodVisualizer(
                        mood: mood,
                        size: 32,
                        interactive: true,
                        showPulse: mood.name == _currentMood.name,
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Tap an emoji to set your current mood',
        style: TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}
