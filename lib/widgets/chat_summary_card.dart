import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/contact_item.dart';

class ChatSummaryCard extends StatelessWidget {
  final String name;
  final String lastMessage;
  final int unreadCount;
  final ContactStatus status;
  final VoidCallback onTap;

  const ChatSummaryCard({
    super.key,
    required this.name,
    required this.lastMessage,
    this.unreadCount = 0,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient:
              status == ContactStatus.online
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryBlue.withOpacity(0.2),
                      AppColors.primaryPurple.withOpacity(0.2),
                    ],
                  )
                  : null,
          color: isDarkMode ? AppColors.glassDark : AppColors.glassLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status indicator and avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _getAvatarColor(),
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),

                // Status indicator
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isDarkMode ? AppColors.darkBackground : Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor().withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Name
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.darkText,
              ),
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Last message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                lastMessage,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Unread count
            if (unreadCount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
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
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor() {
    if (name == 'JoeBanker') return AppColors.primaryBlue;
    if (name == 'TradePost') return AppColors.primaryOrange;
    if (name == 'Info') return AppColors.primaryGreen;
    if (name == 'Gallery') return AppColors.primaryPurple;
    return AppColors.primaryBlue;
  }

  Color _getStatusColor() {
    switch (status) {
      case ContactStatus.online:
        return AppColors.onlineGreen;
      case ContactStatus.away:
        return AppColors.awayYellow;
      case ContactStatus.offline:
        return AppColors.offlineRed;
      case ContactStatus.unknown:
        return Colors.grey;
    }
  }
}
