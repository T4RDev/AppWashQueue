import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const WashQApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(WashQApp), findsOneWidget);
  });
}
