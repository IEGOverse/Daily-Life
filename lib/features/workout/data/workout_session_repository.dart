import 'package:daily_life/core/database/database.dart' as db;

import '../domain/workout_session.dart';
import 'workout_plan_repository.dart';

class WorkoutSessionRepository {
  final db.AppDatabase _database;

  WorkoutSessionRepository(this._database);

  Future<List<WorkoutSession>> getAll() async {
    final sessions = (await _database.getAllWorkoutSessions())
        .map(WorkoutSession.fromRow)
        .toList();
    return _attachPlans(sessions);
  }

  Future<WorkoutSession?> byId(String id) async {
    final row = await _database.getWorkoutSessionById(id);
    if (row == null) return null;
    return (await _attachPlans([WorkoutSession.fromRow(row)])).single;
  }

  Future<WorkoutSession> start({
    required String workoutPlanId,
    DateTime? now,
    String? notes,
  }) async {
    final startedAt = now ?? DateTime.now();
    final session = WorkoutSession(
      id: 'session_${startedAt.microsecondsSinceEpoch}',
      workoutPlanId: workoutPlanId,
      date: DateTime(startedAt.year, startedAt.month, startedAt.day),
      startTime: startedAt,
      completed: false,
      notes: notes,
    );
    await _database.insertWorkoutSession(
      db.WorkoutSession(
        id: session.id,
        workoutPlanId: session.workoutPlanId,
        date: session.date,
        startTime: session.startTime,
        endTime: session.endTime,
        durationSeconds: session.durationSeconds,
        completed: 0,
        notes: session.notes,
      ),
    );
    return session;
  }

  Future<void> complete(String id, {DateTime? endTime}) async {
    final session = await _database.getWorkoutSessionById(id);
    if (session == null || session.completed == 1) return;
    final finishedAt = endTime ?? DateTime.now();
    if (finishedAt.isBefore(session.startTime)) {
      throw ArgumentError('Session end time cannot precede its start time.');
    }
    final duration = finishedAt.difference(session.startTime).inSeconds;
    await _database.completeWorkoutSession(id, finishedAt, duration);
  }

  Future<List<WorkoutSession>> _attachPlans(
    List<WorkoutSession> sessions,
  ) async {
    final plans = await WorkoutPlanRepository(_database).getAll();
    final byId = {for (final plan in plans) plan.id: plan};
    return sessions
        .map(
          (session) => WorkoutSession(
            id: session.id,
            workoutPlanId: session.workoutPlanId,
            date: session.date,
            startTime: session.startTime,
            endTime: session.endTime,
            durationSeconds: session.durationSeconds,
            completed: session.completed,
            notes: session.notes,
            plan: byId[session.workoutPlanId],
          ),
        )
        .toList();
  }
}
