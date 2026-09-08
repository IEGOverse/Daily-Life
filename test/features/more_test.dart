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

      expect(find.text('Lainnya'), findsNWidgets(2)); // AppBar + bottom nav

      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Data & Sinkronisasi'), findsOneWidget);
      expect(find.text('Tema'), findsOneWidget);
      expect(find.text('Bantuan & Dukungan'), findsOneWidget);
      expect(find.text('Tentang Activus'), findsOneWidget);
    });

    testWidgets('Settings opens the reminders screen', (tester) async {
      final container = await _pumpApp(tester);

      container.read(appRouterProvider).go('/more');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pengaturan'));
      await tester.pumpAndSettle();

      expect(find.text('Pengingat'), findsOneWidget);
    });

    testWidgets('About Activus shows an informational dialog', (tester) async {
      final container = await _pumpApp(tester);

      container.read(appRouterProvider).go('/more');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tentang Activus'));
      await tester.pumpAndSettle();

      expect(find.text('Sistem Operasi Kehidupan Pribadi'), findsOneWidget);
      expect(
        find.text(
          'Semua data tersimpan di perangkat Anda. Tidak ada yang diunggah atau dibagikan.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
      expect(
        find.text('Tentang Activus'),
        findsOneWidget,
      ); // row only, dialog closed
    });

    testWidgets('bottom nav switches between tabs', (tester) async {
      await _pumpApp(tester);

      expect(find.text('Lainnya'), findsOneWidget); // bottom nav label only
      await tester.tap(find.text('Jadwal'));
      await tester.pumpAndSettle();
      expect(find.text('Jadwal'), findsNWidgets(2)); // header + nav label

      await tester.tap(find.text('Lainnya'));
      await tester.pumpAndSettle();
      expect(find.text('Profil'), findsOneWidget);
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
