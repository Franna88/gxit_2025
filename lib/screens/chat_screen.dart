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

    final chatService = ChatService();
    final tokenBalance = await chatService.getUserTokenBalance();

    // Check if user has enough tokens
    if (tokenBalance < 1) {
      if (mounted) {
        NotEnoughTokensDialog.show(
          context: context,
          requiredTokens: 1,
          currentTokens: tokenBalance,
        );
      }
      return;
    }

    // Try to send message with token
    try {
      final content = _messageController.text.trim();
      final success = await chatService.sendMessage(
        chatRoomId: 'demoRoom', // In a real app, use actual chatRoomId
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: ${e.toString()}')),
      );
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                '${(_chatActivityLevel * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              ...List.generate(5, (index) {
                final threshold = index * 0.2;
                final isActive = _chatActivityLevel >= threshold;

                return Container(
                  width: 5,
                  height: 12 + (index * 2),
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? _getActivityColor(_chatActivityLevel).withOpacity(
                              0.4 + (0.6 * _activityPulseController.value),
                            )
                            : Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
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
            color: isDarkMode ? Colors.black12 : Colors.white10,
          ),
          child: MoodWave(
            participants: _participants,
            height: 50,
            activityLevel: _chatActivityLevel,
          ),
        ),

        // Participants avatars
        Container(
          height: 115,
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black12 : Colors.white10,
            border: Border(
              bottom: BorderSide(
                color: isDarkMode ? Colors.white10 : Colors.black12,
                width: 0.5,
              ),
            ),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Current user first
              _buildParticipantAvatar('Me', _currentMood, true),

              // Other participants
              ..._participants.entries
                  .map(
                    (entry) =>
                        _buildParticipantAvatar(entry.key, entry.value, false),
                  )
                  .toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantAvatar(
    String name,
    UserMood mood,
    bool isCurrentUser,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              MoodVisualizer(
                mood: mood,
                size: 36,
                interactive: isCurrentUser,
                showPulse: isCurrentUser,
                onTap: isCurrentUser ? _showMoodSelector : null,
              ),
              if (isCurrentUser)
                Positioned(
                  right: -4,
                  top: -4,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 12,
                        color: Colors.black54,
                      ),
                    ),
                    iconSize: 20,
                    onPressed: _showMoodSelector,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: TextStyle(
              fontSize: 9,
              color: isCurrentUser ? mood.color : Colors.grey,
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
            Text(widget.contactName),
            const Spacer(),
            // Add token balance in the AppBar
            const TokenBalance(isCompact: true, showLabel: false),
          ],
        ),
        actions: [
          _buildActivityIndicator(),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
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
                color: isDarkMode ? AppColors.glassDark : AppColors.glassLight,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color:
                      isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  // Mood indicator for current message
                  GestureDetector(
                    onTap: _showMoodSelector,
                    child: AnimatedBuilder(
                      animation: _moodAnimationController,
                      builder: (context, child) {
                        return MoodIcon(mood: _currentMood, size: 36);
                      },
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      maxLines: null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {},
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      gradient: GradientPalette.buttonGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
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
