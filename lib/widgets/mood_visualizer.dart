import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/user_mood.dart';
import 'package:lottie/lottie.dart';

class MoodVisualizer extends StatefulWidget {
  final UserMood mood;
  final double size;
  final bool interactive;
  final Function()? onTap;
  final String? label;
  final bool showPulse;

  const MoodVisualizer({
    super.key,
    required this.mood,
    this.size = 60.0,
    this.interactive = true,
    this.onTap,
    this.label,
    this.showPulse = true,
  });

  @override
  State<MoodVisualizer> createState() => _MoodVisualizerState();
}

class _MoodVisualizerState extends State<MoodVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Initialize pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 1000 + (widget.mood.intensityValue * 1000).toInt(),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.showPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MoodVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      // Update animation duration based on mood intensity
      _pulseController.duration = Duration(
        milliseconds: 1000 + (widget.mood.intensityValue * 1000).toInt(),
      );

      if (widget.showPulse && !_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      } else if (!widget.showPulse && _pulseController.isAnimating) {
        _pulseController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter:
            (_) =>
                widget.interactive ? setState(() => _isHovered = true) : null,
        onExit:
            (_) =>
                widget.interactive ? setState(() => _isHovered = false) : null,
        child: GestureDetector(
          onTapDown:
              (_) =>
                  widget.interactive ? setState(() => _isPressed = true) : null,
          onTapUp:
              (_) =>
                  widget.interactive
                      ? setState(() => _isPressed = false)
                      : null,
          onTapCancel:
              () =>
                  widget.interactive
                      ? setState(() => _isPressed = false)
                      : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulseScale =
                      widget.showPulse
                          ? 1.0 +
                              ((widget.mood.intensityValue * 0.1) *
                                  _pulseAnimation.value)
                          : 1.0;

                  return Transform.scale(
                    scale: _isPressed ? 0.95 : (_isHovered ? 1.05 : pulseScale),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow
                        Container(
                          width: widget.size * 1.2,
                          height: widget.size * 1.2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.mood.color.withOpacity(
                                  widget.mood.intensityValue * 0.6,
                                ),
                                blurRadius:
                                    widget.size / 3 * _pulseAnimation.value,
                                spreadRadius:
                                    widget.size / 10 * _pulseAnimation.value,
                              ),
                            ],
                          ),
                        ),

                        // Main gradient background
                        Container(
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: widget.mood.gradient,
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2.0,
                            ),
                          ),
                        ),

                        // Mood content (emoji or animated icon)
                        if (widget.mood.animatedIconAsset != null &&
                            _assetExists(widget.mood.animatedIconAsset!))
                          Lottie.asset(
                            widget.mood.animatedIconAsset!,
                            width: widget.size * 0.8,
                            height: widget.size * 0.8,
                            fit: BoxFit.contain,
                          )
                        else
                          Text(
                            widget.mood.emoji,
                            style: TextStyle(fontSize: widget.size * 0.5),
                          ),

                        // Intensity indicator at the bottom
                        Positioned(
                          bottom: 5,
                          child: _buildIntensityIndicator(),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Optional label
              if (widget.label != null || widget.mood.label.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    widget.label ?? widget.mood.label,
                    style: TextStyle(
                      fontSize: widget.size * 0.2,
                      fontWeight: FontWeight.w500,
                      color: widget.mood.color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntensityIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = index < _intensityToLevel(widget.mood.intensity);
        return Container(
          width: widget.size * 0.1,
          height: widget.size * 0.03,
          margin: EdgeInsets.symmetric(horizontal: widget.size * 0.01),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size * 0.015),
            color: isActive ? widget.mood.color : Colors.white.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  int _intensityToLevel(MoodIntensity intensity) {
    switch (intensity) {
      case MoodIntensity.low:
        return 1;
      case MoodIntensity.medium:
        return 2;
      case MoodIntensity.high:
        return 3;
    }
  }

  // Helper method to check if Lottie asset exists (placeholder for actual implementation)
  bool _assetExists(String path) {
    // This would need actual implementation to check if the file exists
    // For now, we'll assume they don't exist so we fallback to emojis
    return false;
  }
}

// A simplified version for messages and smaller UI elements
class MoodIcon extends StatelessWidget {
  final UserMood mood;
  final double size;

  const MoodIcon({super.key, required this.mood, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: mood.gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: mood.color.withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(mood.emoji, style: TextStyle(fontSize: size * 0.7)),
      ),
    );
  }
}
