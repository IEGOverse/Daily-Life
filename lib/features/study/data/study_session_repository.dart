import 'package:daily_life/core/database/database.dart' as db;

import '../domain/study_session.dart';

class StudySessionRepository {
  final db.AppDatabase _database;

  StudySessionRepository(this._database);

  Future<List<StudySession>> getAll() async =>
      (await _database.getAllStudySessions())
          .map(StudySession.fromRow)
          .toList();

  Future<StudySession?> byId(String id) async {
    final row = await _database.getStudySessionById(id);
    return row == null ? null : StudySession.fromRow(row);
  }

  Future<void> insert(StudySession session) => _database.insertStudySession(
    db.StudySession(
      id: session.id,
      subject: session.subject,
      date: session.date,
      startTime: session.startTime,
      endTime: session.endTime,
      durationSeconds: session.durationSeconds,
      understanding: session.understanding,
      notes: session.notes,
    ),
  );

  Future<void> update(StudySession session) => insert(session);

  Future<void> delete(String id) => _database.deleteStudySession(id);

  /// Basic study statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final sessions = await getAll();
    if (sessions.isEmpty) return _emptyStats();

    final totalMinutes = sessions.fold<double>(
      0,
      (sum, session) => sum + (session.durationSeconds ?? 0) / 60,
    );

    final totalUnderstanding = sessions.fold<int>(
      0,
      (sum, session) => sum + (session.understanding ?? 0),
    );

    final uniqueDays = <DateTime>{};
    for (final session in sessions) {
      uniqueDays.add(session.date);
    }

    return {
      'totalSessions': sessions.length,
      'totalMinutes': totalMinutes.round(),
      'averageUnderstanding': (totalUnderstanding / sessions.length).round(),
      'studyDays': uniqueDays.length,
    };
  }

  Map<String, dynamic> _emptyStats() => {
    'totalSessions': 0,
    'totalMinutes': 0,
    'averageUnderstanding': 0,
    'studyDays': 0,
  };
}
