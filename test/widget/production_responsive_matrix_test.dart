import 'package:cts_mining_axle_inspection/core/mining_axle_template.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_enums.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_models.dart';
import 'package:cts_mining_axle_inspection/features/inspection_form/inspection_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in <Size>[
    const Size(412, 915),
    const Size(1024, 600),
    const Size(1280, 800),
    const Size(1600, 1000),
  ]) {
    testWidgets('inspection editor has no layout errors at $size', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
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
      expect(find.text('Inspection Purpose'), findsWidgets);
      expect(find.text('Overall Axle Health Assessment'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}

InspectionRecord _blankInspection() {
  final now = DateTime.utc(2026, 7, 1, 12);
  return InspectionRecord(
    id: 'responsive-matrix',
    documentNumber: '20260701-0001',
    status: InspectionStatus.draft,
    inspectionDateTime: now,
    createdAt: now,
    updatedAt: now,
    sections: MiningAxleTemplate.sections
        .map(
          (section) => InspectionSectionProgress(
            id: 'matrix_${section.key}',
            inspectionId: 'responsive-matrix',
            sectionKey: section.key,
            title: section.title,
            sortOrder: section.sortOrder,
            completionState: SectionCompletionState.notStarted,
          ),
        )
        .toList(growable: false),
  );
}
