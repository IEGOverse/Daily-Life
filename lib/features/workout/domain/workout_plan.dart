import '../../../core/database/database.dart' as db;
import 'exercise.dart';

class WorkoutPlan {
  final String id;
  final String name;
  final String? description;
  final String? dayLabel;

  const WorkoutPlan({
    required this.id,
    required this.name,
    this.description,
    this.dayLabel,
  });

  factory WorkoutPlan.fromRow(db.WorkoutPlan row) => WorkoutPlan(
    id: row.id,
    name: row.name,
    description: row.description,
    dayLabel: row.dayLabel,
  );
}

class WorkoutPlanExercise {
  final String id;
  final String workoutPlanId;
  final String exerciseId;
  final int sets;
  final int reps;
  final int? restSeconds;
  final int sortOrder;
  final Exercise? exercise;

  const WorkoutPlanExercise({
    required this.id,
    required this.workoutPlanId,
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.restSeconds,
    required this.sortOrder,
    this.exercise,
  });

  factory WorkoutPlanExercise.fromRow(db.WorkoutPlanExercise row) =>
      WorkoutPlanExercise(
        id: row.id,
        workoutPlanId: row.workoutPlanId,
        exerciseId: row.exerciseId,
        sets: row.sets,
        reps: row.reps,
        restSeconds: row.restSeconds,
        sortOrder: row.sortOrder,
      );
}

class WorkoutPlanDraftExercise {
  final Exercise exercise;
  int sets;
  int reps;
  int restSeconds;

  WorkoutPlanDraftExercise({
    required this.exercise,
    this.sets = 3,
    this.reps = 10,
    this.restSeconds = 60,
  });
}
