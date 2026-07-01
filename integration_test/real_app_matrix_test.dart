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

      for (final title in <String>[
        'Lock landscape mode',
        'Compress images for report output',
        'Save recent email recipients',
        'Use branded industrial theme',
      ]) {
        final tile = find.widgetWithText(SwitchListTile, title);
        expect(tile, findsOneWidget);
        expect(tester.widget<SwitchListTile>(tile).value, isTrue);
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(tester.widget<SwitchListTile>(tile).value, isFalse);
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(tester.widget<SwitchListTile>(tile).value, isTrue);
      }

      expect(find.text('Template version'), findsOneWidget);
      expect(find.text(MiningAxleTemplate.templateVersion), findsWidgets);
      expect(
        find.text('Template key: mining_axle_inspection.'),
        findsOneWidget,
      );

      await tester.tap(find.text('New Inspection').last);
      await tester.pumpAndSettle();

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

      await tester.ensureVisible(
        find.text('Performed Using Infrared Thermography'),
      );
      final thermographyTile = find.widgetWithText(
        SwitchListTile,
        'Performed Using Infrared Thermography',
      );
      expect(tester.widget<SwitchListTile>(thermographyTile).value, isTrue);
      await tester.tap(thermographyTile);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(thermographyTile).value, isFalse);
      await tester.tap(thermographyTile);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(thermographyTile).value, isTrue);

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

      await tester.ensureVisible(find.text('Generate PDF').last);
      await tester.tap(find.widgetWithText(FilledButton, 'Generate PDF').last);
      await tester.pumpAndSettle();
      expect(
        find.text('PDF regenerated locally for this report.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      final exportButton = find.widgetWithText(OutlinedButton, 'Export Bundle');
      await tester.ensureVisible(exportButton);
      await tester.tap(exportButton);
      await tester.pumpAndSettle();
      expect(find.text('Inspection bundle exported locally.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      final completeButton = find.widgetWithText(
        OutlinedButton,
        'Complete inspection',
      );
      await tester.ensureVisible(completeButton);
      await tester.tap(completeButton);
      await tester.pumpAndSettle();
      expect(find.text('Complete inspection'), findsWidgets);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(errors, isEmpty);
    },
  );
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
  for (final option in options) {
    await tester.ensureVisible(find.text(label).first);
    await tester.pumpAndSettle();
    final dropdown = find
        .ancestor(
          of: find.text(label).first,
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
