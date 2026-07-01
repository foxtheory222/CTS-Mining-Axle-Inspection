import 'package:cts_mining_axle_inspection/core/mining_axle_template.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_enums.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_models.dart';
import 'package:cts_mining_axle_inspection/features/inspection_form/inspection_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'new inspection form starts from a blank record and exposes real draft save',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InspectionFormScreen(initialRecord: _blankInspection()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('New Mining Axle Inspection'), findsOneWidget);
      expect(_editableTextWithValue('Moraine Quarry'), findsNothing);
      expect(_editableTextWithValue('R. Ellis'), findsNothing);
      expect(_editableTextWithValue('AXLE-1001'), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Save Draft'), findsWidgets);
    },
  );
}

InspectionRecord _blankInspection() {
  final now = DateTime.utc(2026, 7, 1, 12);
  return InspectionRecord(
    id: 'blank-form',
    documentNumber: '20260701-0001',
    status: InspectionStatus.draft,
    inspectionDateTime: now,
    createdAt: now,
    updatedAt: now,
    sections: MiningAxleTemplate.sections
        .map(
          (section) => InspectionSectionProgress(
            id: 'blank-form_${section.key}',
            inspectionId: 'blank-form',
            sectionKey: section.key,
            title: section.title,
            sortOrder: section.sortOrder,
            completionState: SectionCompletionState.notStarted,
          ),
        )
        .toList(growable: false),
  );
}

Finder _editableTextWithValue(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is EditableText && widget.controller.text == value,
    description: 'EditableText with value "$value"',
  );
}
