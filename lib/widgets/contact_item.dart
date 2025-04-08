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
            // Avatar or profile image with status indicator
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        contact.avatarColor ??
                        AppColors.primaryBlue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child:
                      contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              contact.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Center(
                                    child: Text(
                                      contact.name.isNotEmpty
                                          ? contact.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color:
                                            isDarkMode
                                                ? AppColors.primaryBlue
                                                : AppColors.darkText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                            ),
                          )
                          : Center(
                            child: Text(
                              contact.name.isNotEmpty
                                  ? contact.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? AppColors.primaryBlue
                                        : AppColors.darkText,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                ),
                // Status indicator
                if (status != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status!),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isDarkMode
                                  ? AppColors.darkBackground
                                  : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
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
        return Colors.green;
      case ContactStatus.away:
        return Colors.orange;
      case ContactStatus.offline:
        return Colors.grey;
    }
  }
}
