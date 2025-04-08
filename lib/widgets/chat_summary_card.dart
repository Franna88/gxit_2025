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
              isDarkMode && status == ContactStatus.online
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryBlue.withOpacity(0.1),
                      AppColors.darkSecondaryBackground,
                    ],
                  )
                  : null,
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
                  backgroundColor: _getAvatarColor().withOpacity(
                    isDarkMode ? 0.5 : 0.8,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing glow effect for online status
                      if (status == ContactStatus.online)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _getStatusColor().withOpacity(0.6),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),

                      // Large status indicator
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDarkMode
                                    ? AppColors.darkBackground
                                    : Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor().withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
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
                  color: isDarkMode ? AppColors.subtleText : Colors.black54,
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
                  color:
                      isDarkMode
                          ? AppColors.primaryBlue
                          : AppColors.primaryPurple,
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
    // Social app usernames
    if (name == 'Alex' || name == 'Jessica') return AppColors.primaryBlue;
    if (name == 'SocialBuzz' || name == 'PartyPeople')
      return AppColors.primaryOrange;
    if (name == 'GamingCrew' || name == 'Michael')
      return AppColors.primaryGreen;
    if (name == 'TravelGroup' || name == 'Emma') return AppColors.primaryPurple;
    if (name == 'FitnessFam' || name == 'Carlos')
      return AppColors.primaryYellow;
    // Default color for other users
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
      default:
        return Colors.grey;
    }
  }
}
