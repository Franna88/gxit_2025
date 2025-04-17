import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants.dart';
import '../widgets/message_bubble.dart';
import '../models/user_mood.dart';
import '../widgets/mood_visualizer.dart';
import '../widgets/mood_wave.dart';
import '../services/chat_service.dart';
import '../widgets/token_balance.dart';
import '../widgets/not_enough_tokens_dialog.dart';

class ChatScreen extends StatefulWidget {
  final String contactName;

  const ChatScreen({super.key, required this.contactName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];

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

    // Load demo data
    _loadInitialMessages();
    _setupDemoParticipants();

    // Simulate chat activity changes
    _simulateChatActivityChanges();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _moodAnimationController.dispose();
    _activityPulseController.dispose();
    super.dispose();
  }

  void _simulateChatActivityChanges() {
    // Periodically change the activity level to simulate a dynamic chat
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          // Random activity between 0.2 and 1.0
          _chatActivityLevel = 0.2 + (math.Random().nextDouble() * 0.8);
        });
        _simulateChatActivityChanges();
      }
    });
  }

  void _setupDemoParticipants() {
    // Add some fake participants with different moods
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

  void _loadInitialMessages() {
    // Sample messages for demo with moods and reactions
    _messages.addAll([
      Message(
        content: 'Hey, how are you doing?',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        isMe: false,
        senderName: widget.contactName,
        mood: MoodOptions.curious,
        reactions: ['👍', '❤️'],
      ),
      Message(
        content: 'I\'m good, thanks! How about you?',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        isMe: true,
        senderName: 'Me',
        mood: MoodOptions.happy,
      ),
      Message(
        content: 'Just wanted to check if we\'re still on for tomorrow?',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isMe: false,
        senderName: widget.contactName,
        mood: MoodOptions.relaxed,
      ),
      Message(
        content: 'Yes, definitely! Looking forward to it!',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        isMe: true,
        senderName: 'Me',
        mood: MoodOptions.excited,
        reactions: ['🎉'],
      ),
    ]);
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();

    try {
      final chatService = ChatService();
      final tokenBalance = await chatService.getUserTokenBalance();

      // Check if user has enough tokens
      if (tokenBalance < 1) {
        if (mounted) {
          NotEnoughTokensDialog.show(
            context: context,
            requiredTokens: 1,
            currentTokens: tokenBalance,
            onBuyTokens: () {
              _refreshAfterTokenPurchase();
            },
          );
        }
        return;
      }

      // Try to send message with token
      final success = await chatService.sendMessage(
        chatRoomId: 'demoRoom', // Use demoRoom for testing
        content: content,
        mood: _currentMood.type,
      );

      if (success) {
        setState(() {
          _messages.add(
            Message(
              content: content,
              timestamp: DateTime.now(),
              isMe: true,
              senderName: 'Me',
              mood: _currentMood,
            ),
          );
          _messageController.clear();

          // Increase chat activity when new message is sent
          _chatActivityLevel = math.min(1.0, _chatActivityLevel + 0.2);
        });

        // Simulate response for demo purposes
        _simulateResponse();
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
      if (mounted) {
        setState(() {
          // Simulated response with a random mood
          final responseMood = MoodOptions.getRandomMood();

          _messages.add(
            Message(
              content: 'Thanks for your message. I\'ll get back to you soon!',
              timestamp: DateTime.now(),
              isMe: false,
              senderName: widget.contactName,
              mood: responseMood,
            ),
          );

          // Update contact's mood based on their response
          _participants[widget.contactName] = responseMood;
        });
      }
    });
  }

  void _refreshAfterTokenPurchase() async {
    // After user returns from token purchase, check balance again
    final chatService = ChatService();
    final tokenBalance = await chatService.getUserTokenBalance();

    // Update the token balance in the UI
    if (mounted) {
      setState(() {
        // The TokenBalance widget will automatically update
      });
    }
  }

  void _changeMood(UserMood newMood) {
    if (_currentMood.name != newMood.name) {
      setState(() {
        _currentMood = newMood;
        _moodAnimationController.forward(from: 0.0);
      });
    }
  }

  void _addReactionToMessage(int messageIndex, String reaction) {
    setState(() {
      final message = _messages[messageIndex];
      final List<String> currentReactions = List.from(message.reactions ?? []);

      if (currentReactions.contains(reaction)) {
        currentReactions.remove(reaction);
      } else {
        currentReactions.add(reaction);
      }

      _messages[messageIndex] = message.copyWith(reactions: currentReactions);
    });
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
                                _changeMood(mood);
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
                      onTap: () => _changeMood(mood),
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
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final reversedIndex = _messages.length - 1 - index;
                  final message = _messages[reversedIndex];
                  return GestureDetector(
                    onLongPress: () {
                      _showReactionsMenu(context, reversedIndex);
                    },
                    child: MessageBubble(
                      message: message,
                      onReactionTap: (reaction) {
                        _addReactionToMessage(reversedIndex, reaction);
                      },
                    ),
                  );
                },
              ),
            ),

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
                        hintText: 'Type a message',
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

  void _showReactionsMenu(BuildContext context, int messageIndex) {
    final message = _messages[messageIndex];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Categorized reactions
    final reactionCategories = {
      'Positive': ['👍', '❤️', '😊', '👏', '🎉'],
      'Funny': ['😂', '🤣', '😆', '😜', '🤪'],
      'Surprised': ['😮', '😲', '🤯', '😱', '🙀'],
      'Negative': ['👎', '😢', '😠', '😡', '💔'],
      'Other': ['🔥', '💯', '🤔', '💪', '✨'],
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDarkMode ? AppColors.darkSecondaryBackground : Colors.white,
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
            child: Column(
              children: [
                // Header with user info
                Row(
                  children: [
                    MoodIcon(mood: message.mood, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'React to ${message.isMe ? 'your' : message.senderName}\'s message',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                // Message preview
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black12 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: message.mood.color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    message.content.length > 60
                        ? '${message.content.substring(0, 60)}...'
                        : message.content,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                // Current reactions display
                if (message.reactions != null && message.reactions!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Current: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        ...message.reactions!
                            .map(
                              (emoji) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ),

                // Tabbed reactions by category
                Expanded(
                  child: DefaultTabController(
                    length: reactionCategories.length,
                    child: Column(
                      children: [
                        TabBar(
                          isScrollable: true,
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor:
                              isDarkMode ? Colors.white60 : Colors.black54,
                          tabs:
                              reactionCategories.keys
                                  .map((category) => Tab(text: category))
                                  .toList(),
                        ),
                        Expanded(
                          child: TabBarView(
                            children:
                                reactionCategories.entries.map((entry) {
                                  return GridView.builder(
                                    padding: const EdgeInsets.all(16),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 5,
                                          childAspectRatio: 1,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                        ),
                                    itemCount: entry.value.length,
                                    itemBuilder: (context, index) {
                                      final emoji = entry.value[index];
                                      final isSelected =
                                          message.reactions?.contains(emoji) ??
                                          false;

                                      return InkWell(
                                        onTap: () {
                                          _addReactionToMessage(
                                            messageIndex,
                                            emoji,
                                          );
                                          Navigator.pop(context);
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.2)
                                                    : isDarkMode
                                                    ? Colors.white.withOpacity(
                                                      0.05,
                                                    )
                                                    : Colors.black.withOpacity(
                                                      0.05,
                                                    ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                      : Colors.transparent,
                                              width: 1,
                                            ),
                                            boxShadow:
                                                isSelected
                                                    ? [
                                                      BoxShadow(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.3),
                                                        blurRadius: 8,
                                                        spreadRadius: 1,
                                                      ),
                                                    ]
                                                    : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              emoji,
                                              style: const TextStyle(
                                                fontSize: 28,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Custom reaction button
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Custom Reaction'),
                  onPressed: () {
                    // Show emoji picker or custom input
                    Navigator.pop(context);
                    // Implementation for custom reaction would go here
                  },
                ),
              ],
            ),
          ),
    );
  }
}

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
