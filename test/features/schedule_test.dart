import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/core/database/database.dart' as db;
import 'package:daily_life/core/database/database_provider.dart';
import 'package:daily_life/features/schedule/data/schedule_repository.dart';
import 'package:daily_life/features/schedule/schedule_providers.dart';
import 'package:daily_life/features/schedule/schedule_screen.dart';

void main() {
  group('ScheduleSeeder', () {
    test('initialSchedules returns all 15 university classes', () {
      final schedules = ScheduleSeeder.initialSchedules();
      expect(schedules, hasLength(15));
    });

    test('every schedule is a weekly class', () {
      final schedules = ScheduleSeeder.initialSchedules();
      for (final schedule in schedules) {
        expect(schedule.type, 'class');
        expect(schedule.repeatType, 'weekly');
        expect(schedule.isActive, 1);
      }
    });

    test('covers Monday through Friday with expected titles', () {
      final schedules = ScheduleSeeder.initialSchedules();
      final days = schedules.map((s) => s.dayOfWeek).toSet();
      expect(days, containsAll([1, 2, 3, 4, 5]));
      expect(days, isNot(contains(6)));
      expect(days, isNot(contains(7)));

      final titles = schedules.map((s) => s.title).toSet();
      expect(titles, contains('Business Process Reengineering'));
      expect(titles, contains('System Analysis and Design'));
      expect(titles, contains('Kuliah Umum'));
      expect(titles, contains('Indonesian Civics'));
    });

    test('Monday has exactly 3 classes', () {
      final schedules = ScheduleSeeder.initialSchedules();
      final monday = schedules.where((s) => s.dayOfWeek == 1);
      expect(monday, hasLength(3));
    });

    test('Thursday has 4 classes including Kuliah Umum', () {
      final schedules = ScheduleSeeder.initialSchedules();
      final thursday = schedules.where((s) => s.dayOfWeek == 4);
      expect(thursday, hasLength(4));
      expect(thursday.map((s) => s.title), contains('Kuliah Umum'));
    });
  });

  group('generateActivitiesForDay', () {
    late db.AppDatabase database;

    setUp(() async {
      database = db.AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('generates activities for each schedule on that day', () async {
      // Seed Monday schedules.
      for (final schedule in ScheduleSeeder.initialSchedules()) {
        if (schedule.dayOfWeek == 1) {
          await database.insertSchedule(schedule);
        }
      }

      // Generate for Monday 2026-09-07.
      final generated = await generateActivitiesForDay(
        database,
        DateTime(2026, 9, 7),
      );
      expect(generated, hasLength(3));

      // All should have scheduleId set.
      for (final activity in generated) {
        expect(activity.scheduleId, isNotNull);
        expect(activity.status, 'scheduled');
      }
    });

    test('is idempotent — second call produces nothing', () async {
      for (final schedule in ScheduleSeeder.initialSchedules()) {
        if (schedule.dayOfWeek == 1) {
          await database.insertSchedule(schedule);
        }
      }

      final first = await generateActivitiesForDay(
        database,
        DateTime(2026, 9, 7),
      );
      final second = await generateActivitiesForDay(
        database,
        DateTime(2026, 9, 7),
      );
      expect(first, hasLength(3));
      expect(second, isEmpty);
    });

    test('generates nothing when no schedules exist for that day', () async {
      final generated = await generateActivitiesForDay(
        database,
        DateTime(2026, 9, 6), // Saturday
      );
      expect(generated, isEmpty);
    });
  });

  group('ensureSeededAndGenerated', () {
    late db.AppDatabase database;

    setUp(() async {
      database = db.AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('seeds schedules and generates a week of activities', () async {
      await ensureSeededAndGenerated(database);

      final schedules = await database.getActiveSchedules();
      expect(schedules, hasLength(15));

      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      var totalActivities = 0;
      for (var i = 0; i < 7; i++) {
        final day = DateTime(monday.year, monday.month, monday.day + i);
        final activities = await database.getActivitiesForDay(day);
        totalActivities += activities.length;
      }
      expect(totalActivities, 15);
    });
  });

  group('ScheduleScreen widget', () {
    testWidgets('shows day selector and schedule list', (tester) async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      // Seed all schedules.
      for (final schedule in ScheduleSeeder.initialSchedules()) {
        await database.insertSchedule(schedule);
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: const MaterialApp(home: ScheduleScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Day selector chips should be present.
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);

      // Tap Monday to view its classes.
      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();

      // All 3 Monday classes should be visible.
      expect(find.text('Business Process Reengineering'), findsOneWidget);
      expect(find.text('Data Mining and Warehousing'), findsOneWidget);
      expect(find.text('Research Method & Scientific Writing'), findsOneWidget);
    });

    testWidgets('shows empty state for weekend', (tester) async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: const MaterialApp(home: ScheduleScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Saturday (index 5 among the chips).
      await tester.tap(find.text('Sat'));
      await tester.pumpAndSettle();

      expect(find.text('No classes on Saturday.'), findsOneWidget);
    });
  });
}
