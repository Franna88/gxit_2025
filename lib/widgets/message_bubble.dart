import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../screens/chat_screen.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('h:mm a');

    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color:
              message.isMe
                  ? AppColors.primaryPurple
                  : isDarkMode
                  ? AppColors.glassDark
                  : AppColors.glassLight,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          gradient: message.isMe ? GradientPalette.buttonGradient : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeFormat.format(message.timestamp),
                style: TextStyle(
                  color:
                      message.isMe
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
