import 'package:daily_life/core/database/database.dart' as db;

import '../domain/workout_set_log.dart';
import 'workout_plan_repository.dart';
import 'workout_session_repository.dart';

class WorkoutSetLogRepository {
  final db.AppDatabase _database;

  WorkoutSetLogRepository(this._database);

  Future<List<WorkoutSetLog>> forSession(String sessionId) async {
    final rows = await _database.getWorkoutSetLogs(sessionId);
    final logs = rows.map(WorkoutSetLog.fromRow).toList();
    final session = await WorkoutSessionRepository(_database).byId(sessionId);
    if (session == null) return logs;
    final links = await WorkoutPlanRepository(_database)
        .exercisesFor(session.workoutPlanId);
    final order = {for (final link in links) link.exerciseId: link.sortOrder};
    logs.sort((a, b) {
      final exerciseOrder = (order[a.exerciseId] ?? a.setNumber).compareTo(
        order[b.exerciseId] ?? b.setNumber,
      );
      return exerciseOrder == 0
          ? a.setNumber.compareTo(b.setNumber)
          : exerciseOrder;
    });
    return logs;
  }

  /// Creates the planned rows on first open, preserving the plan's set/reps
  /// prescription while allowing the user to record actual weight and reps.
  Future<List<WorkoutSetLog>> ensureForSession(String sessionId) async {
    final inFlight = _materializationInFlight[sessionId];
    if (inFlight != null) return inFlight;
    final future = _materialize(sessionId);
    _materializationInFlight[sessionId] = future;
    future.whenComplete(() => _materializationInFlight.remove(sessionId));
    return future;
  }

  Future<List<WorkoutSetLog>> _materialize(String sessionId) async {
    final existing = await forSession(sessionId);
    if (existing.isNotEmpty) return existing;

    final session = await WorkoutSessionRepository(_database).byId(sessionId);
    if (session == null) return const [];
    final links = await WorkoutPlanRepository(_database)
        .exercisesFor(session.workoutPlanId);
    await _database.transaction(() async {
      for (final link in links) {
        for (var set = 1; set <= link.sets; set++) {
          await _database.insertWorkoutSetLog(
            db.WorkoutSetLog(
              id: '${sessionId}_${link.exerciseId}_$set',
              workoutSessionId: sessionId,
              exerciseId: link.exerciseId,
              setNumber: set,
              reps: link.reps,
              weight: null,
              completed: 0,
            ),
          );
        }
      }
    });
    return forSession(sessionId);
  }

  Future<void> update(WorkoutSetLog log) => _database.updateWorkoutSetLog(
    log.id,
    log.reps,
    log.weight,
    log.completed,
  );
}

final Map<String, Future<List<WorkoutSetLog>>> _materializationInFlight = {};
