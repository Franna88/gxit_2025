import 'package:flutter/material.dart';
import '../models/user_mood.dart';
import '../constants.dart';

class MoodSelector extends StatelessWidget {
  final MoodType? selectedMood;
  final Function(MoodType) onMoodSelected;

  const MoodSelector({
    super.key,
    required this.onMoodSelected,
    this.selectedMood,
  });

  // Get color for a mood type
  Color _getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return Colors.amber;
      case MoodType.excited:
        return AppColors.primaryPurple;
      case MoodType.calm:
        return AppColors.primaryBlue;
      case MoodType.bored:
        return Colors.grey;
      case MoodType.annoyed:
        return AppColors.primaryOrange;
      case MoodType.angry:
        return Colors.red;
      case MoodType.sad:
        return Colors.blueGrey;
      case MoodType.neutral:
      default:
        return Colors.teal;
    }
  }

  // Get icon for a mood type
  IconData _getMoodIcon(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return Icons.sentiment_satisfied;
      case MoodType.excited:
        return Icons.sentiment_very_satisfied;
      case MoodType.calm:
        return Icons.sentiment_neutral;
      case MoodType.bored:
        return Icons.sentiment_neutral;
      case MoodType.annoyed:
        return Icons.sentiment_dissatisfied;
      case MoodType.angry:
        return Icons.sentiment_very_dissatisfied;
      case MoodType.sad:
        return Icons.sentiment_dissatisfied;
      case MoodType.neutral:
      default:
        return Icons.sentiment_neutral;
    }
  }

  // Get name for a mood type
  String _getMoodName(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return 'Happy';
      case MoodType.excited:
        return 'Excited';
      case MoodType.calm:
        return 'Calm';
      case MoodType.bored:
        return 'Bored';
      case MoodType.annoyed:
        return 'Annoyed';
      case MoodType.angry:
        return 'Angry';
      case MoodType.sad:
        return 'Sad';
      case MoodType.neutral:
      default:
        return 'Neutral';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle for dragging
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            margin: const EdgeInsets.only(bottom: 16),
          ),

          // Title
          const Text(
            'How are you feeling?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Mood grid
          Wrap(
            spacing: 16,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: MoodType.values.map((mood) {
              final color = _getMoodColor(mood);
              final isSelected = mood == selectedMood;

              return GestureDetector(
                onTap: () {
                  onMoodSelected(mood);
                  Navigator.pop(context);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _getMoodIcon(mood),
                        color: isSelected ? Colors.white : color,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getMoodName(mood),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
} 