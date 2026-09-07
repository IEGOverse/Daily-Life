import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/core/database/database.dart' as db;
import 'package:daily_life/features/dashboard/data/dashboard_repository.dart';
import 'package:daily_life/features/dashboard/dashboard_providers.dart';
import 'package:daily_life/features/dashboard/dashboard_screen.dart';
import 'package:daily_life/features/activities/domain/activity.dart';
import 'package:daily_life/features/activities/domain/activity_status.dart';
import 'package:daily_life/features/dashboard/domain/dashboard_summary.dart';
import 'package:flutter/material.dart';

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
  });

  group('Activity time logic', () {
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

    test('completed/skipped activities are not current or upcoming', () {
      final completed = Activity(
        id: 'a1',
        title: 'Study',
        category: 'study',
        startTime: DateTime(2026, 9, 8, 9),
        endTime: DateTime(2026, 9, 8, 10),
        status: ActivityStatus.skipped,
      );
      expect(completed.isCurrentAt(DateTime(2026, 9, 8, 9, 30)), isFalse);
      expect(completed.isUpcomingAfter(DateTime(2026, 9, 8, 8)), isFalse);
    });

    test('open-ended activity without end time is current after start', () {
      final openEnded = Activity(
        id: 'a1',
        title: 'Task',
        category: 'personal',
        startTime: DateTime(2026, 9, 8, 9),
        endTime: null,
      );

      expect(openEnded.isCurrentAt(DateTime(2026, 9, 8, 15)), isTrue);
      expect(openEnded.isCurrentAt(DateTime(2026, 9, 8, 8)), isFalse);
    });
  });

  group('DashboardSummary', () {
    final activities = [
      Activity(
        id: 'a1',
        title: 'Morning run',
        category: 'workout',
        startTime: DateTime(2026, 9, 8, 7),
        endTime: DateTime(2026, 9, 8, 8),
        status: ActivityStatus.completed,
      ),
      Activity(
        id: 'a2',
        title: 'Math',
        category: 'study',
        startTime: DateTime(2026, 9, 8, 10),
        endTime: DateTime(2026, 9, 8, 11),
        status: ActivityStatus.scheduled,
      ),
      Activity(
        id: 'a3',
        title: 'Lunch',
        category: 'nutrition',
        startTime: DateTime(2026, 9, 8, 12),
        endTime: DateTime(2026, 9, 8, 13),
        status: ActivityStatus.completed,
      ),
    ];

    final summary = DashboardSummary(
      day: DateTime(2026, 9, 8),
      activities: activities,
    );

    test('totals and progress', () {
      expect(summary.totalActivities, 3);
      expect(summary.completedActivities, 2);
      expect(summary.progress, closeTo(2 / 3, 0.0001));
    });

    test('progress is 0 when nothing planned', () {
      final empty = DashboardSummary(day: DateTime(2026, 9, 8), activities: []);
      expect(empty.progress, 0.0);
      expect(empty.totalActivities, 0);
    });

    test('currentActivityAt returns the activity spanning now', () {
      final current = summary.currentActivityAt(DateTime(2026, 9, 8, 10, 30));
      expect(current, isNotNull);
      expect(current!.id, 'a2');
    });

    test('nextActivityAfter ignores completed and skipped activities', () {
      // a3 is completed, so there is nothing upcoming at 11:30.
      expect(summary.nextActivityAfter(DateTime(2026, 9, 8, 11, 30)), isNull);
      // Before a2 starts, a2 is the next up.
      final next = summary.nextActivityAfter(DateTime(2026, 9, 8, 9));
      expect(next!.id, 'a2');
      // After everything, nothing is next.
      expect(summary.nextActivityAfter(DateTime(2026, 9, 8, 23)), isNull);
    });

    test('finance defaults to empty', () {
      expect(summary.finance.income, 0);
      expect(summary.finance.expense, 0);
      expect(summary.finance.balance, 0);
    });
  });

  group('FinanceSummary', () {
    test('balance is income minus expense', () {
      const finance = FinanceSummary(income: 100, expense: 30);
      expect(finance.balance, 70);
    });
  });

  group('DashboardRepository', () {
    late db.AppDatabase database;
    late DashboardRepository repository;

    setUp(() {
      database = db.AppDatabase(NativeDatabase.memory());
      repository = DashboardRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('builds a summary from activities and transactions', () async {
      final now = DateTime(2026, 9, 8, 12);
      await database.insertActivity(
        db.Activity(
          id: 'a1',
          title: 'Study',
          category: 'study',
          startTime: DateTime(2026, 9, 8, 9),
          endTime: DateTime(2026, 9, 8, 10),
          status: 'completed',
          scheduleId: null,
          notes: null,
          createdAt: DateTime.now(),
        ),
      );
      await database.insertTransaction(
        db.Transaction(
          id: 't1',
          type: 'income',
          category: 'salary',
          amount: 100,
          description: null,
          date: DateTime(2026, 9, 8, 10),
          createdAt: DateTime.now(),
        ),
      );

      final summary = await repository.buildSummaryForDay(now);
      expect(summary.totalActivities, 1);
      expect(summary.activities.first.id, 'a1');
      expect(summary.finance.income, 100);
      expect(summary.finance.expense, 0);

      final emptyDay = await repository.buildSummaryForDay(
        DateTime(2026, 1, 1),
      );
      expect(emptyDay.totalActivities, 0);
      expect(emptyDay.finance.income, 0);
    });

    test('expense is subtracted correctly', () async {
      await database.insertTransaction(
        db.Transaction(
          id: 't1',
          type: 'expense',
          category: 'food',
          amount: 25,
          description: null,
          date: DateTime(2026, 9, 8, 10),
          createdAt: DateTime.now(),
        ),
      );
      final summary = await repository.buildSummaryForDay(DateTime(2026, 9, 8));
      expect(summary.finance.expense, 25);
      expect(summary.finance.balance, -25);
    });
  });

  group('DashboardScreen widget', () {
    testWidgets('shows empty state when nothing is planned', (tester) async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      final summary = DashboardSummary(
        day: DateTime(2026, 9, 8, 12),
        activities: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(DateTime(2026, 9, 8, 12)),
            dashboardSummaryProvider.overrideWith((ref) async => summary),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Nothing planned today."), findsOneWidget);
      expect(find.text('No transactions today.'), findsOneWidget);
      expect(find.text('Daily Progress'), findsOneWidget);
    });

    testWidgets('shows planned activities in the timeline', (tester) async {
      final summary = DashboardSummary(
        day: DateTime(2026, 9, 8, 12),
        activities: [
          Activity(
            id: 'a1',
            title: 'Business Process Reengineering',
            category: 'study',
            startTime: DateTime(2026, 9, 8, 10, 10),
            endTime: DateTime(2026, 9, 8, 11, 30),
            status: ActivityStatus.scheduled,
          ),
          Activity(
            id: 'a2',
            title: 'Data Mining',
            category: 'study',
            startTime: DateTime(2026, 9, 8, 13, 10),
            endTime: DateTime(2026, 9, 8, 14, 30),
            status: ActivityStatus.scheduled,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(DateTime(2026, 9, 8, 12)),
            dashboardSummaryProvider.overrideWith((ref) async => summary),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Business Process Reengineering'), findsOneWidget);
      expect(find.text('Data Mining'), findsOneWidget);
      expect(find.text('NEXT UP'), findsOneWidget);
    });
  });
}
