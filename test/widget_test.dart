import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cts_mining_axle_inspection/app.dart';
import 'package:cts_mining_axle_inspection/core/workspace_providers.dart';

import 'support/persistence_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  testWidgets('dashboard shell renders the tablet layout', (
    WidgetTester tester,
  ) async {
    final scope = await _testAppScope();
    addTearDown(() => _disposeScope(tester, scope));
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(scope.wrap(const CtsMiningAxleInspectionApp()));
    await tester.pumpAndSettle();

    expect(find.text('CTS Mining Axle Inspection'), findsWidgets);
    expect(find.text('Mining Axle Dashboard'), findsOneWidget);
    expect(find.text('Critical Reports'), findsOneWidget);
    expect(find.textContaining('Fluid Power'), findsNothing);
  });

  testWidgets('navigation rail opens the inspection list', (
    WidgetTester tester,
  ) async {
    final scope = await _testAppScope();
    addTearDown(() => _disposeScope(tester, scope));
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(scope.wrap(const CtsMiningAxleInspectionApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inspections').last);
    await tester.pumpAndSettle();

    expect(find.text('Inspection Search'), findsOneWidget);
    expect(find.text('Inspection Records'), findsOneWidget);
  });

  testWidgets('settings exposes template and backup controls', (
    WidgetTester tester,
  ) async {
    final scope = await _testAppScope();
    addTearDown(() => _disposeScope(tester, scope));
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(scope.wrap(const CtsMiningAxleInspectionApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Template version'), findsOneWidget);
    expect(find.text('1.0.0'), findsWidgets);
    expect(find.text('Backup and Restore'), findsOneWidget);
    expect(find.textContaining('Fluid Power'), findsNothing);
  });
}

Future<_TestAppScope> _testAppScope() async {
  final tempDir = Directory.systemTemp.createTempSync('app_widget_test_');
  final database = TestAppDatabase(tempDir);
  return _TestAppScope(tempDir, database);
}

Future<void> _disposeScope(WidgetTester tester, _TestAppScope scope) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await scope.dispose();
}

class _TestAppScope {
  _TestAppScope(this.tempDir, this.database);

  final Directory tempDir;
  final TestAppDatabase database;

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: child,
    );
  }

  Future<void> dispose() async {
    await database.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}
