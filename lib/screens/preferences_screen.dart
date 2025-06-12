import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants.dart';
import 'wants_screen.dart';
import '../services/user_service.dart';

class PreferencesScreen extends StatefulWidget {
  final String userId;

  const PreferencesScreen({
    super.key,
    required this.userId,
  });

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen>
    with TickerProviderStateMixin {
  final Set<String> _selectedPreferences = {};
  bool _isSubmitting = false;

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Particle> _particles = [];
  final int particleCount = 15;

  // List of preference options
  final List<String> _preferenceOptions = [
    'Music',
    'Animals',
    'Science',
    'Stars',
    'Tech Gadgets',
    'Pop Culture',
    'Food',
    'Doing Nothing',
    'Sitting',
    'Sleeping',
    'Movies',
    'Cyber Stalking',
    'Insulting People',
    'Comedy',
    'Art',
    'Reading',
    'Gaming',
    'Traveling',
    'Sports',
    'Nature',
  ];

  @override
  void initState() {
    super.initState();

    // Generate particles
    final random = math.Random();
    for (int i = 0; i < particleCount; i++) {
      _particles.add(
        Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 8 + 2,
          speedX: (random.nextDouble() - 0.5) * 0.008,
          speedY: (random.nextDouble() - 0.5) * 0.008,
          opacity: random.nextDouble() * 0.6 + 0.2,
        ),
      );
    }

    // Logo pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
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

  Widget _buildParticle(Particle particle, Size size) {
    return Positioned(
      left: particle.x * size.width,
      top: particle.y * size.height,
      child: Container(
        width: particle.size,
        height: particle.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(particle.opacity * 0.5),
        ),
      ),
    );
  }

  void _submitPreferences() async {
    if (_selectedPreferences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one option to continue'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Update user with preferences
      final userService = UserService();
      await userService.updateUserProfile(
        userId: widget.userId,
        preferences: _selectedPreferences.join(', '),
      );

      if (mounted) {
        // Navigate to wants screen instead of home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WantsScreen(
              userId: widget.userId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Prevent back button navigation
    return WillPopScope(
      onWillPop: () async {
        // Show message that selection is required
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one option to continue'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        // Prevent going back
        return false;
      },
      child: Scaffold(
        // Remove app bar to prevent back navigation
        body: Container(
          width: double.infinity,
          height: double.infinity,
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
              // Particle effect background
              ..._particles.map((particle) => _buildParticle(particle, size)),

              // Neon grid lines
              Positioned.fill(child: CustomPaint(painter: GridPainter())),

              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      // Header
                      Text(
                        "I LIKE:",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: AppColors.primaryBlue.withOpacity(0.8),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "SELECT ALL THAT YOU ENJOY",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.subtleText,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Bubble options
                      Wrap(
                        spacing: 10,
                        runSpacing: 15,
                        alignment: WrapAlignment.center,
                        children: _preferenceOptions.map((option) {
                          final isSelected =
                              _selectedPreferences.contains(option);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                // Toggle selection
                                if (isSelected) {
                                  _selectedPreferences.remove(option);
                                } else {
                                  _selectedPreferences.add(option);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryOrange.withOpacity(0.8)
                                    : Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryOrange
                                      : AppColors.subtleText.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryOrange
                                              .withOpacity(0.5),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    option,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.subtleText,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 5),
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Selected count
                      Text(
                        "${_selectedPreferences.length} selected",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.subtleText,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitPreferences,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: _isSubmitting
                                  ? null
                                  : LinearGradient(
                                      colors: [
                                        AppColors.primaryOrange
                                            .withOpacity(0.8),
                                        AppColors.primaryYellow
                                            .withOpacity(0.8),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isSubmitting
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: AppColors.primaryOrange
                                            .withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                      ),
                                    ],
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: _isSubmitting
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryOrange,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text(
                                      'CONTINUE',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Particle class for background effects
class Particle {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });
}

// Grid background painter
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5;

    // Horizontal lines
    for (var i = 0; i < size.height; i += 30) {
      canvas.drawLine(
          Offset(0, i.toDouble()), Offset(size.width, i.toDouble()), paint);
    }

    // Vertical lines
    for (var i = 0; i < size.width; i += 30) {
      canvas.drawLine(
          Offset(i.toDouble(), 0), Offset(i.toDouble(), size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
