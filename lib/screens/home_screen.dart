import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants.dart';
import '../widgets/chat_summary_card.dart';
import '../widgets/important_message_card.dart';
import '../widgets/activity_card.dart';
import '../widgets/contact_item.dart';
import '../widgets/horizontal_chat_room_card.dart';
import '../widgets/area_chat_room_section.dart';
import 'contacts_screen.dart';
import 'chat_screen.dart';
import 'chats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;

  // Particle system
  final List<Particle> _particles = [];
  final int particleCount = 15; // fewer particles than login for less clutter

  // Animation controllers for neon effects
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize particles
    final random = math.Random();
    for (int i = 0; i < particleCount; i++) {
      _particles.add(
        Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 6 + 2, // slightly smaller particles
          speedX: (random.nextDouble() - 0.5) * 0.005, // slower movement
          speedY: (random.nextDouble() - 0.5) * 0.005,
          opacity: random.nextDouble() * 0.5 + 0.2, // more subtle
        ),
      );
    }

    // Pulse animation for neon elements
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animation timer
    Future.delayed(Duration.zero, () {
      _startParticleAnimation();
    });
  }

  void _startParticleAnimation() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          // Move particles
          for (final particle in _particles) {
            particle.x += particle.speedX;
            particle.y += particle.speedY;

            // Wrap around edges
            if (particle.x < 0) particle.x = 1.0;
            if (particle.x > 1) particle.x = 0.0;
            if (particle.y < 0) particle.y = 1.0;
            if (particle.y > 1) particle.y = 0.0;
          }
        });
        _startParticleAnimation();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      // Chats tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatsScreen()),
      );
    } else if (index == 2) {
      // Contacts tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ContactsScreen()),
      );
    } else if (index == 3) {
      // Settings tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _navigateToChat(BuildContext context, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatScreen(
              contactName: name,
              chatRoomId: 'demoRoom', // Use demo room for now
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
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

            // Particle effect
            ..._particles.map((particle) => _buildParticle(particle, size)),

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
                        return Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryPurple,
                                    AppColors.primaryBlue,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withOpacity(
                                      0.5 * _pulseAnimation.value,
                                    ),
                                    blurRadius: 10 * _pulseAnimation.value,
                                    spreadRadius: 2 * _pulseAnimation.value,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/gxit_logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    actions: [
                      _buildNeonIconButton(Icons.search),
                      _buildNeonIconButton(Icons.notifications_none),
                    ],
                  ),

                  // Welcome section with glow
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Text(
                            'WELCOME TO THE GRID, USER',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
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
                                  blurRadius: 12 * _pulseAnimation.value,
                                  offset: const Offset(2, 1),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Area Chat Rooms Section - No section header needed as it's included in the widget
                  SliverToBoxAdapter(
                    child: AreaChatRoomSection(
                      onRoomTap: (name) => _navigateToChat(context, name),
                    ),
                  ),

                  // Recent Chats header
                  _buildSectionHeader('Recent Chats'),

                  // Recent Contacts List
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 140,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          ChatSummaryCard(
                            name: 'Alex',
                            lastMessage: 'Hey, are you free tonight?',
                            unreadCount: 3,
                            status: ContactStatus.online,
                            onTap: () => _navigateToChat(context, 'Alex'),
                          ),
                          ChatSummaryCard(
                            name: 'Emma',
                            lastMessage: 'Check out this photo!',
                            unreadCount: 1,
                            status: ContactStatus.online,
                            onTap: () => _navigateToChat(context, 'Emma'),
                          ),
                          ChatSummaryCard(
                            name: 'Michael',
                            lastMessage: 'Game night tomorrow?',
                            unreadCount: 2,
                            status: ContactStatus.away,
                            onTap: () => _navigateToChat(context, 'Michael'),
                          ),
                          ChatSummaryCard(
                            name: 'Jessica',
                            lastMessage: 'Thanks for the birthday wishes!',
                            unreadCount: 0,
                            status: ContactStatus.offline,
                            onTap: () => _navigateToChat(context, 'Jessica'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Important Messages header
                  _buildSectionHeader('Important Messages'),

                  // Important Messages List
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildImportantMessageWithNeon(
                            context,
                            'SocialBuzz',
                            'Party at Emma\'s place this Friday! RSVP by tomorrow evening.',
                            DateTime.now().subtract(const Duration(hours: 2)),
                            () => _navigateToChat(context, 'SocialBuzz'),
                          ),
                          _buildImportantMessageWithNeon(
                            context,
                            'TravelGroup',
                            'REMINDER: Group trip planning meeting tomorrow at 7pm via video call. Please bring destination ideas!',
                            DateTime.now().subtract(const Duration(hours: 5)),
                            () => _navigateToChat(context, 'TravelGroup'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Recent Activity header
                  _buildSectionHeader('Recent Activity'),

                  // Recent Activity List
                  SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            ActivityCard(
                              activityType: ActivityType.newMember,
                              message:
                                  'Carlos and 3 others joined Photography Lovers',
                              timestamp: DateTime.now().subtract(
                                const Duration(hours: 1),
                              ),
                            ),
                            ActivityCard(
                              activityType: ActivityType.fileShared,
                              message:
                                  'Emma shared vacation photos in Travel Adventures',
                              timestamp: DateTime.now().subtract(
                                const Duration(hours: 3),
                              ),
                            ),
                            ActivityCard(
                              activityType: ActivityType.groupCreated,
                              message:
                                  'Michael created a new group "Movie Night"',
                              timestamp: DateTime.now().subtract(
                                const Duration(hours: 5),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNeonBottomNavBar(),
    );
  }

  // Helper method to build a particle
  Widget _buildParticle(Particle particle, Size size) {
    return Positioned(
      left: particle.x * size.width,
      top: particle.y * size.height,
      child: Container(
        width: particle.size,
        height: particle.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(particle.opacity * 0.4),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(particle.opacity * 0.3),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build neon section headers
  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: AppColors.primaryBlue.withOpacity(
                          0.5 * _pulseAnimation.value,
                        ),
                        blurRadius: 8 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(
                          0.2 * _pulseAnimation.value,
                        ),
                        blurRadius: 6 * _pulseAnimation.value,
                        spreadRadius: 1 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    child: Text(
                      'VIEW ALL',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        shadows: [
                          Shadow(
                            color: AppColors.primaryBlue.withOpacity(
                              0.5 * _pulseAnimation.value,
                            ),
                            blurRadius: 4 * _pulseAnimation.value,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build neon icon buttons
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

  // Helper method to build important message cards with neon effect
  Widget _buildImportantMessageWithNeon(
    BuildContext context,
    String sender,
    String message,
    DateTime timestamp,
    VoidCallback onTap,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue.withOpacity(0.15),
                  const Color(0xFF1A1A2E),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(
                    0.2 * _pulseAnimation.value,
                  ),
                  blurRadius: 8 * _pulseAnimation.value,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.flag,
                        size: 16,
                        color: AppColors.primaryOrange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sender,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppColors.darkText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _getTimeText(timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode
                                  ? AppColors.subtleText
                                  : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  // Message
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

  // Bottom navigation bar with neon effect
  Widget _buildNeonBottomNavBar() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(
                  0.3 * _pulseAnimation.value,
                ),
                blurRadius: 10 * _pulseAnimation.value,
                spreadRadius: 0,
                offset: const Offset(0, -1),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: AppColors.primaryBlue.withOpacity(
                  0.2 * _pulseAnimation.value,
                ),
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.primaryBlue,
            unselectedItemColor: Colors.white.withOpacity(0.5),
            selectedLabelStyle: TextStyle(
              shadows: [
                Shadow(
                  color: AppColors.primaryBlue.withOpacity(
                    0.8 * _pulseAnimation.value,
                  ),
                  blurRadius: 10 * _pulseAnimation.value,
                ),
              ],
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Chats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Contacts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}

// Particle class for background effect
class Particle {
  double x;
  double y;
  final double size;
  final double speedX;
  final double speedY;
  final double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });
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
