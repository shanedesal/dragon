// ------------------------------------------------------------------
// File: step_goal.dart
// Feature: Walk
// Description: Domain model representing the user's step goal.
// ------------------------------------------------------------------

class StepGoal {
  final int targetSteps;

  const StepGoal({required this.targetSteps});

  factory StepGoal.fromJson(Map<String, dynamic> json) {
    return StepGoal(targetSteps: (json['stepGoal'] as num?)?.toInt() ?? 10000);
  }

  Map<String, dynamic> toJson() {
    return {'stepGoal': targetSteps};
  }
}
