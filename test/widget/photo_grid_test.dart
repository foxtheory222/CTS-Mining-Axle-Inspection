import 'package:cts_mining_axle_inspection/core/workspace_models.dart';
import 'package:cts_mining_axle_inspection/widgets/photo_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty photo grid add button invokes the production callback', (
    tester,
  ) async {
    var addCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhotoGrid(photos: const [], onAddPhoto: () => addCount++),
        ),
      ),
    );

    await tester.tap(find.text('Add first photo'));
    await tester.pump();

    expect(addCount, 1);
  });

  testWidgets('photo add tile invokes the production callback', (tester) async {
    var addCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhotoGrid(
            photos: [
              InspectionPhotoView(
                assetPath: 'missing.jpg',
                isAsset: false,
                caption: 'Existing evidence',
                sectionTitle: 'Visual Inspection',
                itemLabel: 'Axle Housing',
                capturedAt: DateTime.utc(2026, 7, 1),
              ),
            ],
            onAddPhoto: () => addCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add photo'));
    await tester.pump();

    expect(addCount, 1);
  });
}
