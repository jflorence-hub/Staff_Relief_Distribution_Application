// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:staff_relief_distribution_application/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StaffApp());
    expect(find.text('Sign in'), findsWidgets);
  });
}
