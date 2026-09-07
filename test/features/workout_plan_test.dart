import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/core/database/database.dart' as db;
import 'package:daily_life/core/database/database_provider.dart';
import 'package:daily_life/core/router/app_router.dart';
import 'package:daily_life/features/dashboard/dashboard_providers.dart';
import 'package:daily_life/features/workout/data/exercise_repository.dart';
import 'package:daily_life/features/workout/data/workout_plan_repository.dart';
import 'package:daily_life/features/workout/domain/workout_plan.dart';
import 'package:daily_life/main.dart';

void main() {
  group('WorkoutPlanRepository', () {
    late db.AppDatabase database;
    late WorkoutPlanRepository repository;

    setUp(() async {
      database = db.AppDatabase(NativeDatabase.memory());
      repository = WorkoutPlanRepository(database);
      await ensureExerciseLibrarySeeded(database);
    });

    tearDown(() async => database.close());

    test('creates a plan and ordered exercise links atomically', () async {
      final exercises = await ExerciseRepository(database).getAll();
      final plan = const WorkoutPlan(
        id: 'plan_push',
        name: 'Push Day',
        description: 'Upper body push',
        dayLabel: 'Monday',
      );
      await repository.insert(
        plan: plan,
        exercises: [
          WorkoutPlanDraftExercise(exercise: exercises[0]),
          WorkoutPlanDraftExercise(exercise: exercises[1], sets: 4, reps: 8),
        ],
      );

      expect((await repository.getAll()).single.name, 'Push Day');
      final links = await repository.exercisesWithDetails(plan.id);
      expect(links, hasLength(2));
      expect(links.first.sortOrder, 0);
      expect(links.first.exercise, isNotNull);
      expect(links[1].sets, 4);
      expect(links[1].reps, 8);
    });

    test('deletes a plan and its links', () async {
      final exercise = (await ExerciseRepository(database).getAll()).first;
      await repository.insert(
        plan: const WorkoutPlan(id: 'plan_delete', name: 'Temporary'),
        exercises: [WorkoutPlanDraftExercise(exercise: exercise)],
      );
      await repository.delete('plan_delete');

      expect(await repository.byId('plan_delete'), isNull);
      expect(await database.getWorkoutPlanExercises('plan_delete'), isEmpty);
    });
  });

  group('Workout plan flow', () {
    testWidgets('creates a plan and opens its exercise details', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          inMemoryDatabaseOverride(),
          clockProvider.overrideWithValue(DateTime(2026, 9, 8, 8)),
        ],
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

      container.read(appRouterProvider).go('/workout/plans');
      await tester.pumpAndSettle();
      expect(
        find.text('No workout plans yet. Create one to get started.'),
        findsOneWidget,
      );

      await tester.tap(find.text('New plan'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Push/Legs');
      await tester.tap(find.text('Bicep Curl'));
      await tester.tap(find.text('Save plan'));
      await tester.pumpAndSettle();

      expect(find.text('Push/Legs'), findsOneWidget);
      expect(await database.getAllWorkoutPlans(), hasLength(1));
      expect(
        await database.getWorkoutPlanExercises(
          (await database.getAllWorkoutPlans()).single.id,
        ),
        hasLength(1),
      );

      await tester.tap(find.text('Push/Legs'));
      await tester.pumpAndSettle();
      expect(find.text('Exercises'), findsOneWidget);
      expect(find.text('Bicep Curl'), findsOneWidget);
      expect(find.text('3 sets x 10 reps  •  60s rest'), findsOneWidget);
    });

    testWidgets('requires a plan name and one exercise', (tester) async {
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
      container.read(appRouterProvider).go('/workout/plans/add');
      await tester.pumpAndSettle();

      await tester.pumpAndSettle();
      await tester.tap(find.text('Save plan'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a plan name.'), findsOneWidget);
      expect(await database.getAllWorkoutPlans(), isEmpty);
    });
  });
}
