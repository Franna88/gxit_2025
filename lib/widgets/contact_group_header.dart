import 'package:flutter/material.dart';
import '../constants.dart';

class ContactGroupHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const ContactGroupHeader({
    super.key,
    required this.title,
    required this.count,
    this.isExpanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color neonColor = _getNeonColor(title);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: neonColor,
              letterSpacing: 0.5,
              shadows: [
                Shadow(color: neonColor.withOpacity(0.7), blurRadius: 5),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: neonColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: neonColor.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: neonColor.withOpacity(0.2),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: neonColor,
              ),
            ),
          ),
          const Spacer(),
          if (onToggle != null)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: neonColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: neonColor.withOpacity(0.8),
                  size: 20,
                ),
                onPressed: onToggle,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
        ],
      ),
    );
  }

  Color _getNeonColor(String groupName) {
    switch (groupName) {
      case 'Chat Invites':
        return AppColors.primaryYellow;
      case 'Active Chats':
        return AppColors.primaryBlue;
      default:
        return AppColors.primaryBlue;
    }
  }
}
