import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import 'package:cts_mining_axle_inspection/app.dart';

void main() {
  testWidgets('dashboard shell renders the tablet layout', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(child: CtsMiningAxleInspectionApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('CTS Mining Axle Inspection'), findsWidgets);
    expect(find.text('Mining Axle Dashboard'), findsOneWidget);
    expect(find.text('Critical Reports'), findsOneWidget);
    expect(find.textContaining('Fluid Power'), findsNothing);
  });

  testWidgets('navigation rail opens the inspection list', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(child: CtsMiningAxleInspectionApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inspections').last);
    await tester.pumpAndSettle();

    expect(find.text('Inspection Search'), findsOneWidget);
    expect(find.text('Inspection Records'), findsOneWidget);
  });

  testWidgets(
    'new inspection editor exposes mining axle sections and settings',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const ProviderScope(child: CtsMiningAxleInspectionApp()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Inspection').first);
      await tester.pumpAndSettle();

      expect(find.text('Inspection Purpose'), findsWidgets);
      expect(find.text('Visual Inspection'), findsWidgets);
      expect(find.text('Lubrication Assessment'), findsWidgets);
      expect(find.text('Differential Inspection'), findsWidgets);
      expect(find.text('Planetary Hub Inspection'), findsWidgets);
      expect(find.text('Mechanical Measurements'), findsWidgets);
      expect(find.text('Temperature Assessment'), findsWidgets);
      expect(find.text('Condition Monitoring Findings'), findsWidgets);
      expect(find.text('Recommendations'), findsWidgets);
      expect(find.text('Overall Axle Health Assessment'), findsWidgets);
      expect(find.text('Axle Serial Number'), findsWidgets);
      expect(find.text('Reliability Risk'), findsWidgets);
      expect(find.textContaining('Fluid Power'), findsNothing);

      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();

      expect(find.text('Template version'), findsOneWidget);
      expect(find.text('1.0.0'), findsWidgets);
    },
  );
}
