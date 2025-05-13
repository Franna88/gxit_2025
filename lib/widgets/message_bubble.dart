import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../screens/chat_screen.dart';
import '../models/user_mood.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const MessageBubble({
    super.key, 
    required this.message, 
    required this.isCurrentUser,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageBubble &&
        other.message.id == message.id &&
        other.message.content == message.content &&
        other.isCurrentUser == isCurrentUser;
  }

  @override
  int get hashCode => Object.hash(message.id, message.content, isCurrentUser);

  Color _getMoodColor(MoodType? mood) {
    if (mood == null) return Colors.grey;
    
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

  IconData _getMoodIcon(MoodType? mood) {
    if (mood == null) return Icons.sentiment_neutral;
    
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('h:mm a');
    final moodColor = _getMoodColor(message.mood);

    return Column(
      crossAxisAlignment:
          message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Sender name with mood icon for group chats (only show for non-user messages)
        if (!message.isMe)
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: moodColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _getMoodIcon(message.mood),
                  color: moodColor,
                  size: 16,
                ),
              ],
            ),
          ),

        // Main message bubble
        Container(
          margin: EdgeInsets.only(
            top: 2,
            bottom: (message.reactions?.isNotEmpty ?? false) ? 2 : 8,
            left: message.isMe ? 60 : 12,
            right: message.isMe ? 12 : 60,
          ),
          decoration: BoxDecoration(
            color:
                message.isMe
                    ? moodColor.withOpacity(0.8) // Use solid color for user messages
                    : isDarkMode
                    ? const Color(0xFF2A2E3A) // Dark gray for received messages
                    : Colors.grey.shade200, // Light gray for received messages
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(message.isMe ? 20 : 5),
              bottomRight: Radius.circular(message.isMe ? 5 : 20),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message content
              Text(
                message.content,
                style: TextStyle(
                  color:
                      message.isMe
                          ? Colors.white
                          : isDarkMode
                          ? Colors.white
                          : Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),

              // Time and mood indicator
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!message.isMe && message.mood != null && message.mood != MoodType.neutral)
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Icon(
                          _getMoodIcon(message.mood),
                          color: moodColor,
                          size: 14,
                        ),
                      ),
                    Text(
                      timeFormat.format(message.timestamp),
                      style: TextStyle(
                        color:
                            message.isMe
                                ? Colors.white.withOpacity(0.8)
                                : isDarkMode
                                ? Colors.grey
                                : Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Reactions
        if (message.reactions != null && message.reactions!.isNotEmpty)
          Container(
            margin: EdgeInsets.only(
              left: message.isMe ? 40 : 12,
              right: message.isMe ? 12 : 40,
              bottom: 8,
            ),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children:
                  message.reactions!.map((reaction) {
                    return GestureDetector(
                      onTap: null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black26 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          reaction,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }
}
