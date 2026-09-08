import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/core/database/database.dart' as db;
import 'package:daily_life/core/database/database_provider.dart';
import 'package:daily_life/core/router/app_router.dart';
import 'package:daily_life/features/habits/data/habit_repository.dart';
import 'package:daily_life/features/habits/domain/habit.dart';
import 'package:daily_life/main.dart';

void main() {
  group('HabitRepository', () {
    final day = DateTime(2026, 9, 8); // Tuesday

    Habit makeHabit(String id, {bool active = true}) => Habit(
      id: id,
      name: 'Read',
      frequency: 'daily',
      target: 1,
      isActive: active,
      createdAt: DateTime(2026, 9, 1),
    );

    test('CRUD: insert, read, update, delete a habit (cascade logs)', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = HabitRepository(database);

      await repository.insertHabit(makeHabit('h1'));
      expect(await repository.getHabits(), hasLength(1));
      expect((await repository.habitById('h1'))?.name, 'Read');

      await repository.setCompleted('h1', day, true);
      await repository.deleteHabit('h1');
      expect(await repository.getHabits(), isEmpty);
      expect(await repository.logsForDay(day), isEmpty);
    });

    test('toggle today completion creates and clears a log', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = HabitRepository(database);

      await repository.insertHabit(makeHabit('h1'));
      await repository.setCompleted('h1', day, true);

      final statuses = await repository.habitsWithStatus(day);
      expect(statuses.first.completedToday, isTrue);
      expect(statuses.first.currentStreak, 1);
      expect(await repository.logsForDay(day), hasLength(1));

      await repository.setCompleted('h1', day, false);
      final after = await repository.habitsWithStatus(day);
      expect(after.first.completedToday, isFalse);
      expect(after.first.currentStreak, 0);
    });

    test('streak: consecutive days count, a gap breaks the streak', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = HabitRepository(database);

      await repository.insertHabit(makeHabit('h1'));
      await repository.setCompleted('h1', DateTime(2026, 9, 6), true);
      await repository.setCompleted('h1', DateTime(2026, 9, 7), true);
      await repository.setCompleted('h1', DateTime(2026, 9, 8), true);

      final statuses = await repository.habitsWithStatus(day);
      expect(statuses.first.currentStreak, 3);
      expect(statuses.first.bestStreak, 3);
      expect(statuses.first.totalCompletions, 3);
    });

    test('streak stays alive when today is not yet logged', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = HabitRepository(database);

      await repository.insertHabit(makeHabit('h1'));
      // Completed yesterday and the day before; today not yet logged.
      await repository.setCompleted('h1', DateTime(2026, 9, 6), true);
      await repository.setCompleted('h1', DateTime(2026, 9, 7), true);

      final statuses = await repository.habitsWithStatus(day);
      expect(statuses.first.completedToday, isFalse);
      expect(statuses.first.currentStreak, 2);
    });

    test('streak breaks after a missed day before today', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = HabitRepository(database);

      await repository.insertHabit(makeHabit('h1'));
      await repository.setCompleted('h1', DateTime(2026, 9, 5), true);
      await repository.setCompleted('h1', DateTime(2026, 9, 6), true);
      // Day 7 missed.
      await repository.setCompleted('h1', DateTime(2026, 9, 8), true);

      final statuses = await repository.habitsWithStatus(day);
      expect(statuses.first.currentStreak, 1);
      expect(statuses.first.bestStreak, 2);
    });

    test('best streak tracks the longest run across gaps', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = HabitRepository(database);

      await repository.insertHabit(makeHabit('h1'));
      // Run of 3, gap, run of 2.
      for (var d = 0; d < 3; d++) {
        await repository.setCompleted(
          'h1',
          DateTime(2026, 8, 1).add(Duration(days: d)),
          true,
        );
      }
      await repository.setCompleted('h1', DateTime(2026, 8, 5), true);
      await repository.setCompleted('h1', DateTime(2026, 8, 6), true);

      final statuses = await repository.habitsWithStatus(day);
      expect(statuses.first.bestStreak, 3);
      expect(statuses.first.currentStreak, 0);
    });

    test('inactive habits are not included as active status', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = HabitRepository(database);

      await repository.insertHabit(makeHabit('h1', active: false));
      await repository.insertHabit(makeHabit('h2'));

      expect(await repository.getActiveHabits(), hasLength(1));
      // habitsWithStatus lists all habits (active and inactive).
      expect(await repository.habitsWithStatus(day), hasLength(2));
    });
  });

  group('Habits screen flow', () {
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

      container.read(appRouterProvider).go('/habits');
      await tester.pumpAndSettle();

      expect(find.text('Kebiasaan'), findsOneWidget);
      expect(find.text('Belum ada kebiasaan.'), findsOneWidget);
    });
  });
}
