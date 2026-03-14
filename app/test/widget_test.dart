import 'package:flutter_test/flutter_test.dart';
import 'package:sportos_app/main.dart';

void main() {
  testWidgets('SportOS app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SportOsApp());
    // Verify the Hub tab is present
    expect(find.text('Хаб'), findsOneWidget);
  });
}
