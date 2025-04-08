import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../screens/chat_screen.dart';
import '../models/user_mood.dart';
import 'mood_visualizer.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final Function(String)? onReactionTap;

  const MessageBubble({super.key, required this.message, this.onReactionTap});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('h:mm a');

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
                    color: message.mood.color,
                  ),
                ),
                const SizedBox(width: 4),
                MoodIcon(mood: message.mood, size: 16),
              ],
            ),
          ),

        // Main message bubble
        Container(
          margin: EdgeInsets.only(
            top: 2,
            bottom: (message.reactions?.isNotEmpty ?? false) ? 2 : 8,
            left: message.isMe ? 60 : 0,
            right: message.isMe ? 0 : 60,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  message.isMe
                      ? message.mood.gradient
                      : [
                        isDarkMode ? AppColors.glassDark : AppColors.glassLight,
                        isDarkMode
                            ? AppColors.glassDark.withOpacity(0.8)
                            : AppColors.glassLight.withOpacity(0.8),
                      ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: (message.isMe ? message.mood.color : Colors.black)
                    .withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
            border:
                message.isMe
                    ? null
                    : Border.all(
                      color: message.mood.color.withOpacity(0.3),
                      width: 1,
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
                          : AppColors.darkText,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),

              // Time and mood indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // If not my message, add mood indicator at the end
                  if (!message.isMe)
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: MoodIcon(mood: message.mood, size: 16),
                    ),

                  Text(
                    timeFormat.format(message.timestamp),
                    style: TextStyle(
                      color:
                          message.isMe
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
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
                      onTap: () => onReactionTap?.call(reaction),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              reaction,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
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
