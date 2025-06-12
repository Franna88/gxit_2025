import 'package:flutter/material.dart';
import '../constants.dart';

enum MoodType { happy, excited, calm, bored, annoyed, angry, sad, neutral }

enum MoodIntensity { low, medium, high }

class UserMood {
  final MoodType? type;
  final String emoji;
  final String label;
  final Color color;
  final String? description;
  final MoodIntensity intensity;
  final List<Color>? gradientColors;
  final String? animatedIconAsset;

  // Original constructor for backward compatibility
  const UserMood({
    required String name,
    required this.emoji,
    required this.color,
    this.description,
    this.intensity = MoodIntensity.medium,
    this.gradientColors,
    this.animatedIconAsset,
  })  : type = null,
        label = name;

  // Private constructor for factory methods
  UserMood._({
    this.type,
    required this.emoji,
    required this.label,
    required this.color,
    this.description,
    this.intensity = MoodIntensity.medium,
    this.gradientColors,
    this.animatedIconAsset,
  });

  // For compatibility with existing code
  String get name => label;

  // Get mood intensity value (0.0 to 1.0)
  double get intensityValue {
    switch (intensity) {
      case MoodIntensity.low:
        return 0.3;
      case MoodIntensity.medium:
        return 0.6;
      case MoodIntensity.high:
        return 1.0;
    }
  }

  // Get gradient for mood (fallback to solid color if not defined)
  List<Color> get gradient => gradientColors ?? [color, color.withOpacity(0.7)];

  // Factory constructor to create a UserMood from a MoodType
  factory UserMood.fromType(MoodType type) {
    switch (type) {
      case MoodType.happy:
        return UserMood._(
          type: type,
          emoji: '😊',
          label: 'Happy',
          color: Colors.amber,
          intensity: MoodIntensity.high,
          gradientColors: [Colors.amber, Colors.orange],
          animatedIconAsset: 'assets/animations/happy.json',
        );
      case MoodType.excited:
        return UserMood._(
          type: type,
          emoji: '🤩',
          label: 'Excited',
          color: AppColors.primaryPurple,
          intensity: MoodIntensity.high,
          gradientColors: [AppColors.primaryPurple, Colors.purpleAccent],
          animatedIconAsset: 'assets/animations/excited.json',
        );
      case MoodType.calm:
        return UserMood._(
          type: type,
          emoji: '😌',
          label: 'Calm',
          color: AppColors.primaryBlue,
          intensity: MoodIntensity.low,
          gradientColors: [AppColors.primaryBlue, Colors.lightBlue],
          animatedIconAsset: 'assets/animations/calm.json',
        );
      case MoodType.bored:
        return UserMood._(
          type: type,
          emoji: '😑',
          label: 'Bored',
          color: Colors.grey,
          intensity: MoodIntensity.low,
          gradientColors: [Colors.grey, Colors.blueGrey],
          animatedIconAsset: 'assets/animations/bored.json',
        );
      case MoodType.annoyed:
        return UserMood._(
          type: type,
          emoji: '😤',
          label: 'Annoyed',
          color: AppColors.primaryOrange,
          intensity: MoodIntensity.medium,
          gradientColors: [AppColors.primaryOrange, Colors.orange],
          animatedIconAsset: 'assets/animations/annoyed.json',
        );
      case MoodType.angry:
        return UserMood._(
          type: type,
          emoji: '😡',
          label: 'Angry',
          color: Colors.red,
          intensity: MoodIntensity.high,
          gradientColors: [Colors.red, Colors.redAccent],
          animatedIconAsset: 'assets/animations/angry.json',
        );
      case MoodType.sad:
        return UserMood._(
          type: type,
          emoji: '😢',
          label: 'Sad',
          color: Colors.blueGrey,
          intensity: MoodIntensity.medium,
          gradientColors: [Colors.blueGrey, Colors.blue.withOpacity(0.6)],
          animatedIconAsset: 'assets/animations/sad.json',
        );
      case MoodType.neutral:
      default:
        return UserMood._(
          type: type,
          emoji: '😐',
          label: 'Neutral',
          color: Colors.teal,
          intensity: MoodIntensity.low,
          gradientColors: [Colors.teal, Colors.tealAccent],
          animatedIconAsset: 'assets/animations/neutral.json',
        );
    }
  }

