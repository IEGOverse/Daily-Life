/// Aggregated cross-module week summary.
///
/// Every field is DERIVED from existing authoritative records in the
/// selected date range (DATABASE.md §4). Nothing here is stored back.
class WeeklySummary {
  final DateTime start;
  final DateTime end;

  // Activities
  final int plannedActivities;
  final int completedActivities;

  // Study
  final int studySessions;
  final double studyMinutes;

  // Workout
  final int workouts;
  final double workoutMinutes;

  // Nutrition
  final int mealCount;

  // Finance
  final double income;
  final double expense;

  // Habits
  final int habitCompletions;
  final int habitLogDays;

  // Score
  final int averageScore;
  final int scoredDays;

  const WeeklySummary({
    required this.start,
    required this.end,
    required this.plannedActivities,
    required this.completedActivities,
    required this.studySessions,
    required this.studyMinutes,
    required this.workouts,
    required this.workoutMinutes,
    required this.mealCount,
    required this.income,
    required this.expense,
    required this.habitCompletions,
    required this.habitLogDays,
    required this.averageScore,
    required this.scoredDays,
  });

  double get balanceChange => income - expense;

  static final WeeklySummary empty = WeeklySummary(
    start: DateTime(2000),
    end: DateTime(2000),
    plannedActivities: 0,
    completedActivities: 0,
    studySessions: 0,
    studyMinutes: 0,
    workouts: 0,
    workoutMinutes: 0,
    mealCount: 0,
    income: 0,
    expense: 0,
    habitCompletions: 0,
    habitLogDays: 0,
    averageScore: 0,
    scoredDays: 0,
  );
}
