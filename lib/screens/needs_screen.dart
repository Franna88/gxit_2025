import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants.dart';
import 'home_screen.dart';
import '../services/user_service.dart';

class NeedsScreen extends StatefulWidget {
  final String userId;

  const NeedsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<NeedsScreen> createState() => _NeedsScreenState();
}

class _NeedsScreenState extends State<NeedsScreen>
    with TickerProviderStateMixin {
  final Set<String> _selectedNeeds = {};
  bool _isSubmitting = false;

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Particle> _particles = [];
  final int particleCount = 15;

  // List of need options
  final List<String> _needOptions = [
    'Food',
    'Hydration',
    'New Teeth',
    'Deodorant',
    'A Shower',
    'Glasses',
    'A Green Card',
    'To Escape from Prison',
    'A Sun Tan',
    'A Haircut',
    'A Break',
    'Sleep',
    'Fresh Air',
    'Exercise',
    'Medical Attention',
    'A Job',
    'More Time',
    'A New Phone',
    'Better Internet',
    'A Vacation',
    'A Hug',
    'Therapy',
    'Coffee',
    'Motivation',
    'A Massage',
    'A Good Book',
    'A New Passport',
    'Meditation',
    'Less Stress',
    'Better Friends',
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

  void _submitNeeds() async {
    if (_selectedNeeds.isEmpty) {
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
      // Update user with needs
      final userService = UserService();
      await userService.updateUserProfile(
        userId: widget.userId,
        needs: _selectedNeeds.join(', '),
      );

      if (mounted) {
        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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
                        "I NEED:",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: AppColors.primaryYellow.withOpacity(0.8),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "SELECT ALL THAT YOU REQUIRE",
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
                        children: _needOptions.map((option) {
                          final isSelected = _selectedNeeds.contains(option);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                // Toggle selection
                                if (isSelected) {
                                  _selectedNeeds.remove(option);
                                } else {
                                  _selectedNeeds.add(option);
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
                                    ? AppColors.primaryYellow.withOpacity(0.8)
                                    : Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryYellow
                                      : AppColors.subtleText.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryYellow
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
                                          ? Colors.black // Dark text for better contrast on yellow
                                          : AppColors.subtleText,
                                      fontWeight:
                                          isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 5),
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.black, // Dark icon for better contrast on yellow
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
                        "${_selectedNeeds.length} selected",
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
                          onPressed: _isSubmitting ? null : _submitNeeds,
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
                                        AppColors.primaryYellow.withOpacity(0.8),
                                        AppColors.primaryOrange.withOpacity(0.8),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isSubmitting
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: AppColors.primaryYellow
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
                                        color: AppColors.primaryYellow,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      'CONTINUE',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        color: Colors.black, // Dark text for better contrast
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
      canvas.drawLine(Offset(0, i.toDouble()),
          Offset(size.width, i.toDouble()), paint);
    }

    // Vertical lines
    for (var i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i.toDouble(), 0),
          Offset(i.toDouble(), size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 