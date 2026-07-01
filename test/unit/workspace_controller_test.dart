import 'dart:io';

import 'package:cts_mining_axle_inspection/core/mining_axle_template.dart';
import 'package:cts_mining_axle_inspection/core/workspace_controller.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_enums.dart';
import 'package:cts_mining_axle_inspection/data/repositories/inspection_repository.dart';
import 'package:cts_mining_axle_inspection/services/document_number_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/persistence_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  test(
    'document numbers increment and search filters durable records',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'workspace_controller_test_',
      );
      final database = TestAppDatabase(tempDir);
      addTearDown(() async {
        await database.close();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final repository = InspectionRepository(
        database: database,
        documentNumberService: DocumentNumberService(),
      );
      final controller = AppWorkspaceController(repository: repository);
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.inspections, isEmpty);

      final created = await controller.createInspection(
        createdAt: DateTime.utc(2026, 7, 1, 8),
      );
      expect(created.documentNumber, '20260701-0001');

      final record = await controller.inspectionRecordById(created.id);
      expect(record, isNotNull);
      record!
        ..customer = 'North Basin Processing'
        ..equipmentMake = 'Komatsu'
        ..equipmentModel = '830E'
        ..axleSerialNumber = 'AXLE-2002'
        ..status = InspectionStatus.inProgress;
      await controller.saveInspectionRecord(record);

      final duplicate = await controller.duplicateInspection(
        controller.inspections.first,
      );
      expect(duplicate.documentNumber, isNot(equals(created.documentNumber)));
      expect(duplicate.sections.length, MiningAxleTemplate.sections.length);

      controller.setSearchQuery('North Basin');
      expect(controller.filteredInspections.length, 2);
      expect(
        controller.filteredInspections.map((item) => item.customer),
        everyElement('North Basin Processing'),
      );
    },
  );
}
