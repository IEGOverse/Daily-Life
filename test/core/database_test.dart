import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/core/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase schema', () {
    test('schema version is 2', () {
      expect(db.schemaVersion, 2);
    });
  });

  group('Activity persistence and day queries', () {
    test('inserts and reads an activity', () async {
      final activity = Activity(
        id: 'a1',
        scheduleId: null,
        title: 'Study',
        category: 'study',
        startTime: DateTime.utc(2026, 9, 8, 9),
        endTime: DateTime.utc(2026, 9, 8, 10),
        status: 'scheduled',
        referenceId: null,
        referenceType: null,
        notes: null,
        createdAt: DateTime.now(),
      );
      await db.insertActivity(activity);

      final all = await db.getAllActivities();
      expect(all, hasLength(1));
      expect(all.first.title, 'Study');
    });

    test('getActivitiesForDay matches the requested local day', () async {
      await db.insertActivity(
        Activity(
          id: 'today',
          scheduleId: null,
          title: 'Today',
          category: 'work',
          startTime: DateTime.utc(2026, 9, 8, 9),
          endTime: DateTime.utc(2026, 9, 8, 10),
          status: 'completed',
          notes: null,
          createdAt: DateTime.now(),
        ),
      );
      await db.insertActivity(
        Activity(
          id: 'otherday',
          scheduleId: null,
          title: 'Other day',
          category: 'work',
          startTime: DateTime.utc(2026, 9, 9, 9),
          endTime: DateTime.utc(2026, 9, 9, 10),
          status: 'scheduled',
          notes: null,
          createdAt: DateTime.now(),
        ),
      );

      final todays = await db.getActivitiesForDay(DateTime(2026, 9, 8));
      expect(todays.map((a) => a.id), ['today']);

      final empty = await db.getActivitiesForDay(DateTime(2026, 1, 1));
      expect(empty, isEmpty);
    });

    test('setActivityStatus updates only the status', () async {
      await db.insertActivity(
        Activity(
          id: 'a1',
          title: 'Study',
          category: 'study',
          startTime: DateTime.utc(2026, 9, 8, 9),
          endTime: DateTime.utc(2026, 9, 8, 10),
          status: 'scheduled',
          createdAt: DateTime.now(),
        ),
      );

      await db.setActivityStatus('a1', 'completed');

      final row = await db.getActivityById('a1');
      expect(row!.status, 'completed');
      expect(row.category, 'study');
    });
  });

  group('Transaction day queries', () {
    test('getTransactionsForDay matches the requested local day', () async {
      await db.insertTransaction(
        Transaction(
          id: 't1',
          type: 'income',
          category: 'salary',
          amount: 100,
          description: null,
          date: DateTime.utc(2026, 9, 8, 10),
          createdAt: DateTime.now(),
        ),
      );
      await db.insertTransaction(
        Transaction(
          id: 't2',
          type: 'expense',
          category: 'food',
          amount: 20,
          description: null,
          date: DateTime.utc(2026, 9, 7, 10),
          createdAt: DateTime.now(),
        ),
      );

      final todays = await db.getTransactionsForDay(DateTime(2026, 9, 8));
      expect(todays.map((t) => t.id), ['t1']);
    });
  });

  group('Schedule persistence', () {
    test('inserts and reads schedules by weekday', () async {
      await db.insertSchedule(
        Schedule(
          id: 's1',
          title: 'Math',
          type: 'class',
          dayOfWeek: 1,
          startTime: '10:10',
          endTime: '11:30',
          repeatType: 'weekly',
          location: null,
          notes: null,
          isActive: 1,
          createdAt: DateTime.now(),
        ),
      );

      final monday = await db.getSchedulesByDay(1);
      expect(monday, hasLength(1));
      expect(monday.first.title, 'Math');

      final tuesday = await db.getSchedulesByDay(2);
      expect(tuesday, isEmpty);
    });
  });
}
