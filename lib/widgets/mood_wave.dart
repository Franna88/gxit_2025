import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/user_mood.dart';

class MoodWave extends StatefulWidget {
  final Map<String, UserMood> participants;
  final double height;
  final double activityLevel;

  const MoodWave({
    super.key,
    required this.participants,
    this.height = 80,
    this.activityLevel = 0.5,
  });

  @override
  State<MoodWave> createState() => _MoodWaveState();
}

class _MoodWaveState extends State<MoodWave> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _flowController;

  @override
  void initState() {
    super.initState();

    // Wave animation controller
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Flow speed controller
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _flowController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MoodWave oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Adjust flow speed based on activity level
    _flowController.duration = Duration(
      milliseconds: (10000 * (1 - widget.activityLevel)).toInt().clamp(
        3000,
        10000,
      ),
    );

    if (!_flowController.isAnimating) {
      _flowController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.participants.isEmpty) {
      return SizedBox(height: widget.height);
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge([_waveController, _flowController]),
        builder: (context, child) {
          return CustomPaint(
            painter: MoodWavePainter(
              participants: widget.participants,
              wavePhase: _waveController.value * 2 * math.pi,
              flowPhase: _flowController.value * 2 * math.pi,
              activityLevel: widget.activityLevel,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class MoodWavePainter extends CustomPainter {
  final Map<String, UserMood> participants;
  final double wavePhase;
  final double flowPhase;
  final double activityLevel;

  MoodWavePainter({
    required this.participants,
    required this.wavePhase,
    required this.flowPhase,
    required this.activityLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a sorted list of participants by mood intensity
    final sortedParticipants =
        participants.entries.toList()..sort(
          (a, b) => a.value.intensityValue.compareTo(b.value.intensityValue),
        );

    // Base wave parameters
    final waveHeight = size.height * 0.5;
    final waveLength = size.width;
    final baseY = size.height * 0.6;

    // Draw each participant's mood wave
    for (int i = 0; i < sortedParticipants.length; i++) {
      final entry = sortedParticipants[i];
      final mood = entry.value;

      // Calculate wave parameters based on mood
      final amplitude = waveHeight * 0.1 * (1 + mood.intensityValue);
      final frequency = 1 + (mood.intensityValue * 2); // Waves per screen
      final speed = flowPhase * (0.5 + mood.intensityValue * 0.5);
      final opacity = 0.6 - (i * 0.05).clamp(0, 0.5);

      // Activity modulation
      final activityAmplitude = amplitude * (0.5 + activityLevel * 0.5);
      final turbulence = activityLevel * 5;

      // Create path for the wave
      final path = Path();

      // Start at left edge
      path.moveTo(0, baseY);

      // Draw the wave
      for (double x = 0; x <= size.width; x += 2) {
        // Primary wave
        final mainWave =
            math.sin((x / waveLength) * frequency * 2 * math.pi + speed) *
            activityAmplitude;

        // Secondary modulation
        final modulation =
            math.sin((x / waveLength) * frequency * 3.7 * math.pi + wavePhase) *
            activityAmplitude *
            0.3;

        // Turbulence (random variation based on activity)
        final turb =
            mood.intensityValue > 0.5
                ? math.sin(x * 0.2 + wavePhase * 3) * turbulence
                : 0;

        final y = baseY + mainWave + modulation + turb;
        path.lineTo(x, y);
      }

      // Complete the path
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      // Create gradient from mood colors
      final paint =
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                mood.color.withOpacity(opacity),
                mood.color.withOpacity(0.1),
              ],
            ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
            ..style = PaintingStyle.fill;

      // Draw the wave
      canvas.drawPath(path, paint);

      // Add participant identifier
      final textPainter = TextPainter(
        text: TextSpan(text: mood.emoji, style: const TextStyle(fontSize: 14)),
        textDirection: TextDirection.ltr,
      )..layout();

      // Position emoji on the wave - making sure it's not too close to top or bottom
      final emojiX = waveLength * (0.1 + (i * 0.15)).clamp(0.1, 0.9);
      final rawEmojiY =
          baseY +
          math.sin(emojiX * frequency * 2 * math.pi / waveLength + speed) *
              amplitude -
          18;

      // Enforce minimum of 15px from top to prevent overflow
      final emojiY = math.max(15.0, math.min(rawEmojiY, size.height - 25));

      // Draw a small circle behind emoji for better visibility
      canvas.drawCircle(
        Offset(emojiX, emojiY),
        10, // Circle radius
        Paint()..color = Colors.white.withOpacity(0.3),
      );

      // Center the emoji on its position
      textPainter.paint(
        canvas,
        Offset(emojiX - textPainter.width / 2, emojiY - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MoodWavePainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase ||
        oldDelegate.flowPhase != flowPhase ||
        oldDelegate.activityLevel != activityLevel ||
        oldDelegate.participants != participants;
  }
}
