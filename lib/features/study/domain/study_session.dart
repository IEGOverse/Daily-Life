import '../../../core/database/database.dart' as db;

class StudySession {
  final String id;
  final String subject;
  final DateTime date;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationSeconds;
  final int? understanding;
  final String? notes;

  const StudySession({
    required this.id,
    required this.subject,
    required this.date,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    this.understanding,
    this.notes,
  });

  factory StudySession.fromRow(db.StudySession row) => StudySession(
    id: row.id,
    subject: row.subject,
    date: row.date,
    startTime: row.startTime,
    endTime: row.endTime,
    durationSeconds: row.durationSeconds,
    understanding: row.understanding,
    notes: row.notes,
  );
}
