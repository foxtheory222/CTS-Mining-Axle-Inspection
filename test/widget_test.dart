import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cts_mining_axle_inspection/app.dart';
import 'package:cts_mining_axle_inspection/core/workspace_providers.dart';
import 'package:cts_mining_axle_inspection/features/inspection_form/inspection_form_screen.dart';

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
    final activeLabel = tester.widget<Text>(find.text('Active'));
    final railScheme = Theme.of(
      tester.element(find.text('Active')),
    ).colorScheme;
    expect(activeLabel.style?.color, railScheme.onSurfaceVariant);
  });

  testWidgets('dashboard shell adapts to a 412x915 portrait viewport', (
    WidgetTester tester,
  ) async {
    final scope = await _testAppScope();
    addTearDown(() => _disposeScope(tester, scope));
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(scope.wrap(const CtsMiningAxleInspectionApp()));
    await tester.pumpAndSettle();

    expect(find.text('Mining Axle Dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Workflow Scope'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

  testWidgets(
    'dashboard creates a draft and reselecting New preserves unsaved work',
    (WidgetTester tester) async {
      final scope = await _testAppScope();
      addTearDown(() => _disposeScope(tester, scope));
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(scope.wrap(const CtsMiningAxleInspectionApp()));
      await tester.pumpAndSettle();
      await _pumpUntil(
        tester,
        () =>
            find.byKey(const Key('storage_loading_banner')).evaluate().isEmpty,
      );

      expect(find.byKey(const Key('storage_error_banner')), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'New Inspection'));
      await tester.pump();
      await _pumpUntil(
        tester,
        () => find.text('New Mining Axle Inspection').evaluate().isNotEmpty,
      );

      expect(find.text('New Mining Axle Inspection'), findsOneWidget);
      expect(find.byKey(const Key('inspection_load_failure')), findsNothing);
      final database = await tester.runAsync(scope.database.open);
      final firstFormState = tester.state(find.byType(InspectionFormScreen));
      expect(
        await tester.runAsync(
          () => database!.rawQuery('SELECT id FROM inspections'),
        ),
        hasLength(1),
      );
      await tester.enterText(find.byType(TextField).first, 'Unsaved Mine');

      tester
          .widget<NavigationRail>(find.byType(NavigationRail))
          .onDestinationSelected!(2);
      await tester.pump();

      expect(find.text('New Mining Axle Inspection'), findsOneWidget);
      expect(find.byKey(const Key('inspection_load_failure')), findsNothing);
      expect(tester.state(find.byType(InspectionFormScreen)), firstFormState);
      expect(find.text('Unsaved Mine'), findsOneWidget);
      final rows = (await tester.runAsync(
        () => database!.rawQuery(
          'SELECT id, document_number FROM inspections '
          'ORDER BY document_number',
        ),
      ))!;
      expect(rows, hasLength(1));
    },
  );

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

  testWidgets('settings does not expose inert workflow preference switches', (
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

    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text('Workflow Preferences'), findsNothing);
    expect(find.text('Workflow Scope'), findsOneWidget);
  });
}

Future<_TestAppScope> _testAppScope() async {
  final tempDir = Directory.systemTemp.createTempSync('app_widget_test_');
  final database = TestAppDatabase(tempDir);
  return _TestAppScope(tempDir, database);
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 50; attempt += 1) {
    if (condition()) {
      return;
    }
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Condition was not met within 5 seconds.');
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
