import '../../../core/database/database.dart' as db;

class WorkoutSetLog {
  final String id;
  final String workoutSessionId;
  final String exerciseId;
  final int setNumber;
  final int reps;
  final double? weight;
  final bool completed;

  const WorkoutSetLog({
    required this.id,
    required this.workoutSessionId,
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    this.weight,
    required this.completed,
  });

  factory WorkoutSetLog.fromRow(db.WorkoutSetLog row) => WorkoutSetLog(
    id: row.id,
    workoutSessionId: row.workoutSessionId,
    exerciseId: row.exerciseId,
    setNumber: row.setNumber,
    reps: row.reps,
    weight: row.weight,
    completed: row.completed == 1,
  );
}
