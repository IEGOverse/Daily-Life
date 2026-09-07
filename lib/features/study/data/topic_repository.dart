import 'package:daily_life/core/database/database.dart' as db;

import '../domain/topic.dart';

class TopicRepository {
  final db.AppDatabase _database;

  TopicRepository(this._database);

  Future<List<Topic>> getAll() async => (await _database.getAllStudyTopics())
      .map(
        (row) => Topic(
          id: row.id,
          studySessionId: row.studySessionId,
          topic: row.topic,
        ),
      )
      .toList();

  Future<Topic?> byId(String id) async {
    final row = await _database.getStudyTopicById(id);
    return row == null
        ? null
        : Topic(
            id: row.id,
            studySessionId: row.studySessionId,
            topic: row.topic,
          );
  }

  Future<void> insert(Topic topic) => _database.insertStudyTopic(
    db.StudyTopic(
      id: topic.id,
      studySessionId: topic.studySessionId,
      topic: topic.topic,
    ),
  );

  Future<void> update(Topic topic) => _database.insertStudyTopic(
    db.StudyTopic(
      id: topic.id,
      studySessionId: topic.studySessionId,
      topic: topic.topic,
    ),
  );

  Future<void> delete(String id) => _database.deleteStudyTopic(id);
}
