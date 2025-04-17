import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../constants.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../widgets/token_balance.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Particle system
  final List<Particle> _particles = [];
  final int particleCount = 15;

  // User service
  final UserService _userService = UserService();
  UserModel? _currentUser;
  bool _isLoadingUser = true;

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
          size: random.nextDouble() * 6 + 2,
          speedX: (random.nextDouble() - 0.5) * 0.005,
          speedY: (random.nextDouble() - 0.5) * 0.005,
          opacity: random.nextDouble() * 0.5 + 0.2,
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

    // Load user data
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUser = true;
    });

    try {
      final user = await _userService.currentUser;

      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
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

  void _logout() async {
    try {
      await _userService.signOut();

      if (mounted) {
        // Navigate to login screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: ${e.toString()}')),
      );
    }
  }

  Widget _buildSettingOption({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isDestructive
                      ? Colors.red.withOpacity(0.4 * _pulseAnimation.value)
                      : AppColors.primaryBlue.withOpacity(
                        0.4 * _pulseAnimation.value,
                      ),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    isDestructive
                        ? Colors.red.withOpacity(0.1 * _pulseAnimation.value)
                        : AppColors.primaryBlue.withOpacity(
                          0.1 * _pulseAnimation.value,
                        ),
                blurRadius: 8 * _pulseAnimation.value,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isDestructive
                                  ? Colors.red.withOpacity(
                                    0.3 * _pulseAnimation.value,
                                  )
                                  : AppColors.primaryBlue.withOpacity(
                                    0.3 * _pulseAnimation.value,
                                  ),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color:
                            isDestructive ? Colors.red : AppColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDestructive ? Colors.red : Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color:
                          isDestructive
                              ? Colors.red.withOpacity(0.7)
                              : AppColors.subtleText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.subtleText,
          letterSpacing: 2,
          shadows: [
            Shadow(
              color: AppColors.primaryBlue.withOpacity(0.5),
              blurRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "SETTINGS",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: AppColors.primaryBlue.withOpacity(0.8),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
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
              child: ListView(
                children: [
                  const SizedBox(height: 16),

                  // Profile section
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primaryBlue.withOpacity(
                                0.4 * _pulseAnimation.value,
                              ),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(
                                  0.2 * _pulseAnimation.value,
                                ),
                                blurRadius: 15 * _pulseAnimation.value,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black,
                                  border: Border.all(
                                    color: AppColors.primaryBlue.withOpacity(
                                      0.6 * _pulseAnimation.value,
                                    ),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withOpacity(
                                        0.3 * _pulseAnimation.value,
                                      ),
                                      blurRadius: 10 * _pulseAnimation.value,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_isLoadingUser)
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else ...[
                                Text(
                                  _currentUser?.name ?? "USER",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _currentUser?.email ?? "",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Add Token Balance
                                const TokenBalance(),
                                const SizedBox(height: 8),
                                Text(
                                  "ACTIVE STATUS: ONLINE",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryBlue,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  _buildSectionHeader('Account'),

                  _buildSettingOption(
                    title: 'Edit Profile',
                    icon: Icons.edit,
                    onTap: () {
                      // Navigate to edit profile screen
                    },
                  ),

                  _buildSettingOption(
                    title: 'Privacy & Security',
                    icon: Icons.security,
                    onTap: () {
                      // Navigate to privacy settings
                    },
                  ),

                  _buildSettingOption(
                    title: 'Notifications',
                    icon: Icons.notifications,
                    onTap: () {
                      // Navigate to notification settings
                    },
                  ),

                  _buildSectionHeader('General'),

                  _buildSettingOption(
                    title: 'Display & Accessibility',
                    icon: Icons.palette,
                    onTap: () {
                      // Navigate to display settings
                    },
                  ),

                  _buildSettingOption(
                    title: 'Language',
                    icon: Icons.language,
                    onTap: () {
                      // Navigate to language settings
                    },
                  ),

                  _buildSettingOption(
                    title: 'Help & Support',
                    icon: Icons.help,
                    onTap: () {
                      // Navigate to help center
                    },
                  ),

                  _buildSectionHeader('Session'),

                  _buildSettingOption(
                    title: 'Logout',
                    icon: Icons.logout,
                    onTap: _logout,
                    isDestructive: true,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
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
