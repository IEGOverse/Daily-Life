import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/core/database/database.dart' as db;
import 'package:daily_life/core/database/database_provider.dart';
import 'package:daily_life/features/activities/calendar_history_screen.dart';
import 'package:daily_life/features/dashboard/dashboard_providers.dart';

void main() {
  group('CalendarHistoryScreen widget', () {
    testWidgets('shows empty state for a day with no activities', (
      tester,
    ) async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            clockProvider.overrideWithValue(DateTime(2026, 9, 8, 12)),
          ],
          child: const MaterialApp(home: CalendarHistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Month header present.
      expect(find.text('September 2026'), findsOneWidget);
      // The calendar grid is present (number 8 cell representing today).
      expect(find.text('8'), findsWidgets);

      // The selected day's activity list is below the grid; scroll to it.
      await tester.scrollUntilVisible(
        find.text('No activities for this day.'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('No activities for this day.'), findsOneWidget);
    });

    testWidgets('shows day activities and marks completion via Done', (
      tester,
    ) async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      // Activity on 2026-09-08 with an actionable status.
      await database.insertActivity(
        db.Activity(
          id: 'a1',
          title: 'Data Mining',
          category: 'study',
          startTime: DateTime(2026, 9, 8, 13, 10),
          endTime: DateTime(2026, 9, 8, 14, 30),
          status: 'scheduled',
          scheduleId: null,
          notes: null,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            clockProvider.overrideWithValue(DateTime(2026, 9, 8, 12)),
          ],
          child: const MaterialApp(home: CalendarHistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // The activity sits below the month grid; drag the outer list up so the
      // day section is visible.
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text('Data Mining'), findsOneWidget);

      // Tap Done.
      await tester.tap(
        find.byIcon(Icons.check_circle_outline),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      final stored = await database.getActivityById('a1');
      expect(stored!.status, 'completed');
      // Now shows reset, not done.
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });
  });
}
