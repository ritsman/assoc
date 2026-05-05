import 'package:flutter_test/flutter_test.dart';

import 'package:synetra/main.dart';

void main() {
  testWidgets('dummy login opens dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const SynetraApp());
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Demo Credentials'), findsOneWidget);

    await tester.ensureVisible(find.text('Login to dashboard'));
    await tester.tap(find.text('Login to dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Hello, Admin'), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Overview'), findsWidgets);
  });
}
