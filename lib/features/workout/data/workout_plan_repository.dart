import 'package:daily_life/core/database/database.dart' as db;

import 'exercise_repository.dart';
import '../domain/workout_plan.dart';

class WorkoutPlanRepository {
  final db.AppDatabase _database;

  WorkoutPlanRepository(this._database);

  Future<List<WorkoutPlan>> getAll() async =>
      (await _database.getAllWorkoutPlans()).map(WorkoutPlan.fromRow).toList();

  Future<WorkoutPlan?> byId(String id) async {
    final row = await _database.getWorkoutPlanById(id);
    return row == null ? null : WorkoutPlan.fromRow(row);
  }

  Future<List<WorkoutPlanExercise>> exercisesFor(String planId) async {
    final rows = await _database.getWorkoutPlanExercises(planId);
    return rows.map(WorkoutPlanExercise.fromRow).toList();
  }

  Future<List<WorkoutPlanExercise>> exercisesWithDetails(String planId) async {
    final links = await exercisesFor(planId);
    final exercises = await ExerciseRepository(_database).getAll();
    final byId = {for (final exercise in exercises) exercise.id: exercise};
    return links
        .map(
          (link) => WorkoutPlanExercise(
            id: link.id,
            workoutPlanId: link.workoutPlanId,
            exerciseId: link.exerciseId,
            sets: link.sets,
            reps: link.reps,
            restSeconds: link.restSeconds,
            sortOrder: link.sortOrder,
            exercise: byId[link.exerciseId],
          ),
        )
        .toList();
  }

  Future<void> insert({
    required WorkoutPlan plan,
    required List<WorkoutPlanDraftExercise> exercises,
  }) async {
    await _database.transaction(() async {
      await _database.insertWorkoutPlan(
        db.WorkoutPlan(
          id: plan.id,
          name: plan.name,
          description: plan.description,
          dayLabel: plan.dayLabel,
        ),
      );
      for (var index = 0; index < exercises.length; index++) {
        final item = exercises[index];
        await _database.insertWorkoutPlanExercise(
          db.WorkoutPlanExercise(
            id: '${plan.id}_${item.exercise.id}',
            workoutPlanId: plan.id,
            exerciseId: item.exercise.id,
            sets: item.sets,
            reps: item.reps,
            restSeconds: item.restSeconds,
            sortOrder: index,
          ),
        );
      }
    });
  }

  Future<void> delete(String id) async {
    final sessions = await _database.getWorkoutSessionsForPlan(id);
    if (sessions.isNotEmpty) {
      throw StateError('Cannot delete a plan with session history.');
    }
    await _database.transaction(() async {
      await _database.deleteWorkoutPlanExercises(id);
      await _database.deleteWorkoutPlan(id);
    });
  }
}
