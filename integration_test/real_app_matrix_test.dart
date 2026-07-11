import 'package:cts_mining_axle_inspection/app.dart';
import 'package:cts_mining_axle_inspection/core/mining_axle_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'real app settings and mining axle option matrix work on tablet',
    (tester) async {
      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const ProviderScope(child: CtsMiningAxleInspectionApp()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsNothing);
      expect(find.text('Workflow Scope'), findsOneWidget);
      expect(find.text('Responsive tablet layout'), findsOneWidget);
      expect(find.text('Local report-ready files'), findsOneWidget);
      expect(find.text('Saved locally during share handoff'), findsOneWidget);
      expect(find.text('CTS branded industrial theme'), findsOneWidget);
      expect(find.text('Template version'), findsOneWidget);
      expect(find.text(MiningAxleTemplate.templateVersion), findsWidgets);
      expect(
        find.text('Template key: mining_axle_inspection.'),
        findsOneWidget,
      );
      expect(find.text('Backup and Restore'), findsOneWidget);

      await tester.tap(find.text('New Inspection').last);
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(seconds: 2));
      });
      await tester.pump();

      for (final title in MiningAxleTemplate.sections.map(
        (section) => section.title,
      )) {
        await tester.ensureVisible(find.text(title).first);
        await tester.pumpAndSettle();
        expect(find.text(title), findsWidgets);
      }

      for (final purpose in MiningAxleTemplate.purposeItems) {
        await _tapFilterChip(tester, purpose.label);
      }
      for (final purpose in MiningAxleTemplate.purposeItems) {
        await _tapFilterChip(tester, purpose.label);
      }

      await _chooseEveryDropdownOption(
        tester,
        label: 'Axle Housing',
        options: MiningAxleTemplate.conditionOptions,
      );
      await _chooseEveryDropdownOption(
        tester,
        label: 'Oil Leaks',
        options: MiningAxleTemplate.defectOptions,
      );
      await _chooseEveryDropdownOption(
        tester,
        label: 'Backlash Measurement',
        options: MiningAxleTemplate.acceptableOptions,
      );
      await _chooseEveryDropdownOption(
        tester,
        label: 'Differential Lock',
        options: MiningAxleTemplate.operationalOptions,
      );
      await _chooseEveryDropdownOption(
        tester,
        label: 'Reliability Risk',
        options: MiningAxleTemplate.reliabilityRiskOptions,
      );
      await _chooseEveryDropdownOption(
        tester,
        label: 'Overall Condition',
        options: MiningAxleTemplate.overallConditionOptions,
      );
      await _chooseEveryDropdownOption(
        tester,
        label: 'Oil Leaks',
        options: const <String>['Yes'],
      );
      final criticalToggle = find.byKey(const Key('critical_toggle_oil_leaks'));
      await Scrollable.ensureVisible(
        tester.element(criticalToggle),
        alignment: 0.5,
        duration: Duration.zero,
      );
      await tester.pumpAndSettle();
      await tester.tap(criticalToggle);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(criticalToggle).selected, isTrue);
      expect(
        find.text('Critical / Out of Service acknowledgement'),
        findsOneWidget,
      );
      await _enterKeyedText(
        tester,
        const Key('comment_axle_housing'),
        'Tablet matrix axle housing note',
      );
      await _enterKeyedText(
        tester,
        const Key('oil_result_iso_cleanliness_code'),
        '18/16/13',
      );
      await _enterKeyedText(
        tester,
        const Key('oil_limits_iso_cleanliness_code'),
        'Within CTS target',
      );
      await _enterKeyedText(
        tester,
        const Key('measurement_specification_crown_wheel_backlash'),
        '0.30-0.45 mm',
      );
      await _enterKeyedText(
        tester,
        const Key('measurement_actual_crown_wheel_backlash'),
        '0.39 mm',
      );
      await _enterKeyedText(
        tester,
        const Key('measurement_comments_crown_wheel_backlash'),
        'Pattern acceptable',
      );

      await tester.ensureVisible(
        find.text('Performed Using Infrared Thermography'),
      );
      final thermographyTile = find.widgetWithText(
        SwitchListTile,
        'Performed Using Infrared Thermography',
      );
      expect(tester.widget<SwitchListTile>(thermographyTile).value, isFalse);
      await tester.tap(thermographyTile);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(thermographyTile).value, isTrue);
      await tester.tap(thermographyTile);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(thermographyTile).value, isFalse);
      await _enterKeyedText(
        tester,
        const Key('temperature_temperature_c_left_planetary_hub'),
        '72.5',
      );
      await _enterKeyedText(
        tester,
        const Key('temperature_comments_left_planetary_hub'),
        'Stable after haul cycle',
      );

      final addPhotoButton = find.widgetWithText(
        FilledButton,
        'Add first photo',
      );
      await tester.ensureVisible(addPhotoButton.first);
      await tester.pumpAndSettle();
      await tester.tap(addPhotoButton.first);
      await tester.pumpAndSettle();
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Sample photo'), findsNothing);
      Navigator.of(tester.element(find.text('Camera'))).pop();
      await tester.pumpAndSettle();

      for (final finding in MiningAxleTemplate.conditionMonitoringFindings) {
        await _tapFilterChip(tester, finding.label);
      }
      await tester.ensureVisible(
        find.text('Critical / Out of Service acknowledgement'),
      );
      await tester.tap(
        find.text('Critical / Out of Service acknowledgement').first,
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Save Draft').first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save Draft').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Draft'), findsWidgets);
      expect(find.textContaining('saved locally'), findsWidgets);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Generate PDF').last);
      await tester.tap(find.widgetWithText(FilledButton, 'Generate PDF').last);
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(seconds: 2));
      });
      await tester.pump();
      await _waitForTextContaining(tester, 'PDF generated:');
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      final exportButton = find.widgetWithText(OutlinedButton, 'Export Bundle');
      await tester.ensureVisible(exportButton);
      await tester.tap(exportButton);
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(seconds: 2));
      });
      await tester.pump();
      await _waitForTextContaining(tester, 'Inspection bundle exported to');
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      final completeButton = find.widgetWithText(
        OutlinedButton,
        'Complete inspection',
      );
      await tester.ensureVisible(completeButton);
      await tester.tap(completeButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Complete blocked by'), findsOneWidget);

      expect(errors, isEmpty);
    },
  );
}

Future<void> _enterKeyedText(WidgetTester tester, Key key, String value) async {
  final finder = find.byKey(key);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

Future<void> _waitForTextContaining(
  WidgetTester tester,
  String pattern, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final finder = find.textContaining(pattern);
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      expect(finder, findsWidgets);
      return;
    }
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
  }
  expect(finder, findsWidgets);
}

Future<void> _tapFilterChip(WidgetTester tester, String label) async {
  final chip = find.byWidgetPredicate((widget) {
    return widget is FilterChip &&
        widget.label is Text &&
        (widget.label as Text).data == label;
  });
  expect(chip, findsOneWidget);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

Future<void> _chooseEveryDropdownOption(
  WidgetTester tester, {
  required String label,
  required List<String> options,
}) async {
  final decoratedLabel = find.text('$label *');
  for (final option in options) {
    await tester.ensureVisible(decoratedLabel.first);
    await tester.pumpAndSettle();
    final dropdown = find
        .ancestor(
          of: decoratedLabel.first,
          matching: find.byType(DropdownButtonFormField<String>),
        )
        .first;
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
    expect(find.text(option), findsWidgets);
  }
}
