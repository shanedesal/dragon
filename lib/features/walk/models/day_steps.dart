// ------------------------------------------------------------------
// File: day_steps.dart
// Feature: Walk
// Description: Domain model representing one day's step data.
// ------------------------------------------------------------------

/// One day's worth of step data loaded from Firestore.
class DaySteps {
  final String date; // YYYY-MM-DD
  final int steps;
  final int goal;

  const DaySteps({
    required this.date,
    required this.steps,
    required this.goal,
  });
}
