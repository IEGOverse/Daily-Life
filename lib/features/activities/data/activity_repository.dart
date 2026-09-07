import '../../../core/database/database.dart' as db;
import '../domain/activity.dart';
import '../domain/activity_status.dart';

/// Repository for the central [Activity] entity. All activity access should
/// go through this repository (ARCHITECTURE: data layer).
class ActivityRepository {
  final db.AppDatabase _database;

  ActivityRepository(this._database);

  Future<List<Activity>> getForDay(DateTime day) async {
    final rows = await _database.getActivitiesForDay(day);
    return rows.map(Activity.fromRow).toList()..sort(compareByStart);
  }

  Future<List<Activity>> getForRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    final rows = await _database.getActivitiesForRange(
      startInclusive,
      endExclusive,
    );
    return rows.map(Activity.fromRow).toList()..sort(compareByStart);
  }

  Future<List<Activity>> getForSchedule(String scheduleId) async {
    final rows = await _database.getActivitiesForSchedule(scheduleId);
    return rows.map(Activity.fromRow).toList()..sort(compareByStart);
  }

  Future<Activity?> getById(String id) async {
    final row = await _database.getActivityById(id);
    return row == null ? null : Activity.fromRow(row);
  }

  Future<void> insert(Activity activity) async {
    await _database.insertActivity(
      db.Activity(
        id: activity.id,
        scheduleId: activity.scheduleId,
        title: activity.title,
        category: activity.category,
        startTime: activity.startTime,
        endTime: activity.endTime,
        status: activity.status.storageValue,
        referenceId: activity.referenceId,
        referenceType: activity.referenceType,
        notes: activity.notes,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateStatus(String id, ActivityStatus status) =>
      _database.setActivityStatus(id, status.storageValue);

  Future<void> delete(String id) => _database.deleteActivity(id);
}
