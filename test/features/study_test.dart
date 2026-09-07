import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/core/database/database.dart' as db;
import 'package:daily_life/core/database/database_provider.dart';
import 'package:daily_life/core/router/app_router.dart';
import 'package:daily_life/features/study/data/study_session_repository.dart';
import 'package:daily_life/features/study/domain/study_session.dart';
import 'package:daily_life/main.dart';

void main() {
  group('StudySessionRepository', () {
    test('inserts and reads a complete study session', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = StudySessionRepository(database);
      final session = StudySession(
        id: 'study_test',
        subject: 'Algorithms',
        date: DateTime(2026, 9, 8),
        startTime: DateTime(2026, 9, 8, 8),
        endTime: DateTime(2026, 9, 8, 9, 30),
        durationSeconds: 5400,
        understanding: 4,
        notes: 'Graphs and trees',
      );
      await repository.insert(session);

      final found = await repository.byId(session.id);
      expect(found?.subject, 'Algorithms');
      expect(found?.durationSeconds, 5400);
      expect(found?.understanding, 4);
      expect(found?.notes, 'Graphs and trees');
      expect(await repository.getAll(), hasLength(1));
    });
  });

  group('Study session flow', () {
    testWidgets('adds a session and opens its detail', (tester) async {
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
      container.read(appRouterProvider).go('/study');
      await tester.pumpAndSettle();
      expect(find.text('No study sessions yet.'), findsOneWidget);

      await tester.tap(find.text('Study session'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Algorithms');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Notes (optional)'),
        'Graphs and trees',
      );
      await tester.tap(find.text('Understanding (optional)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4 / 5'));
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save session'));
      await tester.pumpAndSettle();

      expect(find.text('Algorithms'), findsOneWidget);
      expect(await database.getAllStudySessions(), hasLength(1));
      await tester.tap(find.text('Algorithms'));
      await tester.pumpAndSettle();
      expect(find.text('Graphs and trees'), findsOneWidget);
      expect(find.text('Understanding: 4 / 5'), findsOneWidget);
    });

    testWidgets('empty subject is rejected', (tester) async {
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
      container.read(appRouterProvider).go('/study/add');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save session'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a subject.'), findsOneWidget);
      expect(await database.getAllStudySessions(), isEmpty);
    });
  });
}
