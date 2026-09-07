import '../../../core/database/database.dart' as db;
import 'workout_plan.dart';

class WorkoutSession {
  final String id;
  final String workoutPlanId;
  final DateTime date;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationSeconds;
  final bool completed;
  final String? notes;
  final WorkoutPlan? plan;

  const WorkoutSession({
    required this.id,
    required this.workoutPlanId,
    required this.date,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    required this.completed,
    this.notes,
    this.plan,
  });

  factory WorkoutSession.fromRow(db.WorkoutSession row) => WorkoutSession(
    id: row.id,
    workoutPlanId: row.workoutPlanId,
    date: row.date,
    startTime: row.startTime,
    endTime: row.endTime,
    durationSeconds: row.durationSeconds,
    completed: row.completed == 1,
    notes: row.notes,
  );
}
