import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/contact.dart';

enum ContactStatus { online, away, offline }

class ContactItem extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;
  final ContactStatus? status;

  const ContactItem({
    super.key,
    required this.contact,
    required this.onTap,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 6.0),
              decoration: BoxDecoration(
                color:
                    status != null
                        ? _getStatusColor(status!)
                        : Colors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
                boxShadow:
                    status != null
                        ? [
                          BoxShadow(
                            color: _getStatusColor(status!).withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                        : null,
              ),
            ),

            // Contact information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
            // Favorite icon if applicable
            if (contact.isFavorite)
              Icon(Icons.star, color: AppColors.primaryYellow, size: 20),
          ],
        ),
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
        return Colors.grey;
    }
  }
}
