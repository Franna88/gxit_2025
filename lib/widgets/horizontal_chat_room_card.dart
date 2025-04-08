import 'package:flutter/material.dart';
import '../constants.dart';

class HorizontalChatRoomCard extends StatefulWidget {
  final String name;
  final String lastMessage;
  final DateTime lastActivity;
  final int memberCount;
  final bool hasUnreadMessages;
  final int unreadCount;
  final VoidCallback onTap;

  const HorizontalChatRoomCard({
    Key? key,
    required this.name,
    required this.lastMessage,
    required this.lastActivity,
    required this.memberCount,
    this.hasUnreadMessages = false,
    this.unreadCount = 0,
    required this.onTap,
  }) : super(key: key);

  @override
  State<HorizontalChatRoomCard> createState() => _HorizontalChatRoomCardState();
}

class _HorizontalChatRoomCardState extends State<HorizontalChatRoomCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });

    if (isHovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  Color _getTopicColor() {
    if (widget.name.contains('Photo') || widget.name.contains('Image')) {
      return AppColors.primaryBlue;
    } else if (widget.name.contains('Music') ||
        widget.name.contains('Festival')) {
      return AppColors.primaryPurple;
    } else if (widget.name.contains('Travel') ||
        widget.name.contains('Adventure')) {
      return AppColors.primaryGreen;
    } else if (widget.name.contains('Game') || widget.name.contains('Gaming')) {
      return AppColors.primaryOrange;
    } else {
      return AppColors.primaryYellow;
    }
  }

  String _getTargetAudience() {
    if (widget.name.contains('Photo') || widget.name.contains('Image')) {
      return 'For Visual Artists & Photographers';
    } else if (widget.name.contains('Music') ||
        widget.name.contains('Festival')) {
      return 'For Music Lovers & Festival Goers';
    } else if (widget.name.contains('Travel') ||
        widget.name.contains('Adventure')) {
      return 'For Explorers & Wanderers';
    } else if (widget.name.contains('Game') || widget.name.contains('Gaming')) {
      return 'For Gamers & E-Sports Fans';
    } else if (widget.name.contains('Tech')) {
      return 'For Tech Enthusiasts & Innovators';
    } else if (widget.name.contains('Movie')) {
      return 'For Film Buffs & Cinema Lovers';
    } else {
      return 'Community Space';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _getTopicColor();
    final targetAudience = _getTargetAudience();

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          final hoverValue = _hoverController.value;

          return GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 220,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withOpacity(0.2 + (0.1 * hoverValue)),
                    const Color(0xFF1A1A2E),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentColor.withOpacity(0.3 + (0.3 * hoverValue)),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.2 + (0.3 * hoverValue)),
                    blurRadius: 10 * (1 + hoverValue),
                    spreadRadius: 1 * (1 + hoverValue),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room name with status indicator
                  Row(
                    children: [
                      Container(
                        height: 12,
                        width: 12,
                        decoration: BoxDecoration(
                          color:
                              widget.hasUnreadMessages
                                  ? AppColors.primaryGreen
                                  : accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (widget.hasUnreadMessages
                                      ? AppColors.primaryGreen
                                      : accentColor)
                                  .withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.name,
                          style: TextStyle(
                            fontSize: 16 + (2 * hoverValue),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: accentColor.withOpacity(0.7),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Target audience label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(
                        0.15 + (0.05 * hoverValue),
                      ),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: accentColor.withOpacity(
                          0.2 + (0.1 * hoverValue),
                        ),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      targetAudience,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Message preview
                  Expanded(
                    child: Text(
                      widget.lastMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade300,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Bottom info row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Member count
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.memberCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),

                      // Unread count badge
                      if (widget.hasUnreadMessages && widget.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen.withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            widget.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
