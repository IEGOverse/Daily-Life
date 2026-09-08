import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/core/database/database.dart' as db;
import 'package:daily_life/core/database/database_provider.dart';
import 'package:daily_life/core/router/app_router.dart';
import 'package:daily_life/features/insights/data/insights_repository.dart';
import 'package:daily_life/features/insights/domain/daily_score.dart';
import 'package:daily_life/main.dart';

void main() {
  group('DailyScore', () {
    test('pure task score (no habits)', () {
      final score = DailyScore.compute(
        completedActivities: 3,
        totalActivities: 4,
        completedHabits: 0,
        activeHabits: 0,
      );
      expect(score.taskScore, closeTo(0.75, 0.001));
      expect(score.habitScore, 1.0);
      expect(score.score, 88); // round(0.75*50 + 1.0*50) = round(87.5) = 88
      expect(score.hasData, isTrue);
    });

    test('pure habit score (no tasks)', () {
      final score = DailyScore.compute(
        completedActivities: 0,
        totalActivities: 0,
        completedHabits: 2,
        activeHabits: 4,
      );
      expect(score.taskScore, 1.0);
      expect(score.habitScore, 0.5);
      expect(score.score, 75); // round(1.0*50 + 0.5*50) = 75
      expect(score.hasData, isTrue);
    });

    test('both components weighted fifty-fifty', () {
      final score = DailyScore.compute(
        completedActivities: 4,
        totalActivities: 4,
        completedHabits: 2,
        activeHabits: 4,
      );
      expect(score.score, 75); // round(1.0*50 + 0.5*50)
    });

    test('empty day has no data and no implied score', () {
      final score = DailyScore.compute(
        completedActivities: 0,
        totalActivities: 0,
        completedHabits: 0,
        activeHabits: 0,
      );
      expect(score.hasData, isFalse);
      expect(score.score, 0);
    });

    test('perfect day scores 100', () {
      final score = DailyScore.compute(
        completedActivities: 2,
        totalActivities: 2,
        completedHabits: 3,
        activeHabits: 3,
      );
      expect(score.score, 100);
    });
  });

  group('InsightsRepository', () {
    final weekStart = DateTime(2026, 9, 7); // Monday
    final weekEnd = weekStart.add(const Duration(days: 7));

    db.AppDatabase newDatabase() {
      final d = db.AppDatabase(NativeDatabase.memory());
      addTearDown(d.close);
      return d;
    }

    test('daily score derives from activities and habits', () async {
      final database = newDatabase();
      final repo = InsightsRepository(database);

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
      await database.insertActivity(
        db.Activity(
          id: 'a2',
          title: 'Workout',
          category: 'workout',
          startTime: DateTime(2026, 9, 8, 16),
          endTime: null,
          status: 'scheduled',
          scheduleId: null,
          notes: null,
          createdAt: DateTime.now(),
        ),
      );
      await database.insertHabit(
        db.Habit(
          id: 'h1',
          name: 'Read',
          frequency: 'daily',
          target: 1,
          isActive: 1,
          createdAt: DateTime(2026, 9, 1),
        ),
      );
      await database.insertHabitLog(
        db.HabitLog(
          id: 'l1',
          habitId: 'h1',
          date: DateTime(2026, 9, 8),
          completed: 1,
        ),
      );

      final score = await repo.dailyScore(DateTime(2026, 9, 8));
      // 1/2 tasks completed, 1/1 habit completed.
      expect(score.taskScore, closeTo(0.5, 0.001));
      expect(score.habitScore, 1.0);
      expect(score.score, 75); // round(0.5*50 + 1.0*50)
      expect(score.hasData, isTrue);
    });

    test('weekly summary derives cross-module values from records', () async {
      final database = newDatabase();
      final repo = InsightsRepository(database);

      // Activities: 2 completed, 1 scheduled.
      await database.insertActivity(
        db.Activity(
          id: 'a1',
          title: 'Study',
          category: 'study',
          startTime: DateTime(2026, 9, 7, 9),
          endTime: DateTime(2026, 9, 7, 10),
          status: 'completed',
          createdAt: DateTime.now(),
        ),
      );
      await database.insertActivity(
        db.Activity(
          id: 'a2',
          title: 'Workout',
          category: 'workout',
          startTime: DateTime(2026, 9, 8, 16),
          endTime: DateTime(2026, 9, 8, 17),
          status: 'completed',
          createdAt: DateTime.now(),
        ),
      );
      await database.insertActivity(
        db.Activity(
          id: 'a3',
          title: 'Lecture',
          category: 'study',
          startTime: DateTime(2026, 9, 9, 9),
          endTime: null,
          status: 'scheduled',
          createdAt: DateTime.now(),
        ),
      );

      // Study sessions: 90 minutes in-range, one outside week.
      await database.insertStudySession(
        db.StudySession(
          id: 's1',
          subject: 'Math',
          date: DateTime(2026, 9, 7),
          startTime: DateTime(2026, 9, 7, 10),
          endTime: DateTime(2026, 9, 7, 11, 30),
          durationSeconds: 5400,
          notes: null,
        ),
      );
      await database.insertStudySession(
        db.StudySession(
          id: 's2',
          subject: 'Old',
          date: DateTime(2026, 8, 1),
          startTime: DateTime(2026, 8, 1, 10),
          endTime: DateTime(2026, 8, 1, 11),
          durationSeconds: 3600,
          notes: null,
        ),
      );

      // Workouts: completed 30 min, one open.
      await database.insertWorkoutSession(
        db.WorkoutSession(
          id: 'w1',
          workoutPlanId: 'p1',
          date: DateTime(2026, 9, 8),
          startTime: DateTime(2026, 9, 8, 16),
          endTime: DateTime(2026, 9, 8, 16, 30),
          durationSeconds: 1800,
          completed: 1,
          notes: null,
        ),
      );
      await database.insertWorkoutSession(
        db.WorkoutSession(
          id: 'w2',
          workoutPlanId: 'p1',
          date: DateTime(2026, 8, 1),
          startTime: DateTime(2026, 8, 1, 16),
          endTime: null,
          durationSeconds: null,
          completed: 0,
          notes: null,
        ),
      );

      // Transactions within week.
      await database.insertTransaction(
        db.Transaction(
          id: 't1',
          type: 'income',
          category: 'salary',
          amount: 5000,
          date: DateTime(2026, 9, 7),
          createdAt: DateTime.now(),
        ),
      );
      await database.insertTransaction(
        db.Transaction(
          id: 't2',
          type: 'expense',
          category: 'food',
          amount: 1500,
          date: DateTime(2026, 9, 8),
          createdAt: DateTime.now(),
        ),
      );

      // Meals within week.
      await database.insertMeal(
        db.Meal(
          id: 'm1',
          mealType: 'Lunch',
          date: DateTime(2026, 9, 8),
          time: DateTime(2026, 9, 8, 12),
          notes: null,
        ),
      );

      // Habits: 2 active, 1 completion today, 1 log not completed.
      await database.insertHabit(
        db.Habit(
          id: 'h1',
          name: 'Read',
          frequency: 'daily',
          target: 1,
          isActive: 1,
          createdAt: DateTime(2026, 9, 1),
        ),
      );
      await database.insertHabit(
        db.Habit(
          id: 'h2',
          name: 'Write',
          frequency: 'daily',
          target: 1,
          isActive: 1,
          createdAt: DateTime(2026, 9, 1),
        ),
      );
      await database.insertHabitLog(
        db.HabitLog(
          id: 'l1',
          habitId: 'h1',
          date: DateTime(2026, 9, 8),
          completed: 1,
        ),
      );
      await database.insertHabitLog(
        db.HabitLog(
          id: 'l2',
          habitId: 'h2',
          date: DateTime(2026, 9, 8),
          completed: 0,
        ),
      );

      final summary = await repo.weeklySummary(weekStart, weekEnd);
      expect(summary.plannedActivities, 3);
      expect(summary.completedActivities, 2);
      expect(summary.studySessions, 1);
      expect(summary.studyMinutes, closeTo(90, 0.001));
      expect(summary.workouts, 1);
      expect(summary.workoutMinutes, closeTo(30, 0.001));
      expect(summary.mealCount, 1);
      expect(summary.income, 5000);
      expect(summary.expense, 1500);
      expect(summary.balanceChange, 3500);
      expect(summary.habitCompletions, 1);
      expect(summary.habitLogDays, 2);
      expect(summary.scoredDays, greaterThan(0));
      expect(summary.averageScore, inInclusiveRange(0, 100));
    });

    test(
      'time analytics derives study, workout and activity minutes',
      () async {
        final database = newDatabase();
        final repo = InsightsRepository(database);

        await database.insertStudySession(
          db.StudySession(
            id: 's1',
            subject: 'Math',
            date: DateTime(2026, 9, 7),
            startTime: DateTime(2026, 9, 7, 10),
            endTime: DateTime(2026, 9, 7, 11),
            durationSeconds: 3600,
            notes: null,
          ),
        );
        await database.insertWorkoutSession(
          db.WorkoutSession(
            id: 'w1',
            workoutPlanId: 'p1',
            date: DateTime(2026, 9, 8),
            startTime: DateTime(2026, 9, 8, 16),
            endTime: DateTime(2026, 9, 8, 16, 30),
            durationSeconds: 1800,
            completed: 1,
            notes: null,
          ),
        );
        await database.insertWorkoutSession(
          db.WorkoutSession(
            id: 'w2',
            workoutPlanId: 'p1',
            date: DateTime(2026, 9, 9),
            startTime: DateTime(2026, 9, 9, 16),
            endTime: null,
            durationSeconds: null,
            completed: 0,
            notes: null,
          ),
        );
        await database.insertActivity(
          db.Activity(
            id: 'a1',
            title: 'Seminar',
            category: 'seminar',
            startTime: DateTime(2026, 9, 9, 9),
            endTime: DateTime(2026, 9, 9, 9, 30),
            status: 'completed',
            createdAt: DateTime.now(),
          ),
        );

        final time = await repo.timeAnalytics(weekStart, weekEnd);
        expect(
          time.totalMinutes,
          closeTo(120, 0.001),
        ); // 60 study + 30 workout + 30 seminar
        final study = time.entries.firstWhere((e) => e.label == 'Study');
        expect(study.minutes, 60);
        expect(study.fraction, closeTo(0.5, 0.001));
        final workout = time.entries.firstWhere((e) => e.label == 'Workout');
        expect(workout.minutes, 30);
      },
    );

    test('empty database yields empty analytics', () async {
      final database = newDatabase();
      final repo = InsightsRepository(database);

      final summary = await repo.weeklySummary(weekStart, weekEnd);
      expect(summary.plannedActivities, 0);
      expect(summary.scoredDays, 0);
      expect(summary.averageScore, 0);

      final time = await repo.timeAnalytics(weekStart, weekEnd);
      expect(time.isEmpty, isTrue);
    });
  });

  group('Insights screen flow', () {
    testWidgets('renders empty state', (tester) async {
      final container = ProviderContainer(
        overrides: [inMemoryDatabaseOverride()],
      );
      addTearDown(container.dispose);
      final database = container.read(databaseProvider);
      addTearDown(database.close);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DailyLifeApp(),
        ),
      );
      await tester.pumpAndSettle();

      container.read(appRouterProvider).go('/insights');
      await tester.pumpAndSettle();

      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('No time recorded this week yet.'), findsOneWidget);
    });
  });
}
