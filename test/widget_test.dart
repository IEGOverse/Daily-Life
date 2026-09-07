import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life/main.dart';

void main() {
  testWidgets('Daily Life app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DailyLifeApp()));

    expect(find.text('Daily Life'), findsOneWidget);
    expect(find.byType(DailyLifeApp), findsOneWidget);
  });
}
