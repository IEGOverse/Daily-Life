import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/core/database/database_provider.dart';
import 'package:daily_life/main.dart';

void main() {
  testWidgets('Activus app launches', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [inMemoryDatabaseOverride()],
        child: const DailyLifeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DailyLifeApp), findsOneWidget);
  });
}
