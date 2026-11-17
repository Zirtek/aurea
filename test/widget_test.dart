import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aurea/main.dart';

void main() {
  testWidgets('Aurea app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AureaApp());
    await tester.pumpAndSettle();

    expect(find.text('AUREA'), findsOneWidget);
  });
}