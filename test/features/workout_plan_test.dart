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
import 'package:daily_life/features/workout/data/workout_session_repository.dart';
import 'package:daily_life/features/workout/data/workout_set_log_repository.dart';
import 'package:daily_life/features/workout/domain/workout_plan.dart';
import 'package:daily_life/features/workout/domain/workout_set_log.dart';
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
      final exercises = await ExerciseRepository(database).getAll();
      final exercise = exercises.first;
      await repository.insert(
        plan: const WorkoutPlan(id: 'plan_delete', name: 'Temporary'),
        exercises: [WorkoutPlanDraftExercise(exercise: exercise)],
      );
      await repository.delete('plan_delete');

      expect(await repository.byId('plan_delete'), isNull);
      expect(await database.getWorkoutPlanExercises('plan_delete'), isEmpty);
    });

    test('retains plans that have session history', () async {
      final exercises = await ExerciseRepository(database).getAll();
      final exercise = exercises.first;
      await repository.insert(
        plan: const WorkoutPlan(id: 'plan_retained', name: 'Retained'),
        exercises: [WorkoutPlanDraftExercise(exercise: exercise)],
      );
      final sessions = WorkoutSessionRepository(database);
      await sessions.start(
        workoutPlanId: 'plan_retained',
        now: DateTime(2026, 9, 8, 8),
      );

      expect(
        () => repository.delete('plan_retained'),
        throwsA(isA<StateError>()),
      );
      expect(await repository.byId('plan_retained'), isNotNull);
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
        find.text('Belum ada rencana olahraga. Buat satu untuk memulai.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Rencana Baru'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Push/Legs');
      await tester.tap(find.text('Bicep Curl'));
      await tester.tap(find.text('Simpan Rencana'));
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
      expect(find.text('Gerakan'), findsOneWidget);
      expect(find.text('Bicep Curl'), findsOneWidget);
      expect(
        find.text('3 set x 10 repetisi  •  60d istirahat'),
        findsOneWidget,
      );

      await tester.tap(find.text('Mulai Olahraga'));
      await tester.pumpAndSettle();
      expect(find.text('Berlangsung'), findsOneWidget);
      await tester.tap(find.text('Catat Set'));
      await tester.pumpAndSettle();
      expect(find.text('Simpan Catatan Set'), findsOneWidget);
      await tester.tap(find.byType(Checkbox).first);
      await tester.tap(find.text('Simpan Catatan Set'));
      await tester.pumpAndSettle();
      final sessionId = (await database.getAllWorkoutSessions()).single.id;
      expect((await database.getWorkoutSetLogs(sessionId)).first.completed, 1);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selesaikan Olahraga'));
      await tester.pumpAndSettle();
      expect(find.text('Selesai'), findsOneWidget);
      container.read(appRouterProvider).go('/workout/history');
      await tester.pumpAndSettle();
      expect(find.text('Olahraga'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
      expect(find.text('Push/Legs'), findsOneWidget);
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
      await tester.tap(find.text('Simpan Rencana'));
      await tester.pumpAndSettle();
      expect(find.text('Masukkan nama rencana.'), findsOneWidget);
      expect(await database.getAllWorkoutPlans(), isEmpty);
    });
  });

  group('WorkoutSessionRepository', () {
    test('starts and completes a session with its duration', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final planRepository = WorkoutPlanRepository(database);
      await ensureExerciseLibrarySeeded(database);
      final exercise = (await ExerciseRepository(database).getAll());
      await planRepository.insert(
        plan: const WorkoutPlan(id: 'plan_session', name: 'Session plan'),
        exercises: [WorkoutPlanDraftExercise(exercise: exercise.first)],
      );
      final repository = WorkoutSessionRepository(database);
      final started = await repository.start(
        workoutPlanId: 'plan_session',
        now: DateTime(2026, 9, 8, 8),
      );
      await repository.complete(
        started.id,
        endTime: DateTime(2026, 9, 8, 8, 1, 30),
      );

      final finished = await repository.byId(started.id);
      expect(finished?.completed, isTrue);
      expect(finished?.durationSeconds, 90);
      expect(finished?.plan?.name, 'Session plan');
      expect(await repository.getAll(), hasLength(1));
    });

    test('rejects an end time before the session start', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await ensureExerciseLibrarySeeded(database);
      final plans = WorkoutPlanRepository(database);
      final exercises = await ExerciseRepository(database).getAll();
      final exercise = exercises.first;
      await plans.insert(
        plan: const WorkoutPlan(id: 'plan_invalid_time', name: 'Timing'),
        exercises: [WorkoutPlanDraftExercise(exercise: exercise)],
      );
      final repository = WorkoutSessionRepository(database);
      final session = await repository.start(
        workoutPlanId: 'plan_invalid_time',
        now: DateTime(2026, 9, 8, 8),
      );

      expect(
        () => repository.complete(
          session.id,
          endTime: DateTime(2026, 9, 8, 7, 59),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect((await repository.byId(session.id))?.completed, isFalse);
    });

    test('materializes prescribed sets and updates actual logging', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await ensureExerciseLibrarySeeded(database);
      final plans = WorkoutPlanRepository(database);
      final exercises = await ExerciseRepository(database).getAll();
      final exercise = exercises.first;
      await plans.insert(
        plan: const WorkoutPlan(id: 'plan_sets', name: 'Set plan'),
        exercises: [
          WorkoutPlanDraftExercise(exercise: exercise, sets: 3, reps: 8),
          WorkoutPlanDraftExercise(exercise: exercises[1], sets: 1, reps: 5),
        ],
      );
      final session = await WorkoutSessionRepository(database)
          .start(workoutPlanId: 'plan_sets', now: DateTime(2026, 9, 8, 8));
      final repository = WorkoutSetLogRepository(database);
      final results = await Future.wait([
        repository.ensureForSession(session.id),
        repository.ensureForSession(session.id),
      ]);
      final logs = results.first;
      expect(logs, hasLength(4));
      expect(logs.first.reps, 8);

      await repository.update(
        WorkoutSetLog(
          id: logs.first.id,
          workoutSessionId: session.id,
          exerciseId: logs.first.exerciseId,
          setNumber: logs.first.setNumber,
          reps: 7,
          weight: 42.5,
          completed: true,
        ),
      );
      final updated = (await repository.forSession(session.id)).first;
      expect(updated.reps, 7);
      expect(updated.weight, 42.5);
      expect(updated.completed, isTrue);
      expect(await repository.ensureForSession(session.id), hasLength(4));
    });
  });
}
