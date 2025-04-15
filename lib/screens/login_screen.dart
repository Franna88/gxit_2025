import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  // 3D rotation controllers and values
  late AnimationController _rotationXController;
  late AnimationController _rotationYController;
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  double _lastDragX = 0.0;
  double _lastDragY = 0.0;
  bool _isDragging = false;
  static const double _maxRotation =
      0.5; // Increased max rotation for more noticeable effect

  final List<Particle> _particles = [];
  final int particleCount = 20;

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
          size: random.nextDouble() * 10 + 2,
          speedX: (random.nextDouble() - 0.5) * 0.01,
          speedY: (random.nextDouble() - 0.5) * 0.01,
          opacity: random.nextDouble() * 0.7 + 0.3,
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

    // Logo rotation animation
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20000),
    )..repeat();

    // Logo floating animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // 3D rotation controllers
    _rotationXController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _rotationYController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Add listeners to restore to center position
    _rotationXController.addListener(() {
      setState(() {
        _rotationX = _rotationXController.value;
      });
    });

    _rotationYController.addListener(() {
      setState(() {
        _rotationY = _rotationYController.value;
      });
    });

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
    _usernameController.dispose();
    _passwordController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _floatController.dispose();
    _rotationXController.dispose();
    _rotationYController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get email and password from controllers
      final email = _usernameController.text.trim();
      final password = _passwordController.text;

      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter both email and password')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Attempt to sign in with Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Ensure user exists in Firestore
      final userService = UserService();
      await userService.ensureUserExists(userCredential.user!);

      if (mounted) {
        // Navigate to home screen on success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      String errorMessage = 'Authentication failed';

      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      // Handle other errors
      print('Login error: ${e.toString()}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /* Commented out Google Sign-In functionality for now
  void _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userService = UserService();
      final userCredential = await userService.signInWithGoogle();

      if (userCredential != null && mounted) {
        // Navigate to home screen on success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      // Handle errors
      print('Google Sign-In error: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  */

  // Add new pan gesture handlers
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _lastDragX = details.globalPosition.dx;
      _lastDragY = details.globalPosition.dy;
    });

    // Stop any ongoing animations
    _rotationXController.stop();
    _rotationYController.stop();

    // Optionally pause other animations
    // _floatController.stop();
    // _rotateController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final dx = details.globalPosition.dx - _lastDragX;
    final dy = details.globalPosition.dy - _lastDragY;

    // Higher sensitivity for more immediate response
    const sensitivity = 0.5;

    setState(() {
      // Y rotation is affected by X movement (swipe left/right)
      _rotationY += (dx / 100) * sensitivity;
      _rotationY = _rotationY.clamp(-_maxRotation, _maxRotation);

      // X rotation is affected by Y movement (swipe up/down)
      _rotationX += (dy / 100) * sensitivity;
      _rotationX = _rotationX.clamp(-_maxRotation, _maxRotation);

      // Update last position
      _lastDragX = details.globalPosition.dx;
      _lastDragY = details.globalPosition.dy;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    // Animate back to center with spring effect
    _rotationXController.value = _rotationX;
    _rotationYController.value = _rotationY;

    _rotationXController.animateTo(
      0,
      curve: Curves.elasticOut,
      duration: const Duration(milliseconds: 1200),
    );

    _rotationYController.animateTo(
      0,
      curve: Curves.elasticOut,
      duration: const Duration(milliseconds: 1200),
    );

    // Resume other animations if needed
    // _floatController.repeat(reverse: true);
    // _rotateController.repeat();
  }

  // Add this method for handling sign up
  void _showSignUpDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Floating and pulsing logo
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: GestureDetector(
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              _pulseController,
                              _floatController,
                              _rotateController,
                            ]),
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _floatAnimation.value),
                                child: Transform(
                                  transform:
                                      Matrix4.identity()
                                        ..setEntry(
                                          3,
                                          2,
                                          0.001,
                                        ) // Perspective effect
                                        ..rotateX(_rotationX)
                                        ..rotateY(_rotationY)
                                        ..rotateZ(
                                          _rotateController.value *
                                              2 *
                                              math.pi *
                                              0.05,
                                        ),
                                  alignment: Alignment.center,
                                  child: Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Glow effect
                                        Container(
                                          width: size.width * 0.5,
                                          height: size.width * 0.5,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(
                                              0xFF0A0A18,
                                            ).withOpacity(0.8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primaryBlue
                                                    .withOpacity(0.3),
                                                blurRadius: 40,
                                                spreadRadius: 20,
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Logo
                                        Hero(
                                          tag: 'logo',
                                          child: Container(
                                            width: size.width * 0.45,
                                            height: size.width * 0.45,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color(0xFF0A0A18),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primaryBlue
                                                      .withOpacity(0.2),
                                                  blurRadius: 15,
                                                  spreadRadius: 1,
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
                                        ),

                                        // Circular neon ring
                                        Container(
                                          width: size.width * 0.55,
                                          height: size.width * 0.55,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.primaryBlue
                                                  .withOpacity(0.3),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Login form
                    Expanded(flex: 6, child: _buildLoginForm()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form title with cyber-styled text
          Text(
            "LOGIN",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: AppColors.primaryBlue.withOpacity(0.8),
                  blurRadius: 8,
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          Text(
            "ACCESS YOUR NETWORK",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.subtleText,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Username field
          _buildCyberTextField(
            controller: _usernameController,
            label: 'IDENTITY',
            prefixIcon: Icons.person_outline,
          ),

          const SizedBox(height: 16),

          // Password field
          _buildCyberTextField(
            controller: _passwordController,
            label: 'PASSCODE',
            isPassword: true,
            prefixIcon: Icons.lock_outline,
          ),

          const SizedBox(height: 12),

          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              child: const Text('RESET PASSCODE'),
            ),
          ),

          const SizedBox(height: 24),

          // Login button with neon effect
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
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
                  gradient:
                      _isLoading
                          ? null
                          : LinearGradient(
                            colors: [
                              AppColors.primaryBlue.withOpacity(0.8),
                              AppColors.primaryPurple.withOpacity(0.8),
                            ],
                          ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      _isLoading
                          ? null
                          : [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                ),
                child: Container(
                  alignment: Alignment.center,
                  child:
                      _isLoading
                          ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.primaryBlue,
                              strokeWidth: 3,
                            ),
                          )
                          : const Text(
                            'CONNECT',
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

          const SizedBox(height: 20),

          // Sign up text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'NEW USER? ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.subtleText,
                  letterSpacing: 1,
                ),
              ),
              TextButton(
                onPressed: () {
                  _showSignUpDialog();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                child: const Text('REGISTER'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCyberTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(color: Colors.white, letterSpacing: 1),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.subtleText,
            fontSize: 12,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(prefixIcon, color: AppColors.subtleText, size: 20),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.subtleText,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
}

// Data class for particles
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

// Custom painter for grid effect
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
