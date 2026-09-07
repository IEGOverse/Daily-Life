import 'package:daily_life/core/database/database.dart' as db;

import '../domain/exercise.dart';

/// Repository for the workout exercise library. All exercise access should go
/// through this repository (ARCHITECTURE: data layer).
class ExerciseRepository {
  final db.AppDatabase _database;

  ExerciseRepository(this._database);

  Future<List<Exercise>> getAll() async {
    final rows = await _database.getAllExercises();
    return rows.map(Exercise.fromRow).toList();
  }

  Future<List<Exercise>> byMuscleGroup(String muscleGroup) async {
    final rows = await _database.getExercisesByMuscleGroup(muscleGroup);
    return rows.map(Exercise.fromRow).toList();
  }

  Future<Exercise?> byId(String id) async {
    final row = await _database.getExerciseById(id);
    return row == null ? null : Exercise.fromRow(row);
  }

  Future<void> insert(Exercise exercise) async {
    await _database.insertExercise(
      db.Exercise(
        id: exercise.id,
        name: exercise.name,
        muscleGroup: exercise.muscleGroup,
        description: exercise.description,
        instructions: exercise.instructions,
      ),
    );
  }
}

/// Seeds the initial exercise library once.
///
/// Same single-flight + idempotency pattern as the schedule seeding: a shared
/// in-flight future keeps concurrent first-reads (the library list and a detail
/// route on the same frame) from double-inserting behind the UNIQUE constraint.
Future<void> ensureExerciseLibrarySeeded(db.AppDatabase database) {
  final inFlight = _librarySeedInFlight;
  if (inFlight != null) {
    return inFlight;
  }
  final future = _seedLibrary(database).whenComplete(() {
    _librarySeedInFlight = null;
  });
  _librarySeedInFlight = future;
  return future;
}

Future<void>? _librarySeedInFlight;

Future<void> _seedLibrary(db.AppDatabase database) async {
  final existing = await database.getAllExercises();
  if (existing.isNotEmpty) {
    return;
  }
  for (final exercise in ExerciseLibrarySeeder.initialExercises()) {
    await database.insertExercise(exercise);
  }
}

