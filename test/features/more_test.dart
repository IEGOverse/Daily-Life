import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/core/database/database_provider.dart';
import 'package:daily_life/core/router/app_router.dart';
import 'package:daily_life/features/dashboard/dashboard_providers.dart';
import 'package:daily_life/main.dart';

void main() {
  group('More screen flow', () {
    testWidgets('shows all sections and rows', (tester) async {
      final container = await _pumpApp(tester);

      container.read(appRouterProvider).go('/more');
      await tester.pumpAndSettle();

      expect(find.text('More'), findsNWidgets(2)); // AppBar + bottom nav

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Data & Sync'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('About Activus'), findsOneWidget);
    });

    testWidgets('Settings opens the reminders screen', (tester) async {
      final container = await _pumpApp(tester);

      container.read(appRouterProvider).go('/more');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Reminders'), findsOneWidget);
    });

    testWidgets('About Activus shows an informational dialog', (tester) async {
      final container = await _pumpApp(tester);

      container.read(appRouterProvider).go('/more');
      await tester.pumpAndSettle();

      await tester.tap(find.text('About Activus'));
      await tester.pumpAndSettle();

      expect(find.text('Personal Life Operating System'), findsOneWidget);
      expect(
        find.text(
          'All data stays on your device. Nothing is uploaded or shared.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(
        find.text('About Activus'),
        findsOneWidget,
      ); // row only, dialog closed
    });

    testWidgets('bottom nav switches between tabs', (tester) async {
      await _pumpApp(tester);

      expect(find.text('More'), findsOneWidget); // bottom nav label only
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      expect(find.text('Schedule'), findsNWidgets(2)); // header + nav label

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);
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
  final database = container.read(databaseProvider);
  addTearDown(database.close);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const DailyLifeApp(),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}
