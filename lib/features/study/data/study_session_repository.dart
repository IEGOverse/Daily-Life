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
}