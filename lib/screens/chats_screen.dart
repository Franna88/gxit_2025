import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/chat_room_card.dart';
import '../services/chat_service.dart';
import '../services/location_service.dart';
import '../models/area_chat_room.dart';
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

  // Location service to get area chat rooms
  final _locationService = LocationService();
  List<AreaChatRoom> _areaChatRooms = [];
  List<AreaChatRoom> _privateChatRooms = [];
  bool _isLoading = true;

  // Animation controllers for each card's hover effect
  final Map<int, AnimationController> _hoverControllers = {};
  bool _isHovering = false;
  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();

    // Load chat rooms
    _loadChatRooms();

    // Pulse animation for neon elements
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize hover animations for each card
    for (int i = 0; i < 12; i++) {
      _hoverControllers[i] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  Future<void> _loadChatRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final officialRooms = await _locationService.getOfficialAreaChatRooms();
      final privateRooms = await _locationService.getPrivateChatRooms();

      setState(() {
        _areaChatRooms = officialRooms;
        _privateChatRooms = privateRooms;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading chat rooms: $e');
      setState(() {
        _isLoading = false;
      });
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

  String _getTargetAudience(String name, String areaName) {
    if (name.contains("Main Beach") || name.contains("Supertubes")) {
      return 'For Surfers & Beach Lovers';
    } else if (name.contains("Marina")) {
      return 'For Marina Residents & Visitors';
    } else if (name.contains("Francis")) {
      return 'For St Francis Bay Locals';
    } else if (name.contains("Photography") || name.contains("Photo")) {
      return 'For Visual Artists & Photographers';
    } else if (name.contains("Surf") || name.contains("Beach")) {
      return 'For Surfers & Beach Enthusiasts';
    } else if (name.contains("Restaurant") || name.contains("Food")) {
      return 'For Foodies & Culinary Enthusiasts';
    } else if (name.contains("Fishing")) {
      return 'For Fishing Enthusiasts';
    } else if (name.contains("Golf")) {
      return 'For Golf Enthusiasts';
    } else if (name.contains("Extreme")) {
      return 'For Adventure Seekers';
    } else if (name.contains("Cleanup") || name.contains("Environment")) {
      return 'For Environmental Activists';
    } else {
      return 'Community Space in ' + areaName;
    }
  }

  // Get color based on chat room name
  Color _getRoomColor(String name) {
    if (name.contains("Main Beach") ||
        name.contains("Surf") ||
        name.contains("Beach")) {
      return AppColors.primaryBlue;
    } else if (name.contains("Marina") || name.contains("St Francis")) {
      return AppColors.primaryPurple;
    } else if (name.contains("Aston") ||
        name.contains("Paradise") ||
        name.contains("Cleanup")) {
      return AppColors.primaryGreen;
    } else if (name.contains("Photography") || name.contains("Extreme")) {
      return AppColors.primaryOrange;
    } else if (name.contains("Restaurant") || name.contains("Fish")) {
      return AppColors.primaryYellow;
    } else {
      return AppColors.primaryBlue; // Default
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
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomScrollView(
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
                                  'JEFFREYS BAY CHAT ROOMS',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                    shadows: [
                                      Shadow(
                                        color: AppColors.primaryBlue
                                            .withOpacity(
                                              0.7 * _pulseAnimation.value,
                                            ),
                                        blurRadius: 10 * _pulseAnimation.value,
                                      ),
                                      Shadow(
                                        color: AppColors.primaryPurple
                                            .withOpacity(
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

                          // Section header for Area Chat Rooms
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'AREA CHAT ROOMS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.primaryBlue.withOpacity(
                                        0.7,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Area Chat Rooms Grid
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.85,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index >= _areaChatRooms.length) {
                                    return _buildCreateNewRoomTile();
                                  }

                                  final room = _areaChatRooms[index];
                                  final color = _getRoomColor(room.name);

                                  return _buildRoomTileFromRoom(
                                    index,
                                    room,
                                    color,
                                  );
                                },
                                childCount:
                                    _areaChatRooms.length +
                                    1, // +1 for "Create New" tile
                              ),
                            ),
                          ),

                          // Section header for Private Chat Rooms
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Text(
                                'PRIVATE CHAT ROOMS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.primaryPurple
                                          .withOpacity(0.7),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Private Chat Rooms Grid
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.85,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                if (index >= _privateChatRooms.length) {
                                  return null;
                                }

                                final room = _privateChatRooms[index];
                                final color = _getRoomColor(room.name);

                                return _buildRoomTileFromRoom(
                                  index + _areaChatRooms.length,
                                  room,
                                  color,
                                );
                              }, childCount: _privateChatRooms.length),
                            ),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildRoomTileFromRoom(
    int index,
    AreaChatRoom room,
    Color accentColor,
  ) {
    final random = DateTime.now().millisecond % 2 == 0;
    final hasUnread = random;
    final unreadCount = hasUnread ? ((DateTime.now().second % 5) + 1) : 0;
    final targetAudience = _getTargetAudience(room.name, room.areaName);

    // Generate a plausible last message
    String lastMessage = '';
    if (room.name.contains('Surf')) {
      lastMessage = 'The waves look amazing today! 🌊';
    } else if (room.name.contains('Restaurant')) {
      lastMessage = 'Has anyone tried the new seafood place?';
    } else if (room.name.contains('Marina')) {
      lastMessage = 'Meeting at the clubhouse at 6pm';
    } else if (room.name.contains('Fish')) {
      lastMessage = 'Caught a 5kg yellowtail today! 🐟';
    } else if (room.name.contains('Beach')) {
      lastMessage = 'Beach day tomorrow if weather holds!';
    } else if (room.name.contains('Golf')) {
      lastMessage = 'Anyone up for a round this weekend?';
    } else if (room.name.contains('Photography')) {
      lastMessage = 'Sunset photos from Paradise Beach 📸';
    } else {
      lastMessage = 'Join the conversation in ${room.areaName}';
    }

    return _buildRoomTile(
      index,
      room.name,
      lastMessage,
      room.createdAt ?? DateTime.now().subtract(const Duration(hours: 5)),
      room.memberCount,
      hasUnread,
      unreadCount,
      accentColor,
      targetAudience: targetAudience,
    );
  }

  Widget _buildRoomTile(
    int index,
    String roomName,
    String lastMessage,
    DateTime lastActivity,
    int memberCount,
    bool hasUnreadMessages,
    int unreadCount,
    Color accentColor, {
    String? targetAudience,
  }) {
    return MouseRegion(
      onEnter: (_) => _onHover(index, true),
      onExit: (_) => _onHover(index, false),
      child: AnimatedBuilder(
        animation: _hoverControllers[index] ?? _pulseController,
        builder: (context, child) {
          final hoverValue = _hoverControllers[index]?.value ?? 0.0;

          return GestureDetector(
            onTap: () => _navigateToChat(context, roomName),
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
                    color: accentColor.withOpacity(0.2 + (0.3 * hoverValue)),
                    blurRadius: 10 * (1 + hoverValue),
                    spreadRadius: 1 * (1 + hoverValue),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room name
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
                            roomName,
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

                    const SizedBox(height: 8),

                    // Target audience
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
                        targetAudience ?? _getTargetAudience(roomName, ''),
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

                    const SizedBox(height: 8),

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
                              memberCount.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),

                        // Time or unread count
                        hasUnreadMessages && unreadCount > 0
                            ? Container(
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
                                      0.5,
                                    ),
                                    blurRadius: 5,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                            : Text(
                              _getTimeText(lastActivity),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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

  Widget _buildCreateNewRoomTile() {
    return GestureDetector(
      onTap: () {
        _showCreateRoomDialog(context);
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(
                  0.3 * _pulseAnimation.value,
                ),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(
                            0.3 * _pulseAnimation.value,
                          ),
                          blurRadius: 10 * _pulseAnimation.value,
                          spreadRadius: 0,
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(
                          0.5 * _pulseAnimation.value,
                        ),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 30,
                      color: AppColors.primaryBlue.withOpacity(
                        0.5 + (0.5 * _pulseAnimation.value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CREATE NEW ROOM',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue.withOpacity(
                        0.7 + (0.3 * _pulseAnimation.value),
                      ),
                      letterSpacing: 1.0,
                      shadows: [
                        Shadow(
                          color: AppColors.primaryBlue.withOpacity(
                            0.5 * _pulseAnimation.value,
                          ),
                          blurRadius: 5 * _pulseAnimation.value,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateRoomDialog(BuildContext context) {
    // Check if enough tokens are available
    final enoughTokens = true; // This would be a real check in a real app

    if (!enoughTokens) {
      showDialog(
        context: context,
        builder:
            (context) => NotEnoughTokensDialog(
              requiredTokens: 50,
              currentTokens: 0,
              onBuyTokens: () {
                // Do nothing for now
              },
            ),
      );
      return;
    }

    // Show room creation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.primaryBlue, width: 1),
            ),
            title: const Text(
              'Create New Chat Room',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Feature coming soon in the next update!',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                ),
                child: const Text('OK'),
              ),
            ],
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

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(
                  0.4 * _pulseAnimation.value,
                ),
                blurRadius: 15 * _pulseAnimation.value,
                spreadRadius: 2 * _pulseAnimation.value,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => _showCreateRoomDialog(context),
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
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
