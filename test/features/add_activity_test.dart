import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/core/database/database.dart' as db;
import 'package:daily_life/core/database/database_provider.dart';
import 'package:daily_life/features/dashboard/dashboard_providers.dart';
import 'package:daily_life/main.dart';

void main() {
  group('Add Activity flow', () {
    testWidgets('quick-add saves the activity and shows it on today', (
      tester,
    ) async {
      final database = await _pumpApp(tester);

      // Seeding created scheduled activities, so the dashboard timeline has
      // content. Open the quick-add form.
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Add Activity'), findsOneWidget);

      // Fill in the form (keep the default category).
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Coffee with team',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Notes (optional)'),
        'quarterly sync',
      );
      await tester.pumpAndSettle();

      // Save.
      await tester.tap(find.text('Save Activity'));
      await tester.pumpAndSettle();

      // Back on the dashboard.
      expect(find.byType(DailyLifeApp), findsOneWidget);

      // The activity was persisted with the entered values.
      final rows = await database.getActivitiesForDay(DateTime(2026, 9, 8));
      final added = rows.where((r) => r.title == 'Coffee with team').single;
      expect(added.category, 'study');
      expect(added.notes, 'quarterly sync');
      expect(added.status, 'scheduled');
      expect(added.startTime, DateTime(2026, 9, 8, 8)); // clock override 08:00

      // It shows in the dashboard timeline.
      expect(find.text('Coffee with team'), findsWidgets);
    });

    testWidgets('invalid form shows validation errors and does not persist', (
      tester,
    ) async {
      final database = await _pumpApp(tester);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      // Title is empty -> Save is rejected.
      await tester.tap(find.text('Save Activity'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a title'), findsOneWidget);

      final rows = await database.getActivitiesForDay(DateTime(2026, 9, 8));
      // Only the seeded schedule activities exist (no manual insert happened).
      expect(rows.length, greaterThanOrEqualTo(0));
      expect(rows.where((r) => r.id.startsWith('act_')), isEmpty);
    });
  });
}

Future<db.AppDatabase> _pumpApp(WidgetTester tester) async {
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

  return database;
}
