import 'package:flutter/material.dart';
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
    Key? key,
    required this.name,
    required this.lastMessage,
    required this.lastActivity,
    required this.memberCount,
    this.hasUnreadMessages = false,
    this.unreadCount = 0,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: AppColors.primaryBlue.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primaryPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      color: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Left side - Icon with color indicator for unread
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color:
                      hasUnreadMessages
                          ? AppColors.primaryGreen
                          : AppColors.primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (hasUnreadMessages
                              ? AppColors.primaryGreen
                              : AppColors.primaryBlue)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.group, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              // Center - Room details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  hasUnreadMessages
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                              color:
                                  isDarkMode
                                      ? Colors.white
                                      : AppColors.darkText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _getTimeText(lastActivity),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDarkMode
                                    ? AppColors.subtleText
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDarkMode
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                        fontWeight:
                            hasUnreadMessages
                                ? FontWeight.w500
                                : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color:
                              isDarkMode
                                  ? AppColors.subtleText
                                  : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$memberCount members',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDarkMode
                                    ? AppColors.subtleText
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Right side - notification count if any
              if (hasUnreadMessages && unreadCount > 0)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeText(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }
}
