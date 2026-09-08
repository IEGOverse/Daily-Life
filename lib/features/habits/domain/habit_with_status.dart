import 'habit.dart';

/// View model pairing a [Habit] with its current streak and today's status.
///
/// Used by the Habits screen so each row shows completion state for today plus
/// the current streak in a single reactive object.
class HabitWithStatus {
  final Habit habit;

  /// Number of consecutive days (through today) the habit was completed on.
  final int currentStreak;

  /// Best streak ever recorded for this habit, in days.
  final int bestStreak;

  /// Whether today's completion log exists and is marked completed.
  final bool completedToday;

  /// Total number of completed days on record.
  final int totalCompletions;

  const HabitWithStatus({
    required this.habit,
    required this.currentStreak,
    required this.bestStreak,
    required this.completedToday,
    required this.totalCompletions,
  });
}
