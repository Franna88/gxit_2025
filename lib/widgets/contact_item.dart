import 'package:flutter/material.dart';
import '../constants.dart';

enum ContactStatus { online, away, offline, unknown }

class ContactItem extends StatelessWidget {
  final String name;
  final ContactStatus status;
  final bool hasUnreadMessage;
  final VoidCallback onTap;

  const ContactItem({
    super.key,
    required this.name,
    required this.status,
    this.hasUnreadMessage = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.glassDark : AppColors.glassLight,
              borderRadius: BorderRadius.circular(12),
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
                // Status indicator
                _buildStatusIndicator(),
                const SizedBox(width: 12),

                // Contact name
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          hasUnreadMessage
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color: isDarkMode ? Colors.white : AppColors.darkText,
                    ),
                  ),
                ),

                // Message indicator if there's an unread message
                if (hasUnreadMessage)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber,
                    ),
                    child: const Icon(
                      Icons.mail_outline,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color statusColor;

    switch (status) {
      case ContactStatus.online:
        statusColor = AppColors.onlineGreen;
        break;
      case ContactStatus.away:
        statusColor = AppColors.awayYellow;
        break;
      case ContactStatus.offline:
        statusColor = AppColors.offlineRed;
        break;
      case ContactStatus.unknown:
        statusColor = Colors.grey;
        break;
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: statusColor,
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
