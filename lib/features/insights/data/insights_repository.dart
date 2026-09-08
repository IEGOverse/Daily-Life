import 'package:daily_life/core/database/database.dart' as db;

import '../../activities/domain/activity.dart';
import '../../activities/domain/activity_status.dart';
import '../domain/daily_score.dart';
import '../domain/time_analytics.dart';
import '../domain/weekly_summary.dart';

/// Derives cross-module analytics from existing authoritative records.
///
/// Every value returned by this repository is computed on the fly from the
/// underlying modules' source rows (activities, study sessions, workout
/// sessions, transactions, meals, habit logs). No analytics row is stored and
/// no authoritative data is duplicated (DATABASE.md §4).
class InsightsRepository {
  final db.AppDatabase _database;

  InsightsRepository(this._database);

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Daily productivity score for [day].
  Future<DailyScore> dailyScore(DateTime day) async {
    final start = _dayOnly(day);
    final end = start.add(const Duration(days: 1));

    final activityRows = await _database.getActivitiesForRange(start, end);
    final activities = activityRows.map(Activity.fromRow).toList();
    final planned = activities.length;
    final completed = activities
        .where((a) => a.status == ActivityStatus.completed)
        .length;

    final habits = await _database.getActiveHabits();
    final logs = await _database.getHabitLogsForRange(start, end);
    final activeHabits = habits.length;
    final completedHabits = logs
        .where((l) => l.completed == 1 && habits.any((h) => h.id == l.habitId))
        .length;

    return DailyScore.compute(
      completedActivities: completed,
      totalActivities: planned,
      completedHabits: completedHabits,
      activeHabits: activeHabits,
    );
  }

  /// Weekly summary for [startInclusive, endExclusive).
  Future<WeeklySummary> weeklySummary(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    // Activities (grouped, since start_time is an instant within the week).
    final activityRows = await _database.getActivitiesForRange(
      _dayOnly(startInclusive),
      _dayOnly(endExclusive),
    );
    final activities = activityRows.map(Activity.fromRow).toList();

    // Study sessions.
    final studyRows = await _database.getStudySessionsForRange(
      _dayOnly(startInclusive),
      _dayOnly(endExclusive),
    );
    final studyMinutes = studyRows.fold<double>(
      0,
      (sum, s) => sum + (s.durationSeconds ?? 0) / 60,
    );

    // Workout sessions.
    final workoutRows = await _database.getWorkoutSessionsForRange(
      _dayOnly(startInclusive),
      _dayOnly(endExclusive),
    );
    final completedWorkouts = workoutRows.where((s) => s.completed == 1);
    final workoutMinutes = completedWorkouts.fold<double>(
      0,
      (sum, s) => sum + (s.durationSeconds ?? 0) / 60,
    );

    // Nutrition.
    final meals = await _database.getMealsForRange(
      _dayOnly(startInclusive),
      _dayOnly(endExclusive),
    );

    // Finance.
    final transactions = await _database.getTransactionsForRange(
      _dayOnly(startInclusive),
      _dayOnly(endExclusive),
    );
    final income = transactions
        .where((t) => t.type == 'income')
        .fold<double>(0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, t) => sum + t.amount);

    // Habits.
    final habitLogs = await _database.getHabitLogsForRange(
      _dayOnly(startInclusive),
      _dayOnly(endExclusive),
    );
    final habitCompletions = habitLogs.where((l) => l.completed == 1).length;
    final habitLogDays = habitLogs.length;

    // Daily scores across the week (only full calendar days within range).
    final scores = <DailyScore>[];
    var cursor = _dayOnly(startInclusive);
    final end = _dayOnly(endExclusive);
    while (cursor.isBefore(end)) {
      scores.add(await dailyScore(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }
    final scoredDays = scores.where((s) => s.hasData).length;
    final averageScore = scoredDays == 0
        ? 0
        : (scores
                      .where((s) => s.hasData)
                      .fold<int>(0, (sum, s) => sum + s.score) /
                  scoredDays)
              .round();

    return WeeklySummary(
      start: _dayOnly(startInclusive),
      end: _dayOnly(endExclusive),
      plannedActivities: activities.length,
      completedActivities: activities
          .where((a) => a.status == ActivityStatus.completed)
          .length,
      studySessions: studyRows.length,
      studyMinutes: studyMinutes,
      workouts: completedWorkouts.length,
      workoutMinutes: workoutMinutes,
      mealCount: meals.length,
      income: income,
      expense: expense,
      habitCompletions: habitCompletions,
      habitLogDays: habitLogDays,
      averageScore: averageScore,
      scoredDays: scoredDays,
    );
  }

  /// Time distribution for [startInclusive, endExclusive).
  Future<TimeAnalytics> timeAnalytics(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    final studyRows = await _database.getStudySessionsForRange(
      _dayOnly(startInclusive),
      _dayOnly(endExclusive),
    );
    final studyMinutes = studyRows.fold<double>(
      0,
      (sum, s) => sum + (s.durationSeconds ?? 0) / 60,
    );

    final workoutRows = await _database.getWorkoutSessionsForRange(
      _dayOnly(startInclusive),
      _dayOnly(endExclusive),
    );
    final workoutMinutes = workoutRows
        .where((s) => s.completed == 1)
        .fold<double>(0, (sum, s) => sum + (s.durationSeconds ?? 0) / 60);

    final activityRows = await _database.getActivitiesForRange(
      _dayOnly(startInclusive),
      _dayOnly(endExclusive),
    );
    final byCategory = <String, double>{};
    for (final row in activityRows) {
      if (row.status != 'completed' || row.endTime == null) continue;
      final minutes = row.endTime!.difference(row.startTime).inSeconds / 60.0;
      byCategory.update(
        row.category,
        (v) => v + minutes,
        ifAbsent: () => minutes,
      );
    }

    final buckets = <TimeEntryBuilder>[
      if (studyMinutes > 0)
        TimeEntryBuilder(label: 'Study', minutes: studyMinutes),
      if (workoutMinutes > 0)
        TimeEntryBuilder(label: 'Workout', minutes: workoutMinutes),
      ...byCategory.entries.map(
        (e) => TimeEntryBuilder(label: e.key, minutes: e.value),
      ),
    ];
    final total = buckets.fold<double>(0, (sum, b) => sum + b.minutes);
    final entries =
        buckets
            .map(
              (b) => TimeEntry(
                label: b.label,
                minutes: b.minutes,
                fraction: total == 0 ? 0 : b.minutes / total,
              ),
            )
            .toList()
          ..sort((a, b) => b.minutes.compareTo(a.minutes));

    return TimeAnalytics(entries: entries, totalMinutes: total);
  }
}

/// Lightweight mutable builder used while computing [TimeAnalytics].
class TimeEntryBuilder {
  final String label;
  final double minutes;

  const TimeEntryBuilder({required this.label, required this.minutes});
}
