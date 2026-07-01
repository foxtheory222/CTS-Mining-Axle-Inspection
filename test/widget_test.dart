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
    expect(find.text('Inspection Suite'), findsOneWidget);
    expect(find.text('Critical Reports'), findsOneWidget);
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
}
