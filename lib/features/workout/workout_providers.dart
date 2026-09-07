import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import 'data/exercise_repository.dart';
import 'domain/exercise.dart';

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
final exerciseByIdProvider = FutureProvider.family<Exercise?, String>(
  (ref, id) async {
    await ensureExerciseLibrarySeeded(ref.read(databaseProvider));
    return ref.read(exerciseRepositoryProvider).byId(id);
  },
);