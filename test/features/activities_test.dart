import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/core/database/database.dart' as db;
import 'package:daily_life/features/activities/data/activity_repository.dart';
import 'package:daily_life/features/activities/domain/activity.dart';
import 'package:daily_life/features/activities/domain/activity_status.dart';

void main() {
  group('ActivityStatus', () {
    test('fromString parses persisted values', () {
      expect(ActivityStatus.fromString('completed'), ActivityStatus.completed);
      expect(ActivityStatus.fromString('skipped'), ActivityStatus.skipped);
      expect(
        ActivityStatus.fromString('in_progress'),
        ActivityStatus.inProgress,
      );
      expect(ActivityStatus.fromString('upcoming'), ActivityStatus.upcoming);
      expect(ActivityStatus.fromString('scheduled'), ActivityStatus.scheduled);
      expect(ActivityStatus.fromString(null), ActivityStatus.scheduled);
      expect(ActivityStatus.fromString('garbage'), ActivityStatus.scheduled);
    });

    test('storageValue round-trips', () {
      for (final status in ActivityStatus.values) {
        expect(ActivityStatus.fromString(status.storageValue), status);
      }
    });

    test('isActionable excludes completed and skipped', () {
      expect(ActivityStatus.scheduled.isActionable, isTrue);
      expect(ActivityStatus.upcoming.isActionable, isTrue);
      expect(ActivityStatus.inProgress.isActionable, isTrue);
      expect(ActivityStatus.completed.isActionable, isFalse);
      expect(ActivityStatus.skipped.isActionable, isFalse);
    });
  });

  group('Activity', () {
    final activity = Activity(
      id: 'a1',
      title: 'Study',
      category: 'study',
      startTime: DateTime(2026, 9, 8, 9),
      endTime: DateTime(2026, 9, 8, 10),
    );

    test('isCurrentAt within range', () {
      expect(activity.isCurrentAt(DateTime(2026, 9, 8, 9, 30)), isTrue);
      expect(activity.isCurrentAt(DateTime(2026, 9, 8, 8, 59)), isFalse);
      expect(activity.isCurrentAt(DateTime(2026, 9, 8, 10, 1)), isFalse);
    });

    test('isUpcomingAfter before start', () {
      expect(activity.isUpcomingAfter(DateTime(2026, 9, 8, 8)), isTrue);
      expect(activity.isUpcomingAfter(DateTime(2026, 9, 8, 9, 30)), isFalse);
    });

    test('completed/skipped are not current or upcoming', () {
      final done = Activity(
        id: 'a1',
        title: 'Study',
        category: 'study',
        startTime: DateTime(2026, 9, 8, 9),
        endTime: DateTime(2026, 9, 8, 10),
        status: ActivityStatus.skipped,
      );
      expect(done.isCurrentAt(DateTime(2026, 9, 8, 9, 30)), isFalse);
      expect(done.isUpcomingAfter(DateTime(2026, 9, 8, 8)), isFalse);
    });

    test('open-ended activity is current after start', () {
      final openEnded = Activity(
        id: 'a1',
        title: 'Task',
        category: 'personal',
        startTime: DateTime(2026, 9, 8, 9),
      );
      expect(openEnded.isCurrentAt(DateTime(2026, 9, 8, 15)), isTrue);
      expect(openEnded.isCurrentAt(DateTime(2026, 9, 8, 8)), isFalse);
    });
  });

  group('ActivityRepository', () {
    late db.AppDatabase database;
    late ActivityRepository repository;

    setUp(() {
      database = db.AppDatabase(NativeDatabase.memory());
      repository = ActivityRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('insert and getById round-trip preserving all fields', () async {
      await repository.insert(
        Activity(
          id: 'a1',
          scheduleId: 'sched-1',
          title: 'Leg Day',
          category: 'workout',
          startTime: DateTime(2026, 9, 8, 9),
          endTime: DateTime(2026, 9, 8, 10),
          status: ActivityStatus.inProgress,
          referenceId: 'w1',
          referenceType: 'workout_session',
          notes: 'Heavy squat week',
        ),
      );

      final loaded = await repository.getById('a1');
      expect(loaded, isNotNull);
      expect(loaded!.title, 'Leg Day');
      expect(loaded.scheduleId, 'sched-1');
      expect(loaded.status, ActivityStatus.inProgress);
      expect(loaded.referenceType, 'workout_session');
      expect(loaded.notes, 'Heavy squat week');
    });

    test('getForDay returns only that local day ordered by start', () async {
      await repository.insert(
        Activity(
          id: 'a2',
          title: 'Later',
          category: 'work',
          startTime: DateTime(2026, 9, 8, 14),
        ),
      );
      await repository.insert(
        Activity(
          id: 'a1',
          title: 'Earlier',
          category: 'work',
          startTime: DateTime(2026, 9, 8, 9),
        ),
      );
      await repository.insert(
        Activity(
          id: 'a3',
          title: 'Another day',
          category: 'work',
          startTime: DateTime(2026, 9, 9, 9),
        ),
      );

      final todays = await repository.getForDay(DateTime(2026, 9, 8));
      expect(todays.map((a) => a.id), ['a1', 'a2']);
    });

    test('updateStatus persists a new status', () async {
      await repository.insert(
        Activity(
          id: 'a1',
          title: 'Study',
          category: 'study',
          startTime: DateTime(2026, 9, 8, 9),
        ),
      );

      await repository.updateStatus('a1', ActivityStatus.completed);

      final loaded = await repository.getById('a1');
      expect(loaded!.status, ActivityStatus.completed);
    });

    test('delete removes the activity', () async {
      await repository.insert(
        Activity(
          id: 'a1',
          title: 'Study',
          category: 'study',
          startTime: DateTime(2026, 9, 8, 9),
        ),
      );
      await repository.delete('a1');

      expect(await repository.getById('a1'), isNull);
    });
  });
}