  // Get a short description of the mood for UI display
  String get shortDescription => '$emoji $label';

  // Get a random UserMood
  static UserMood random() {
    final values = MoodType.values;
    final randomIndex = DateTime.now().microsecond % values.length;
    return UserMood.fromType(values[randomIndex]);
  }

  // Default mood (neutral)
  static UserMood get defaultMood => UserMood.fromType(MoodType.neutral);
}

// Define available moods
class MoodOptions {
  static const UserMood excited = UserMood(
    name: 'Excited',
    emoji: '🤩',
    color: Color(0xFFFFD700),
    description: 'Feeling enthusiastic and energetic',
    intensity: MoodIntensity.high,
    gradientColors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
    animatedIconAsset: 'assets/animations/excited.json',
  );

  static const UserMood happy = UserMood(
    name: 'Happy',
    emoji: '😊',
    color: Color(0xFF00BF63),
    description: 'In a good mood and positive',
    intensity: MoodIntensity.high,
    gradientColors: [Color(0xFF00BF63), Color(0xFF4CD080)],
    animatedIconAsset: 'assets/animations/happy.json',
  );

  static const UserMood relaxed = UserMood(
    name: 'Relaxed',
    emoji: '😌',
    color: Color(0xFF4DA6FF),
    description: 'Feeling calm and at ease',
    intensity: MoodIntensity.low,
    gradientColors: [Color(0xFF4DA6FF), Color(0xFF80C6FF)],
    animatedIconAsset: 'assets/animations/relaxed.json',
  );

  static const UserMood bored = UserMood(
    name: 'Bored',
    emoji: '😑',
    color: Color(0xFF9E9E9E),
    description: 'Not engaged, feeling uninterested',
    intensity: MoodIntensity.low,
    gradientColors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
    animatedIconAsset: 'assets/animations/bored.json',
  );

  static const UserMood annoyed = UserMood(
    name: 'Annoyed',
    emoji: '😤',
    color: Color(0xFFFF8D4D),
    description: 'Slightly irritated or displeased',
    intensity: MoodIntensity.medium,
    gradientColors: [Color(0xFFFF8D4D), Color(0xFFFFAB80)],
    animatedIconAsset: 'assets/animations/annoyed.json',
  );

  static const UserMood angry = UserMood(
    name: 'Angry',
    emoji: '😡',
    color: Color(0xFFFF4D4D),
    description: 'Feeling frustrated or upset',
    intensity: MoodIntensity.high,
    gradientColors: [Color(0xFFFF4D4D), Color(0xFFFF7575)],
    animatedIconAsset: 'assets/animations/angry.json',
  );

  static const UserMood sad = UserMood(
    name: 'Sad',
    emoji: '😢',
    color: Color(0xFF5D8AA8),
    description: 'Feeling down or unhappy',
    intensity: MoodIntensity.medium,
    gradientColors: [Color(0xFF5D8AA8), Color(0xFF8EB8D8)],
    animatedIconAsset: 'assets/animations/sad.json',
  );

  static const UserMood curious = UserMood(
    name: 'Curious',
    emoji: '🧐',
    color: Color(0xFFE066FF),
    description: 'Inquisitive and interested',
    intensity: MoodIntensity.medium,
    gradientColors: [Color(0xFFE066FF), Color(0xFFEA80FF)],
    animatedIconAsset: 'assets/animations/curious.json',
  );

  // List of all available moods
  static const List<UserMood> allMoods = [
    excited,
    happy,
    relaxed,
    curious,
    bored,
    annoyed,
    angry,
    sad,
  ];

  // Get a random mood - useful for demo purposes
  static UserMood getRandomMood() {
    allMoods.shuffle();
    return allMoods.first;
  }

  // Get mood by name
  static UserMood getMoodByName(String name) {
    return allMoods.firstWhere(
      (mood) => mood.name.toLowerCase() == name.toLowerCase(),
      orElse: () => happy,
    );
  }
}
