import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_life/core/database/database.dart' as db;
import 'package:daily_life/core/database/database_provider.dart';
import 'package:daily_life/core/router/app_router.dart';
import 'package:daily_life/features/dashboard/dashboard_providers.dart';
import 'package:daily_life/features/profile/profile_providers.dart';
import 'package:daily_life/features/profile/profile_repository.dart';
import 'package:daily_life/features/study/study_providers.dart';
import 'package:daily_life/main.dart';

void main() {
  group('Study sync to dashboard', () {
    test('today study minutes update after a session insert', () async {
      final container = ProviderContainer(
        overrides: [
          inMemoryDatabaseOverride(),
          clockProvider.overrideWithValue(DateTime(2026, 9, 8, 8)),
        ],
      );
      addTearDown(container.dispose);
      final database = container.read(databaseProvider);
      addTearDown(database.close);

      expect(await container.read(todayStudyMinutesProvider.future), 0);

      await database.insertStudySession(
        db.StudySession(
          id: 's1',
          subject: 'Math',
          date: DateTime(2026, 9, 8),
          startTime: DateTime(2026, 9, 8, 9),
          endTime: DateTime(2026, 9, 8, 10),
          durationSeconds: 3600,
          notes: null,
        ),
      );
      container.invalidate(studySessionsProvider);

      expect(await container.read(todayStudyMinutesProvider.future), 60);
    });

    test('only sessions on the current day count toward the total', () async {
      final container = ProviderContainer(
        overrides: [
          inMemoryDatabaseOverride(),
          clockProvider.overrideWithValue(DateTime(2026, 9, 8, 8)),
        ],
      );
      addTearDown(container.dispose);
      final database = container.read(databaseProvider);
      addTearDown(database.close);

      await database.insertStudySession(
        db.StudySession(
          id: 's1',
          subject: 'Old',
          date: DateTime(2026, 9, 1),
          startTime: DateTime(2026, 9, 1, 9),
          endTime: DateTime(2026, 9, 1, 10),
          durationSeconds: 3600,
          notes: null,
        ),
      );
      container.invalidate(studySessionsProvider);

      expect(await container.read(todayStudyMinutesProvider.future), 0);
    });
  });

  group('Profile', () {
    test('default name and a save/load round trip', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = ProfileRepository();

      expect(
        await repository.loadDisplayName(),
        ProfileRepository.defaultDisplayName,
      );

      await repository.saveDisplayName('Andi');
      expect(await repository.loadDisplayName(), 'Andi');
    });

    test('displayNameProvider reflects a stored name', () async {
      SharedPreferences.setMockInitialValues({'profile.display_name': 'Andi'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(displayNameProvider.future), 'Andi');
    });
  });

  group('Nutrition first-use flow', () {
    testWidgets('creates a food then saves a meal with it', (tester) async {
      tester.view.physicalSize = const Size(1440, 3200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final container = await _pumpApp(tester);
      final database = container.read(databaseProvider);
      addTearDown(database.close);

      container.read(appRouterProvider).go('/nutrition');
      await tester.pumpAndSettle();

      expect(find.text('Nutrisi'), findsOneWidget);
      expect(
        find.text('Belum ada makanan yang tercatat hari ini.'),
        findsOneWidget,
      );

      // No foods yet -> the Add Meal dialog guides the user to create one.
      await tester.tap(find.text('Tambah Makanan'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada makanan di database.'), findsOneWidget);
      expect(find.text('Tambah Makanan Baru'), findsOneWidget);

      await tester.tap(find.text('Tambah Makanan Baru'));
      await tester.pumpAndSettle();

      // Fill the new-food form.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama'),
        'Nasi Putih',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Kalori (per porsi)'),
        '130',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Protein (g)'),
        '2.7',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Karbo (g)'),
        '28',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Lemak (g)'),
        '0.3',
      );

      final saveFood = find.descendant(
        of: find.byType(AlertDialog).last,
        matching: find.text('Simpan Makanan'),
      );
      await tester.ensureVisible(saveFood);
      await tester.tap(saveFood);
      await tester.pumpAndSettle();

      expect(await database.getAllFoods(), hasLength(1));

      // Back in the meal dialog the new food is selectable.
      expect(find.text('Nasi Putih'), findsWidgets);

      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();

      final saveMeal = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Simpan Makanan'),
      );
      await tester.ensureVisible(saveMeal);
      await tester.tap(saveMeal);
      await tester.pumpAndSettle();

      final today = DateTime.now();
      final day = DateTime(today.year, today.month, today.day);
      expect(await database.getMealsForDay(day), hasLength(1));
      expect(find.textContaining('Nasi Putih'), findsWidgets);
    });
  });

  group('Habit first-use flow', () {
    testWidgets('creating a habit shows it in the list immediately', (
      tester,
    ) async {
      final container = await _pumpApp(tester);
      final database = container.read(databaseProvider);
      addTearDown(database.close);

      container.read(appRouterProvider).go('/habits');
      await tester.pumpAndSettle();

      expect(find.text('Kebiasaan'), findsOneWidget);
      expect(find.text('Belum ada kebiasaan.'), findsOneWidget);

      await tester.tap(find.text('Tambah Kebiasaan'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama'),
        'Baca Buku',
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Baca Buku'), findsOneWidget);
      expect(find.text('harian · target 1'), findsOneWidget);
      expect(await database.getAllHabits(), hasLength(1));
    });
  });
}

Future<ProviderContainer> _pumpApp(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      inMemoryDatabaseOverride(),
      clockProvider.overrideWithValue(DateTime(2026, 9, 8, 8)),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const DailyLifeApp(),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}