/// Common, standard exercises to bootstrap the library (PRD §7). The user can
/// extend their own library through the add flow.
class ExerciseLibrarySeeder {
  static List<db.Exercise> initialExercises() {
    return [
      // Chest
      ExerciseLibrarySeeder._exercise(
        id: 'bench_press',
        name: 'Bench Press',
        muscleGroup: 'chest',
        description: 'Compound chest press on a flat bench.',
        instructions:
            'Lie on a flat bench with your feet planted and shoulder blades '
            'pulled back. Lower the bar to mid-chest under control, then press '
            'up until your arms are locked out.',
      ),
      ExerciseLibrarySeeder._exercise(
        id: 'push_up',
        name: 'Push-Up',
        muscleGroup: 'chest',
        description: 'Bodyweight upper-body push.',
        instructions:
            'Start in a high plank with hands under your shoulders. Lower your '
            'chest to just above the floor while keeping a straight line from '
            'head to heels, then push back up.',
      ),
      ExerciseLibrarySeeder._exercise(
        id: 'dumbbell_fly',
        name: 'Dumbbell Fly',
        muscleGroup: 'chest',
        description: 'Isolation chest movement with free weights.',
        instructions:
            'Lie on a flat bench holding dumbbells over your chest with a '
            'slight elbow bend. Open your arms wide in an arc until you feel a '
            'chest stretch, then squeeze the weights back to the top.',
      ),

      // Back
      ExerciseLibrarySeeder._exercise(
        id: 'pull_up',
        name: 'Pull-Up',
        muscleGroup: 'back',
        description: 'Bodyweight vertical pull.',
        instructions:
            'Hang from a bar with an overhand grip slightly wider than your '
            'shoulders. Pull your chest to the bar, then lower yourself with '
            'control.',
      ),
      ExerciseLibrarySeeder._exercise(
        id: 'bent_over_row',
        name: 'Bent-Over Row',
        muscleGroup: 'back',
        description: 'Compound horizontal pull.',
        instructions:
            'Hinge at the hips holding a barbell with a slight knee bend. Row '
            'the bar to your lower ribs, squeezing your shoulder blades '
            'together, then lower under control.',
      ),
      ExerciseLibrarySeeder._exercise(
        id: 'lat_pulldown',
        name: 'Lat Pulldown',
        muscleGroup: 'back',
        description: 'Machine vertical pull to the upper chest.',
        instructions:
            'Sit at a pulldown station and grip the bar with hands wider than '
            'shoulders. Pull the bar to your upper chest with elbows pointing '
            'down, then slowly return to the start.',
      ),

      // Legs
      ExerciseLibrarySeeder._exercise(
        id: 'back_squat',
        name: 'Barbell Squat',
        muscleGroup: 'legs',
        description: 'Compound lower-body strength movement.',
        instructions:
            'Rest the bar on your upper back with a braced core. Sit down into '
            'a squat with knees tracking over your toes and a flat back, then '
            'drive up through your heels.',
      ),
      ExerciseLibrarySeeder._exercise(
        id: 'deadlift',
        name: 'Deadlift',
        muscleGroup: 'legs',
        description: 'Full-body hinge lift.',
        instructions:
            'Stand over a loaded barbell with the bar touching your shins. '
            'Grip it, brace your core, and stand tall by extending hips and '
            'knees together; lower the bar under control.',
      ),
      ExerciseLibrarySeeder._exercise(
        id: 'walking_lunge',
        name: 'Walking Lunge',
        muscleGroup: 'legs',
        description: 'Unilateral lower-body movement.',
        instructions:
            'Step forward into a lunge until both knees are bent around 90 '
            'degrees, then push off your front leg and step into the next '
            'lunge.',
      ),

      // Shoulders
      ExerciseLibrarySeeder._exercise(
        id: 'overhead_press',
        name: 'Overhead Press',
        muscleGroup: 'shoulders',
        description: 'Compound overhead pressing movement.',
        instructions:
            'Stand with the bar at shoulder height and a tight core. Press '
            'straight overhead until the arms are locked, then lower to the '
            'starting position.',
      ),
      ExerciseLibrarySeeder._exercise(
        id: 'lateral_raise',
        name: 'Lateral Raise',
        muscleGroup: 'shoulders',
        description: 'Isolation side-delt movement.',
        instructions:
            'Hold light dumbbells at your sides. Raise both arms out to '
            'shoulder height with a slight elbow bend, then lower slowly.',
      ),

      // Arms
      ExerciseLibrarySeeder._exercise(
        id: 'bicep_curl',
        name: 'Bicep Curl',
        muscleGroup: 'arms',
        description: 'Isolation elbow-flexion movement.',
        instructions:
            'Hold dumbbells at your sides with palms facing forward. Curl the '
            'weights toward your shoulders without swinging your body, then '
            'lower under control.',
      ),
      ExerciseLibrarySeeder._exercise(
        id: 'triceps_pushdown',
        name: 'Triceps Pushdown',
        muscleGroup: 'arms',
        description: 'Cable isolation for the triceps.',
        instructions:
            'Stand at a cable station and grip the bar with your elbows pinned '
            'to your sides. Extend your forearms down to full lockout, then '
            'return slowly.',
      ),

      // Core
      ExerciseLibrarySeeder._exercise(
        id: 'plank',
        name: 'Plank',
        muscleGroup: 'core',
        description: 'Isometric core hold.',
        instructions:
            'Support your body on your forearms and toes with a straight line '
            'from head to heels. Brace your core and hold without letting your '
            'hips sag.',
      ),
      ExerciseLibrarySeeder._exercise(
        id: 'crunch',
        name: 'Crunch',
        muscleGroup: 'core',
        description: 'Basic abdominal curl.',
        instructions:
            'Lie on your back with knees bent and feet flat. Lift your '
            'shoulder blades off the floor by contracting your abs, then lower '
            'slowly.',
      ),
    ];
  }

  static db.Exercise _exercise({
    required String id,
    required String name,
    required String muscleGroup,
    required String description,
    required String instructions,
  }) {
    return db.Exercise(
      id: id,
      name: name,
      muscleGroup: muscleGroup,
      description: description,
      instructions: instructions,
    );
  }
}