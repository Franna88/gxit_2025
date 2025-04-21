import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/chat_service.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Choose icon based on notification type
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.roomClosed:
        icon = Icons.meeting_room_outlined;
        iconColor = Colors.red;
        break;
      case NotificationType.invitationReceived:
        icon = Icons.person_add;
        iconColor = Colors.green;
        break;
      case NotificationType.messageReceived:
        icon = Icons.message;
        iconColor = Colors.blue;
        break;
      case NotificationType.roomExpired:
        icon = Icons.access_time;
        iconColor = Colors.orange;
        break;
      case NotificationType.systemMessage:
      default:
        icon = Icons.notifications;
        iconColor = Colors.purple;
        break;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        // Mark as read and dismiss
        final chatService = ChatService();
        chatService.markNotificationAsRead(notification.id);
        onDismiss();
      },
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        color:
            notification.isRead
                ? (isDarkMode ? const Color(0xFF1A1A2E) : Colors.grey.shade100)
                : (isDarkMode ? const Color(0xFF222244) : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side:
              notification.isRead
                  ? BorderSide.none
                  : BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
        ),
        child: InkWell(
          onTap: () {
            // Mark as read when tapped
            final chatService = ChatService();
            chatService.markNotificationAsRead(notification.id);
            // Handle tap based on notification type
            _handleNotificationTap(context);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title based on notification type
                      Text(
                        _getNotificationTitle(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.7,
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
      ),
    );
  }

  String _getNotificationTitle() {
    switch (notification.type) {
      case NotificationType.roomClosed:
        return 'Room Closed';
      case NotificationType.invitationReceived:
        return 'New Invitation';
      case NotificationType.messageReceived:
        return 'New Message';
      case NotificationType.roomExpired:
        return 'Room Expired';
      case NotificationType.systemMessage:
        return 'System Notification';
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _handleNotificationTap(BuildContext context) {
    // Handle different types of notifications
    switch (notification.type) {
      case NotificationType.roomClosed:
        // Show a dialog with details about the closed room
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Room Closed'),
                content: Text(
                  'The chat room "${notification.roomName}" has been closed.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
        break;
      case NotificationType.invitationReceived:
        // Navigate to invitations screen
        // This would be implemented based on your navigation structure
        break;
      case NotificationType.messageReceived:
        // Navigate to the chat room
        // This would depend on your navigation structure
        break;
      case NotificationType.roomExpired:
      case NotificationType.systemMessage:
        // Just show the notification details
        break;
    }
  }
}
