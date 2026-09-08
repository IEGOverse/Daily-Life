/// Transparent daily productivity score (0-100).
///
/// The score is an indicator, not a judgment. It is built from two visible
/// components and never from body appearance, weight, calories, or restrictive
/// health targets (see DATABASE.md §4 — documented scoring rule):
///
///   taskScore  = completed planned activities / planned activities
///                (1.0 when no activities are planned that day)
///   habitScore = completed active habits / active habits
///                (1.0 when there are no active habits)
///   score      = round(taskScore × 50 + habitScore × 50)
///
/// When the day has no planned activities AND no active habits, [hasData] is
/// false and no numeric score is implied.
class DailyScore {
  /// Fraction of planned activities that were completed (0.0-1.0).
  final double taskScore;

  /// Fraction of today's active habits that were completed (0.0-1.0).
  final double habitScore;

  /// The combined 0-100 score.
  final int score;

  /// Whether the day had anything to score (activities or active habits).
  final bool hasData;

  const DailyScore({
    required this.taskScore,
    required this.habitScore,
    required this.score,
    required this.hasData,
  });

  /// An empty day with no activities and no habits to score.
  static const DailyScore empty = DailyScore(
    taskScore: 1.0,
    habitScore: 1.0,
    score: 0,
    hasData: false,
  );

  /// Builds a score from raw component counts.
  static DailyScore compute({
    required int completedActivities,
    required int totalActivities,
    required int completedHabits,
    required int activeHabits,
  }) {
    final hasActivities = totalActivities > 0;
    final hasHabits = activeHabits > 0;
    final taskScore = hasActivities
        ? completedActivities / totalActivities
        : 1.0;
    final habitScore = hasHabits ? completedHabits / activeHabits : 1.0;
    final score = hasActivities || hasHabits
        ? ((taskScore * 50) + (habitScore * 50)).round()
        : 0;
    return DailyScore(
      taskScore: taskScore,
      habitScore: habitScore,
      score: score,
      hasData: hasActivities || hasHabits,
    );
  }
}
