import 'package:drift/drift.dart';
import 'package:daily_life/core/database/database.dart' as db;

import '../domain/habit.dart';
import '../domain/habit_log.dart';
import '../domain/habit_with_status.dart';

/// Repository for the Habits module (PRD §11).
///
/// Habits are independent recurring behaviors with daily logs. Streaks are
/// DERIVED from the habit logs; no streak value is stored (DATABASE.md §2, §4).
class HabitRepository {
  final db.AppDatabase _database;

  HabitRepository(this._database);

  /// Monotonic suffix keeps generated log IDs unique even when several logs
  /// are created within the same microsecond (e.g. rapid toggles or seeding).
  static int _idCounter = 0;

  String _newLogId() =>
      'log_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // --- Habits --------------------------------------------------------------
  Future<List<Habit>> getHabits() async =>
      (await _database.getAllHabits()).map(Habit.fromRow).toList();

  Future<List<Habit>> getActiveHabits() async =>
      (await _database.getActiveHabits()).map(Habit.fromRow).toList();

  Future<Habit?> habitById(String id) async {
    final row = await _database.getHabitById(id);
    return row == null ? null : Habit.fromRow(row);
  }

  Future<void> insertHabit(Habit habit) => _database.insertHabit(
    db.Habit(
      id: habit.id,
      name: habit.name,
      frequency: habit.frequency,
      target: habit.target,
      isActive: habit.isActive ? 1 : 0,
      createdAt: habit.createdAt,
    ),
  );

  Future<void> updateHabit(Habit habit) => _database.updateHabit(
    habit.id,
    db.HabitsCompanion(
      name: Value(habit.name),
      frequency: Value(habit.frequency),
      target: Value(habit.target),
      isActive: Value(habit.isActive ? 1 : 0),
    ),
  );

  Future<void> deleteHabit(String id) => _database.deleteHabit(id);

  // --- Habit logs ----------------------------------------------------------
  Future<List<HabitLog>> logsForDay(DateTime day) async =>
      (await _database.getHabitLogsForDay(day)).map(HabitLog.fromRow).toList();

  Future<List<HabitLog>> logsForHabit(String habitId) async =>
      (await _database.getHabitLogsForHabit(habitId))
          .map(HabitLog.fromRow)
          .toList();

  /// Completes today's log for [habitId] on [day], or un-completes it when
  /// [completed] is false. Creates the log when none exists.
  Future<void> setCompleted(
    String habitId,
    DateTime day,
    bool completed,
  ) async {
    final normalized = _dateOnly(day);
    final existing = await _database.getHabitLog(habitId, normalized);
    if (existing == null) {
      if (!completed) return;
      await _database.insertHabitLog(
        db.HabitLog(
          id: _newLogId(),
          habitId: habitId,
          date: normalized,
          completed: 1,
        ),
      );
    } else {
      if (existing.completed == (completed ? 1 : 0)) return;
      await _database.updateHabitLog(
        existing.id,
        db.HabitLogsCompanion(completed: Value(completed ? 1 : 0)),
      );
    }
  }

  // --- Derived status ------------------------------------------------------
  /// Builds [HabitWithStatus] for every habit, evaluating completion for
  /// [day].
  Future<List<HabitWithStatus>> habitsWithStatus(DateTime day) async {
    final habits = await getHabits();
    final statuses = <HabitWithStatus>[];
    for (final habit in habits) {
      final logs = await logsForHabit(habit.id);
      final completedDates = logs
          .where((l) => l.completed)
          .map((l) => _dateOnly(l.date))
          .toSet();
      statuses.add(
        HabitWithStatus(
          habit: habit,
          currentStreak: _currentStreak(completedDates, _dateOnly(day)),
          bestStreak: _bestStreak(completedDates),
          completedToday: completedDates.contains(_dateOnly(day)),
          totalCompletions: completedDates.length,
        ),
      );
    }
    statuses.sort((a, b) {
      // Completed-first ordering makes the today list feel responsive.
      if (a.completedToday != b.completedToday) {
        return a.completedToday ? -1 : 1;
      }
      return a.habit.name.compareTo(b.habit.name);
    });
    return statuses;
  }

  /// Number of consecutive completion days ending at or before [asOf].
  ///
  /// A day before [asOf] that was not completed breaks the streak. [asOf]
  /// itself may be unfinished (today has not been logged yet) without
  /// breaking an otherwise-running streak.
  int _currentStreak(Set<DateTime> completedDates, DateTime asOf) {
    var streak = 0;
    var cursor = _dateOnly(asOf);
    var isFirst = true;
    while (true) {
      if (!completedDates.contains(cursor)) {
        if (isFirst) {
          // Today is optionally unfinished; step back and keep checking.
          isFirst = false;
          cursor = cursor.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
      streak += 1;
      isFirst = false;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Longest run of consecutive completion days.
  int _bestStreak(Set<DateTime> completedDates) {
    if (completedDates.isEmpty) return 0;
    final sorted = completedDates.toList()..sort();
    var best = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        run += 1;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    return best;
  }
}
