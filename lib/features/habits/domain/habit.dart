import '../../../core/database/database.dart' as db;

/// Domain model for a Habit (PRD §11).
///
/// Habits are independent recurring behaviors. They are NOT tied to the
/// activity/schedule bridge; activity remains the central bridge for
/// scheduled activities (ARCHITECTURE §6).
class Habit {
  final String id;
  final String name;

  /// Frequency label, e.g. 'daily', 'weekly'.
  final String frequency;

  /// Completion target (e.g. 1 completion per day, 3 times per week).
  final int target;

  final bool isActive;
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.name,
    required this.frequency,
    required this.target,
    this.isActive = true,
    required this.createdAt,
  });

  factory Habit.fromRow(db.Habit row) => Habit(
    id: row.id,
    name: row.name,
    frequency: row.frequency,
    target: row.target,
    isActive: row.isActive == 1,
    createdAt: row.createdAt,
  );
}
