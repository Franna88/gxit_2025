import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/contact.dart';

enum ContactStatus { online, away, offline }

class ContactItem extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;
  final ContactStatus? status;
  final String? messageType;

  const ContactItem({
    super.key,
    required this.contact,
    required this.onTap,
    this.status,
    this.messageType,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        child: Row(
          children: [
            // Enhanced neon status indicator
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(right: 16.0),
              decoration: BoxDecoration(
                color:
                    status != null
                        ? _getStatusColor(status!)
                        : Colors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
                boxShadow:
                    status != null
                        ? [
                          // Inner glow
                          BoxShadow(
                            color: _getStatusColor(status!).withOpacity(0.6),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                          // Outer glow
                          BoxShadow(
                            color: _getStatusColor(status!).withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                        : null,
                border: Border.all(
                  color:
                      status != null
                          ? _getStatusColor(status!).withAlpha(100)
                          : Colors.transparent,
                  width: 2,
                ),
              ),
            ),

            // Contact information with aligned baseline
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    contact.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (contact.address.isNotEmpty)
                    Text(
                      contact.address,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDarkMode
                                ? AppColors.subtleText
                                : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Message type indicator
            if (messageType != null && messageType!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 8.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _getMessageTypeColor(messageType!),
                    width: 1,
                  ),
                ),
                child: Text(
                  messageType!,
                  style: TextStyle(
                    color: _getMessageTypeColor(messageType!),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),

            // Enhanced invitation indicator
            if (contact.isFavorite)
              _buildInviteIndicator(context),
          ],
        ),
      ),
    );
  }

  // New method to build an enhanced invite indicator
  Widget _buildInviteIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryOrange,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_active,
            color: AppColors.primaryOrange,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'Invite',
            style: TextStyle(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get the status color
  Color _getStatusColor(ContactStatus status) {
    switch (status) {
      case ContactStatus.online:
        return AppColors.onlineGreen;
      case ContactStatus.away:
        return AppColors.awayYellow;
      case ContactStatus.offline:
        return Colors.grey.shade500;
    }
  }

  // Helper method to get message type color
  Color _getMessageTypeColor(String type) {
    switch (type) {
      case 'Urgent':
        return AppColors.offlineRed;
      case 'Question':
        return AppColors.primaryBlue;
      case 'Follow-up':
        return AppColors.primaryPurple;
      case 'New Message':
      default:
        return AppColors.primaryGreen;
    }
  }
}
