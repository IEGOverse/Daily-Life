import 'package:daily_life/core/database/database.dart' as db;

import '../domain/workout_history.dart';
import 'workout_session_repository.dart';

class WorkoutHistoryRepository {
  final db.AppDatabase _database;

  WorkoutHistoryRepository(this._database);

  Future<WorkoutHistory> getSummary() async {
    final sessions = await WorkoutSessionRepository(_database).getAll();
    final completed = sessions.where((session) => session.completed).toList();
    final logs = await _database.getAllWorkoutSetLogs();
    final completedSessionIds = completed.map((session) => session.id).toSet();
    return WorkoutHistory(
      completedSessions: completed,
      totalDurationSeconds: completed.fold(
        0,
        (total, session) => total + (session.durationSeconds ?? 0),
      ),
      completedSets: logs
          .where(
            (log) =>
                completedSessionIds.contains(log.workoutSessionId) &&
                log.completed == 1,
          )
          .length,
    );
  }
}
