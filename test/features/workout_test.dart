import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/core/database/database.dart' as db;
import 'package:daily_life/core/database/database_provider.dart';
import 'package:daily_life/core/router/app_router.dart';
import 'package:daily_life/features/dashboard/dashboard_providers.dart';
import 'package:daily_life/features/workout/data/exercise_repository.dart';
import 'package:daily_life/features/workout/domain/exercise.dart';
import 'package:daily_life/features/workout/workout_screen.dart';
import 'package:daily_life/main.dart';

void main() {
  group('ExerciseLibrarySeeder', () {
    test('initialExercises returns a complete library', () {
      final exercises = ExerciseLibrarySeeder.initialExercises();
      expect(exercises, hasLength(15));
      expect(exercises.map((e) => e.id).toSet(), hasLength(exercises.length));

      for (final exercise in exercises) {
        expect(exercise.id, isNotEmpty);
        expect(exercise.name, isNotEmpty);
        expect(exercise.muscleGroup, isNotEmpty);
        expect(exercise.description, isNotNull);
        expect(exercise.instructions, isNotNull);
      }
    });

    test('covers every muscle group', () {
      final groups = ExerciseLibrarySeeder.initialExercises()
          .map((e) => e.muscleGroup)
          .toSet();
      expect(groups, containsAll(exerciseMuscleGroups));
    });
  });

  group('ensureExerciseLibrarySeeded', () {
    late db.AppDatabase database;

    setUp(() async {
      database = db.AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('seeds the library once', () async {
      await ensureExerciseLibrarySeeded(database);
      expect(await database.getAllExercises(), hasLength(15));
    });

    test('is idempotent', () async {
      await ensureExerciseLibrarySeeded(database);
      await ensureExerciseLibrarySeeded(database);
      expect(await database.getAllExercises(), hasLength(15));
    });

    test(
      'concurrent calls share one in-flight seed and never conflict',
      () async {
        final results = await Future.wait([
          ensureExerciseLibrarySeeded(database),
          ensureExerciseLibrarySeeded(database),
          ensureExerciseLibrarySeeded(database),
        ]);
        expect(results, hasLength(3));
        expect(await database.getAllExercises(), hasLength(15));
      },
    );
  });

  group('ExerciseRepository', () {
    late db.AppDatabase database;
    late ExerciseRepository repository;

    setUp(() async {
      database = db.AppDatabase(NativeDatabase.memory());
      repository = ExerciseRepository(database);
      await ensureExerciseLibrarySeeded(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('getAll orders by muscle group then name', () async {
      final exercises = await repository.getAll();
      expect(exercises, hasLength(15));
      expect(exercises.first.muscleGroup, 'arms');
      expect(exercises.first.name, 'Bicep Curl');
    });

    test('byMuscleGroup returns only that group', () async {
      final legs = await repository.byMuscleGroup('legs');
      expect(legs.every((e) => e.muscleGroup == 'legs'), isTrue);
      expect(legs.map((e) => e.name), contains('Deadlift'));
    });

    test('byId resolves and unknown id returns null', () async {
      final bench = await repository.byId('bench_press');
      expect(bench?.name, 'Bench Press');
      expect(await repository.byId('missing'), isNull);
    });

    test('insert persists a personal exercise', () async {
      await repository.insert(
        const Exercise(
          id: 'exercise_test_skip_pulldown',
          name: 'Skip Pulldown',
          muscleGroup: 'back',
          description: 'fun',
          instructions: 'do it',
        ),
      );
      final found = await repository.byId('exercise_test_skip_pulldown');
      expect(found?.name, 'Skip Pulldown');
      expect(found?.muscleGroup, 'back');
    });

    test('delete removes an exercise', () async {
      await repository.insert(
        const Exercise(
          id: 'exercise_test_temp',
          name: 'Temp Exercise',
          muscleGroup: 'core',
        ),
      );
      expect(await repository.byId('exercise_test_temp'), isNotNull);
      await database.deleteExercise('exercise_test_temp');
      expect(await repository.byId('exercise_test_temp'), isNull);
    });
  });

  group('WorkoutScreen widget', () {
    testWidgets('shows the seeded library', (tester) async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: const MaterialApp(home: WorkoutScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bicep Curl'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Pull-Up'), findsOneWidget);
    });

    testWidgets('muscle-group chip filters the list', (tester) async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: const MaterialApp(home: WorkoutScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Legs'));
      await tester.pumpAndSettle();

      expect(find.text('Deadlift'), findsOneWidget);
      expect(find.text('Bench Press'), findsNothing);
    });

    testWidgets('search filters by name', (tester) async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: const MaterialApp(home: WorkoutScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'pull');
      await tester.pumpAndSettle();

      expect(find.text('Pull-Up'), findsOneWidget);
      expect(find.text('Bench Press'), findsNothing);
    });
  });

  group('Workout flow through the app router', () {
    testWidgets(
      "browse -> detail shows instructions, and quick-add persists to the library",
      (tester) async {
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

        // Open the exercise library.
        container.read(appRouterProvider).go('/workout');
        await tester.pumpAndSettle();

        // Drill into a detail screen and see the instructions.
        await tester.tap(find.text('Bicep Curl'));
        await tester.pumpAndSettle();
        expect(find.text('Instructions'), findsOneWidget);
        expect(find.textContaining('shoulders'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Add a personal exercise.
        await tester.tap(find.byIcon(Icons.add_circle_outline));
        await tester.pumpAndSettle();
        expect(find.text('Add exercise'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'),
          'Cable Crunch',
        );
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Core').last);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Instructions (optional)'),
          'Kneel at a cable stack and crunch your elbows toward your knees.',
        );
        await tester.tap(find.text('Save exercise'));
        await tester.pumpAndSettle();

        // Back on the library screen.
        expect(find.text('Add exercise'), findsNothing);
        expect(find.text('Workout'), findsOneWidget);

        // Persisted with the selected muscle group.
        final all = await database.getAllExercises();
        expect(all, hasLength(16));
        final created = all.where((e) => e.name == 'Cable Crunch');
        expect(created, hasLength(1));
        expect(created.single.muscleGroup, 'core');
        expect(created.single.instructions, isNotNull);

        // And listed in the library UI (it is last, so scroll it into view).
        await tester.scrollUntilVisible(
          find.text('Cable Crunch'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('Cable Crunch'), findsOneWidget);
      },
    );

    testWidgets('add form validates an empty name and does not persist', (
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

      container.read(appRouterProvider).go('/workout/add');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save exercise'));
      await tester.pumpAndSettle();

      expect(find.text('Enter an exercise name.'), findsOneWidget);
      expect(await database.getAllExercises(), hasLength(15));
    });
  });
}
