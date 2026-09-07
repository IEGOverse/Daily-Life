import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_life/main.dart';

void main() {
  testWidgets('Dashboard screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DailyLifeApp()));
    await tester.pump();

    expect(find.text('Today'), findsOneWidget);
  });
}
