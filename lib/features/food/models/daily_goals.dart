// ------------------------------------------------------------------
// File: daily_goals.dart
// Feature: Food
// Description: Domain model representing the user's daily nutritional targets.
// ------------------------------------------------------------------

class DailyGoals {
  final int targetCalories;
  final int targetProtein;

  DailyGoals({
    required this.targetCalories,
    required this.targetProtein,
  });

  factory DailyGoals.fromJson(Map<String, dynamic> json) {
    return DailyGoals(
      targetCalories: json['targetCalories'] as int? ?? 2000,
      targetProtein: json['targetProtein'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
    };
  }
}
