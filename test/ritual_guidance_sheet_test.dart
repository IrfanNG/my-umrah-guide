import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_umrah_guide/features/practice/presentation/guidance/ritual_guidance.dart';
import 'package:my_umrah_guide/features/practice/presentation/guidance/ritual_guidance_sheet.dart';

void main() {
  testWidgets('renders ritual guidance content and dismiss action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RitualGuidanceSheet(guidance: RitualGuidanceCatalog.tawafStart),
        ),
      ),
    );

    expect(find.text('Mula Tawaf'), findsOneWidget);
    expect(find.textContaining('Anda berada dalam zon Tawaf'), findsOneWidget);
    expect(find.textContaining('Bismillah'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });
}
