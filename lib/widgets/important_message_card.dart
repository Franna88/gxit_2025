import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';

class ImportantMessageCard extends StatelessWidget {
  final String senderName;
  final String message;
  final DateTime timestamp;
  final VoidCallback onTap;

  const ImportantMessageCard({
    super.key,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('h:mm a');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? AppColors.darkSecondaryBackground
                  : AppColors.glassLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDarkMode
                    ? AppColors.primaryOrange.withOpacity(0.3)
                    : AppColors.primaryOrange.withOpacity(0.5),
            width: isDarkMode ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with sender name and timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flag,
                        color: AppColors.primaryOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    timeFormat.format(timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? AppColors.subtleText : Colors.black54,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Message content
              Text(
                message,
                style: TextStyle(
                  color:
                      isDarkMode
                          ? Colors.white.withOpacity(0.9)
                          : AppColors.darkText.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    context,
                    'Reply',
                    Icons.reply,
                    AppColors.primaryBlue,
                    onTap,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    context,
                    'Mark Read',
                    Icons.check_circle_outline,
                    AppColors.primaryGreen,
                    () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDarkMode ? color.withOpacity(0.15) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
