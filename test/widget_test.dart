import 'package:flutter_test/flutter_test.dart';

import 'package:my_umrah_guide/main.dart';

void main() {
  testWidgets('shows the MyUmrahGuide splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyUmrahGuide());

    expect(find.text('MyUmrahGuide'), findsOneWidget);
    expect(find.text('Your Digital Umrah Companion'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });
}
