/// Time distribution derived from existing records.
///
/// All values are DERIVED from authoritative records; nothing here is stored
/// (DATABASE.md §4). Time inputs:
///   - Study:  sum of `study_sessions.duration_seconds`
///   - Workout: sum of `workout_sessions.duration_seconds` (completed only)
///   - Activities: sum of `activities` end-start for completed activities,
///     grouped by category.
class TimeEntry {
  final String label;

  /// Minutes in this bucket.
  final double minutes;

  /// Fraction of total tracked time (0.0-1.0); 0 when total is 0.
  final double fraction;

  const TimeEntry({
    required this.label,
    required this.minutes,
    required this.fraction,
  });
}

class TimeAnalytics {
  final List<TimeEntry> entries;

  /// Total tracked minutes across all buckets.
  final double totalMinutes;

  const TimeAnalytics({required this.entries, required this.totalMinutes});

  static const TimeAnalytics empty = TimeAnalytics(
    entries: [],
    totalMinutes: 0,
  );

  bool get isEmpty => entries.isEmpty || totalMinutes == 0;
}
