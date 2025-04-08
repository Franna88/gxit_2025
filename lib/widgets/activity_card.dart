import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';

enum ActivityType { newMember, fileShared, groupCreated, messageReacted }

class ActivityCard extends StatelessWidget {
  final ActivityType activityType;
  final String message;
  final DateTime timestamp;

  const ActivityCard({
    super.key,
    required this.activityType,
    required this.message,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassDark : AppColors.glassLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getActivityColor().withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getActivityIcon(),
                color: _getActivityColor(),
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Activity details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _getActivityTypeText(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getActivityColor(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· ${_getRelativeTimeText(timestamp)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon() {
    switch (activityType) {
      case ActivityType.newMember:
        return Icons.person_add;
      case ActivityType.fileShared:
        return Icons.folder_shared;
      case ActivityType.groupCreated:
        return Icons.group_add;
      case ActivityType.messageReacted:
        return Icons.thumb_up;
    }
  }

  Color _getActivityColor() {
    switch (activityType) {
      case ActivityType.newMember:
        return AppColors.primaryBlue;
      case ActivityType.fileShared:
        return AppColors.primaryPurple;
      case ActivityType.groupCreated:
        return AppColors.primaryGreen;
      case ActivityType.messageReacted:
        return AppColors.primaryOrange;
    }
  }

  String _getActivityTypeText() {
    switch (activityType) {
      case ActivityType.newMember:
        return 'New Members';
      case ActivityType.fileShared:
        return 'File Shared';
      case ActivityType.groupCreated:
        return 'Group Created';
      case ActivityType.messageReacted:
        return 'Message Reaction';
    }
  }

  String _getRelativeTimeText(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} day ago';
    }
  }
}
