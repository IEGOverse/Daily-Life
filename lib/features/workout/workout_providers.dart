import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import 'data/exercise_repository.dart';
import 'data/workout_plan_repository.dart';
import 'data/workout_session_repository.dart';
import 'data/workout_set_log_repository.dart';
import 'data/workout_history_repository.dart';
import 'domain/exercise.dart';
import 'domain/workout_plan.dart';
import 'domain/workout_session.dart';
import 'domain/workout_set_log.dart';
import 'domain/workout_history.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => ExerciseRepository(ref.watch(databaseProvider)),
);

/// All seeded + user exercises, ordered by muscle group then name. Lazily
/// seeds the initial library on first read.
final exercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  await ensureExerciseLibrarySeeded(ref.read(databaseProvider));
  return ref.read(exerciseRepositoryProvider).getAll();
});

/// A single exercise by id (used by the detail screen).
final exerciseByIdProvider = FutureProvider.family<Exercise?, String>((
  ref,
  id,
) async {
  await ensureExerciseLibrarySeeded(ref.read(databaseProvider));
  return ref.read(exerciseRepositoryProvider).byId(id);
});

final workoutPlanRepositoryProvider = Provider<WorkoutPlanRepository>(
  (ref) => WorkoutPlanRepository(ref.watch(databaseProvider)),
);

final workoutPlansProvider = FutureProvider<List<WorkoutPlan>>((ref) {
  return ref.watch(workoutPlanRepositoryProvider).getAll();
});

final workoutPlanByIdProvider = FutureProvider.family<WorkoutPlan?, String>(
  (ref, id) => ref.watch(workoutPlanRepositoryProvider).byId(id),
);

final workoutPlanExercisesProvider =
    FutureProvider.family<List<WorkoutPlanExercise>, String>((ref, id) {
      return ref.watch(workoutPlanRepositoryProvider).exercisesWithDetails(id);
    });

final workoutSessionRepositoryProvider = Provider<WorkoutSessionRepository>(
  (ref) => WorkoutSessionRepository(ref.watch(databaseProvider)),
);

final workoutSessionsProvider = FutureProvider<List<WorkoutSession>>((ref) {
  return ref.watch(workoutSessionRepositoryProvider).getAll();
});

final workoutSessionByIdProvider =
    FutureProvider.family<WorkoutSession?, String>((ref, id) {
      return ref.watch(workoutSessionRepositoryProvider).byId(id);
    });

final workoutSetLogRepositoryProvider = Provider<WorkoutSetLogRepository>(
  (ref) => WorkoutSetLogRepository(ref.watch(databaseProvider)),
);

final workoutSetLogsProvider =
    FutureProvider.family<List<WorkoutSetLog>, String>((ref, sessionId) {
      return ref
          .watch(workoutSetLogRepositoryProvider)
          .ensureForSession(sessionId);
    });

final workoutHistoryRepositoryProvider = Provider<WorkoutHistoryRepository>(
  (ref) => WorkoutHistoryRepository(ref.watch(databaseProvider)),
);

final workoutHistoryProvider = FutureProvider<WorkoutHistory>((ref) {
  return ref.watch(workoutHistoryRepositoryProvider).getSummary();
});
