import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/chat_room_card.dart';
import '../services/chat_service.dart';
import '../widgets/not_enough_tokens_dialog.dart';
import '../widgets/token_balance.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Animation controllers for each card's hover effect
  final Map<int, AnimationController> _hoverControllers = {};
  bool _isHovering = false;
  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();

    // Pulse animation for neon elements
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize hover animations for each card
    for (int i = 0; i < 6; i++) {
      _hoverControllers[i] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    for (var controller in _hoverControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _navigateToChat(BuildContext context, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen(contactName: name)),
    );
  }

  void _onHover(int index, bool isHovering) {
    setState(() {
      _isHovering = isHovering;
      _hoveredIndex = isHovering ? index : -1;
    });

    if (isHovering) {
      _hoverControllers[index]?.forward();
    } else {
      _hoverControllers[index]?.reverse();
    }
  }

  String _getTargetAudience(String name) {
    if (name.contains('Photo') || name.contains('Image')) {
      return 'For Visual Artists & Photographers';
    } else if (name.contains('Music') || name.contains('Festival')) {
      return 'For Music Lovers & Festival Goers';
    } else if (name.contains('Travel') || name.contains('Adventure')) {
      return 'For Explorers & Wanderers';
    } else if (name.contains('Game') || name.contains('Gaming')) {
      return 'For Gamers & E-Sports Fans';
    } else if (name.contains('Tech')) {
      return 'For Tech Enthusiasts & Innovators';
    } else if (name.contains('Movie')) {
      return 'For Film Buffs & Cinema Lovers';
    } else {
      return 'Community Space';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Rooms'),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          // Add token balance in the AppBar
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TokenBalance(isCompact: true, showLabel: false),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F0F1A),
              AppColors.primaryPurple.withOpacity(0.8),
              const Color(0xFF0A0A18),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Grid background
            Positioned.fill(child: CustomPaint(painter: GridPainter())),

            // Main content
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  // App Bar with neon glow
                  SliverAppBar(
                    floating: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Text(
                          'CHAT ROOMS',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: AppColors.primaryBlue.withOpacity(
                                  0.7 * _pulseAnimation.value,
                                ),
                                blurRadius: 10 * _pulseAnimation.value,
                              ),
                              Shadow(
                                color: AppColors.primaryPurple.withOpacity(
                                  0.5 * _pulseAnimation.value,
                                ),
                                blurRadius: 15 * _pulseAnimation.value,
                                offset: const Offset(2, 1),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      _buildNeonIconButton(Icons.search),
                      _buildNeonIconButton(Icons.add),
                    ],
                  ),

                  // Chat Rooms Grid
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      delegate: SliverChildListDelegate([
                        _buildRoomTile(
                          0,
                          'Photography Lovers',
                          'Emma: Check out my new portrait shots!',
                          DateTime.now().subtract(const Duration(minutes: 5)),
                          126,
                          true,
                          3,
                          AppColors.primaryBlue,
                        ),
                        _buildRoomTile(
                          1,
                          'Music Festival',
                          "Alex: Who's going to Coachella this year?",
                          DateTime.now().subtract(const Duration(hours: 1)),
                          84,
                          true,
                          5,
                          AppColors.primaryPurple,
                        ),
                        _buildRoomTile(
                          2,
                          'Travel Adventures',
                          'Rachel: Just booked my flight to Thailand!',
                          DateTime.now().subtract(const Duration(hours: 6)),
                          53,
                          false,
                          0,
                          AppColors.primaryGreen,
                        ),
                        _buildRoomTile(
                          3,
                          'Gaming Squad',
                          'Michael: Anyone up for Fortnite tonight?',
                          DateTime.now().subtract(const Duration(days: 1)),
                          98,
                          false,
                          0,
                          AppColors.primaryOrange,
                        ),
                        _buildRoomTile(
                          4,
                          'Tech Enthusiasts',
                          'David: Have you seen the new AI advancements?',
                          DateTime.now().subtract(const Duration(days: 2)),
                          142,
                          false,
                          0,
                          AppColors.primaryYellow,
                        ),
                        _buildRoomTile(
                          5,
                          'Movie Club',
                          'Sarah: The new Marvel movie was amazing!',
                          DateTime.now().subtract(const Duration(days: 3)),
                          72,
                          false,
                          0,
                          AppColors.primaryPurple,
                        ),
                        _buildCreateNewRoomTile(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(
                    0.5 * _pulseAnimation.value,
                  ),
                  blurRadius: 12 * _pulseAnimation.value,
                  spreadRadius: 2 * _pulseAnimation.value,
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.primaryBlue,
              child: const Icon(Icons.add_comment, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNeonIconButton(IconData icon) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(
                  0.3 * _pulseAnimation.value,
                ),
                blurRadius: 8 * _pulseAnimation.value,
                spreadRadius: 1 * _pulseAnimation.value,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: () {},
          ),
        );
      },
    );
  }

  Widget _buildRoomTile(
    int index,
    String name,
    String lastMessage,
    DateTime lastActivity,
    int memberCount,
    bool hasUnreadMessages,
    int unreadCount,
    Color accentColor,
  ) {
    final targetAudience = _getTargetAudience(name);

    return MouseRegion(
      onEnter: (_) => _onHover(index, true),
      onExit: (_) => _onHover(index, false),
      child: AnimatedBuilder(
        animation: _hoverControllers[index] ?? _pulseController,
        builder: (context, child) {
          final hoverValue = _hoverControllers[index]?.value ?? 0.0;
          final pulseValue = _pulseAnimation.value;

          return GestureDetector(
            onTap: () => _navigateToChat(context, name),
            child: Container(
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
                    color: accentColor.withOpacity(
                      (0.2 * pulseValue) + (0.3 * hoverValue),
                    ),
                    blurRadius: 10 * (pulseValue + hoverValue),
                    spreadRadius: 1 * (pulseValue + hoverValue),
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
                              hasUnreadMessages
                                  ? AppColors.primaryGreen
                                  : accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (hasUnreadMessages
                                      ? AppColors.primaryGreen
                                      : accentColor)
                                  .withOpacity(0.5 * pulseValue),
                              blurRadius: 8 * pulseValue,
                              spreadRadius: 1 * pulseValue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16 + (2 * hoverValue),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: accentColor.withOpacity(
                                  0.7 * pulseValue,
                                ),
                                blurRadius: 5 * pulseValue,
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
                      lastMessage,
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
                            '$memberCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),

                      // Unread count badge
                      if (hasUnreadMessages && unreadCount > 0)
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
                                color: AppColors.primaryGreen.withOpacity(
                                  0.5 * pulseValue,
                                ),
                                blurRadius: 6 * pulseValue,
                                spreadRadius: 1 * pulseValue,
                              ),
                            ],
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      // Time indicator
                      Text(
                        _getTimeText(lastActivity),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
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

  Widget _buildCreateNewRoomTile() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = _pulseAnimation.value;

        return GestureDetector(
          onTap: () async {
            // Check if user has enough tokens to create a room
            final chatService = ChatService();
            final tokenBalance = await chatService.getUserTokenBalance();

            if (tokenBalance < 100) {
              NotEnoughTokensDialog.show(
                context: context,
                requiredTokens: 100,
                currentTokens: tokenBalance,
              );
              return;
            }

            // Show dialog to create a new room
            _showCreateRoomDialog(context);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.05 + (0.01 * pulseValue)),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1 + (0.05 * pulseValue)),
                width: 1.5,
                style: BorderStyle.solid,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.1 * pulseValue),
                  blurRadius: 8 * pulseValue,
                  spreadRadius: 1 * pulseValue,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.2),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(
                        0.3 + (0.2 * pulseValue),
                      ),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(
                          0.2 * pulseValue,
                        ),
                        blurRadius: 8 * pulseValue,
                        spreadRadius: 1 * pulseValue,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add,
                    color: AppColors.primaryBlue.withOpacity(
                      0.7 + (0.3 * pulseValue),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Create New Room',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                // Show the token cost
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(
                      0.1 + (0.05 * pulseValue),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(
                        0.3 + (0.1 * pulseValue),
                      ),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.token,
                        size: 14,
                        color: AppColors.primaryBlue.withOpacity(
                          0.7 + (0.3 * pulseValue),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '100',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateRoomDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text(
              'Create New Chat Room',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Room Name',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This will cost 100 tokens',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                ),
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;

                  final chatService = ChatService();
                  try {
                    final roomId = await chatService.createChatRoom(
                      name: nameController.text.trim(),
                      memberIds: [],
                    );

                    if (roomId != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chat room created successfully!'),
                          backgroundColor: AppColors.primaryGreen,
                        ),
                      );
                    }
                    Navigator.pop(context);
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  String _getTimeText(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }
}

// Grid painter for background effect
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.blue.withOpacity(0.1)
          ..strokeWidth = 0.5;

    // Horizontal lines
    final horizontalCount = 15;
    final horizontalSpacing = size.height / horizontalCount;
    for (int i = 0; i <= horizontalCount; i++) {
      final y = i * horizontalSpacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical lines
    final verticalCount = 15;
    final verticalSpacing = size.width / verticalCount;
    for (int i = 0; i <= verticalCount; i++) {
      final x = i * verticalSpacing;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
