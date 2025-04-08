import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String contactName;

  const ChatScreen({super.key, required this.contactName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _loadInitialMessages() {
    // Sample messages for demo
    _messages.addAll([
      Message(
        content: 'Hey, how are you doing?',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        isMe: false,
      ),
      Message(
        content: 'I\'m good, thanks! How about you?',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        isMe: true,
      ),
      Message(
        content: 'Just wanted to check if we\'re still on for tomorrow?',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isMe: false,
      ),
      Message(
        content: 'Yes, definitely! Looking forward to it!',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        isMe: true,
      ),
    ]);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        Message(
          content: _messageController.text.trim(),
          timestamp: DateTime.now(),
          isMe: true,
        ),
      );
      _messageController.clear();
    });

    // Simulate response for demo purposes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(
            Message(
              content: 'Thanks for your message. I\'ll get back to you soon!',
              timestamp: DateTime.now(),
              isMe: false,
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.contactName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            isDarkMode ? AppColors.darkBackground : Colors.grey.shade100,
        elevation: 0,
        actions: [
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
                  return MessageBubble(message: message);
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
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    onPressed: () {},
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
}

class Message {
  final String content;
  final DateTime timestamp;
  final bool isMe;

  Message({required this.content, required this.timestamp, required this.isMe});
}
