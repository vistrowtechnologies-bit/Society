import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:societyos_app/main.dart';

void main() {
  testWidgets('App boots to the splash screen then routes to login', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SocietyOSApp());
    expect(find.text('SocietyOS'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
  });
}
