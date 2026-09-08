import '../../../core/database/database.dart' as db;

/// Domain model for a single daily habit completion record (PRD §11).
class HabitLog {
  final String id;
  final String habitId;

  /// Local calendar day the log belongs to.
  final DateTime date;
  final bool completed;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
  });

  factory HabitLog.fromRow(db.HabitLog row) => HabitLog(
    id: row.id,
    habitId: row.habitId,
    date: row.date,
    completed: row.completed == 1,
  );
}
