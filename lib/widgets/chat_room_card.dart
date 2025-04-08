import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';

class ChatRoomCard extends StatelessWidget {
  final String name;
  final String lastMessage;
  final DateTime lastActivity;
  final int memberCount;
  final bool hasUnreadMessages;
  final int unreadCount;
  final VoidCallback onTap;

  const ChatRoomCard({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.lastActivity,
    required this.memberCount,
    this.hasUnreadMessages = false,
    this.unreadCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? AppColors.darkSecondaryBackground
                  : AppColors.glassLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border:
              hasUnreadMessages
                  ? Border.all(
                    color:
                        isDarkMode
                            ? AppColors.primaryBlue.withOpacity(0.3)
                            : AppColors.primaryBlue.withOpacity(0.5),
                    width: 1,
                  )
                  : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topic indicator and name
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: _getTopicColor(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : AppColors.darkText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Last message
              Text(
                lastMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? AppColors.subtleText : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Member count and activity info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Member count
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 14,
                        color:
                            isDarkMode ? AppColors.subtleText : Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$memberCount members',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode
                                  ? AppColors.subtleText
                                  : Colors.black54,
                        ),
                      ),
                    ],
                  ),

                  // Unread messages badge
                  if (hasUnreadMessages && unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Last activity time
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: isDarkMode ? AppColors.subtleText : Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last activity: ${_getTimeText(lastActivity)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? AppColors.subtleText : Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTopicColor() {
    // Assign colors based on the topic name
    if (name.contains('Market') || name.contains('Economic')) {
      return AppColors.primaryBlue;
    } else if (name.contains('Crypto')) {
      return AppColors.primaryPurple;
    } else if (name.contains('Trade') || name.contains('Strategy')) {
      return AppColors.primaryOrange;
    } else {
      return AppColors.primaryGreen;
    }
  }

  String _getTimeText(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes <= 1 ? 'Just now' : '$minutes min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      final formatter = DateFormat('MMM d');
      return formatter.format(time);
    }
  }
}
