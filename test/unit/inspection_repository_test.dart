import 'dart:io';

import 'package:cts_mining_axle_inspection/core/constants.dart';
import 'package:cts_mining_axle_inspection/core/mining_axle_template.dart';
import 'package:cts_mining_axle_inspection/core/validators.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_enums.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_models.dart';
import 'package:cts_mining_axle_inspection/data/repositories/inspection_repository.dart';
import 'package:cts_mining_axle_inspection/services/document_number_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../support/persistence_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late TestAppDatabase database;
  late InspectionRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('inspection_repo_test_');
    database = TestAppDatabase(tempDir);
    repository = InspectionRepository(
      database: database,
      documentNumberService: DocumentNumberService(),
      uuid: const Uuid(),
    );
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('createInspection seeds mining axle metadata and sections', () async {
    final inspection = await repository.createInspection(
      createdAt: DateTime.utc(2026, 7, 1, 9, 30),
    );

    expect(inspection.templateKey, AppConstants.templateKey);
    expect(inspection.templateVersion, AppConstants.templateVersion);
    expect(inspection.appName, AppConstants.appName);
    expect(inspection.documentNumber, '20260701-0001');
    expect(
      inspection.sections.map((section) => section.title),
      MiningAxleTemplate.sections.map((section) => section.title),
    );
  });

  test('inspection json round-trips mining axle rows and signatures', () {
    final inspection = buildInspection(
      id: 'round-trip',
      documentNumber: '20260701-0002',
      status: InspectionStatus.inProgress,
      equipmentMake: 'Komatsu',
      equipmentModel: 'WA900',
      machineSerialNumber: 'KM-900-7788',
      axleManufacturer: 'Kessler',
      axleModel: 'D106',
      axleSerialNumber: 'AX-55-1234',
      hoursOnMachine: '18450',
      purchaseOrderNumber: 'PO-7788',
      relatedMachineReportDocumentNumber: '20260701-0001',
      customerRepresentativeName: 'Morgan Customer',
      customerSignatureFilePath: '/tmp/customer-signature.png',
      customerUnavailableNote: 'Representative declined signature.',
      restoredFromExportPath: '/tmp/imports/source.zip',
    );
    inspection.oilAnalysisRows.add(
      OilAnalysisRow(
        parameter: 'Iron (Fe)',
        result: '125 ppm',
        limits: 'Trending high',
      ),
    );
    inspection.mechanicalMeasurementRows.add(
      MechanicalMeasurementRow(
        measurement: 'Crown Wheel Backlash',
        specification: '0.30-0.45 mm',
        actual: '0.52 mm',
        comments: 'Out of specification.',
        performedStatus: 'Performed',
      ),
    );
    inspection.temperatureRows.add(
      TemperatureRow(
        location: 'Left Planetary Hub',
        temperatureC: 82.5,
        comments: 'Elevated after haul cycle.',
        abnormalFlagged: true,
      ),
    );
    inspection.recommendationRows.add(
      RecommendationRow(
        priority: 'Priority 2 Schedule Repair',
        recommendation: 'Schedule backlash adjustment.',
      ),
    );

    final restored = InspectionRecord.fromJson(inspection.toJson());

    expect(restored.equipmentMake, 'Komatsu');
    expect(restored.machineSerialNumber, 'KM-900-7788');
    expect(restored.axleSerialNumber, 'AX-55-1234');
    expect(restored.oilAnalysisRows.single.result, '125 ppm');
    expect(restored.mechanicalMeasurementRows.single.actual, '0.52 mm');
    expect(restored.temperatureRows.single.temperatureC, 82.5);
    expect(
      restored.recommendationRows.single.recommendation,
      'Schedule backlash adjustment.',
    );
    expect(restored.customerSignatureFilePath, '/tmp/customer-signature.png');
    expect(restored.restoredFromExportPath, '/tmp/imports/source.zip');
  });

  test(
    'duplicateInspection copies only header fields and assigns new document number',
    () async {
      final source = buildInspection(
        id: 'source',
        documentNumber: '20260420-0001',
        status: InspectionStatus.complete,
        completedAt: DateTime.utc(2026, 4, 20, 12, 30),
        signatureFilePath: '/tmp/signature.png',
        equipmentMake: 'Caterpillar',
        equipmentModel: '793F',
        machineSerialNumber: 'CAT793-4455',
        axleManufacturer: 'Dana',
        axleModel: 'Spicer 53R300',
        axleSerialNumber: 'AXLE-9001',
        hoursOnMachine: '22750',
        purchaseOrderNumber: 'PO-9001',
        relatedMachineReportDocumentNumber: '20260419-0001',
        customerSignatureFilePath: '/tmp/customer-signature.png',
      );
      fillRequiredResponses(source);
      source.photos.add(
        InspectionPhoto(
          id: 'photo-1',
          inspectionId: source.id,
          sectionKey: InspectionSectionKeys.fluidTankService,
          itemKey: InspectionItemKeys.tankIntegrity,
          filePath: '/tmp/photo.jpg',
          caption: 'Damage',
          sortOrder: 0,
          capturedAt: DateTime.utc(2026, 4, 20, 12, 0),
          createdAt: DateTime.utc(2026, 4, 20, 12, 0),
        ),
      );

      final duplicate = await repository.duplicateInspection(
        source,
        createdAt: DateTime.utc(2026, 4, 21, 8, 0),
      );

      expect(duplicate.documentNumber, isNot(source.documentNumber));
      expect(duplicate.customer, source.customer);
      expect(duplicate.workOrderNumber, source.workOrderNumber);
      expect(duplicate.equipmentMake, source.equipmentMake);
      expect(duplicate.equipmentModel, source.equipmentModel);
      expect(duplicate.machineSerialNumber, source.machineSerialNumber);
      expect(duplicate.axleManufacturer, source.axleManufacturer);
      expect(duplicate.axleModel, source.axleModel);
      expect(duplicate.axleSerialNumber, source.axleSerialNumber);
      expect(duplicate.hoursOnMachine, source.hoursOnMachine);
      expect(duplicate.purchaseOrderNumber, source.purchaseOrderNumber);
      expect(
        duplicate.relatedMachineReportDocumentNumber,
        source.relatedMachineReportDocumentNumber,
      );
      expect(duplicate.responses, isEmpty);
      expect(duplicate.photos, isEmpty);
      expect(duplicate.actionItems, isEmpty);
      expect(duplicate.signatureFilePath, isNull);
      expect(duplicate.customerSignatureFilePath, isNull);
      expect(duplicate.completedAt, isNull);
      expect(duplicate.emailedAt, isNull);
      expect(duplicate.status, InspectionStatus.inProgress);
    },
  );

  test('saving an emailed inspection clears emailed state on edit', () async {
    final inspection = buildInspection(
      id: 'save-edit',
      documentNumber: '20260420-0002',
      status: InspectionStatus.inProgress,
    );
    fillRequiredResponses(inspection);
    inspection.signatureFilePath = '/tmp/signature.png';
    inspection.completedAt = DateTime.utc(2026, 4, 20, 12, 30);

    final completed = await repository.saveInspection(inspection);
    expect(completed.status, InspectionStatus.complete);

    final emailed = await repository.markEmailed(completed);
    expect(emailed.status, InspectionStatus.emailed);
    expect(emailed.emailedAt, isNotNull);

    emailed.customer = 'Updated Customer';
    final edited = await repository.saveInspection(emailed);

    expect(edited.emailedAt, isNull);
    expect(edited.status, InspectionStatus.complete);
    expect(edited.customer, 'Updated Customer');
  });

  test(
    'saving a valid signed draft does not complete it without confirmation',
    () async {
      final inspection = buildInspection(
        id: 'valid-draft',
        documentNumber: '20260420-0005',
        status: InspectionStatus.inProgress,
      );
      fillRequiredResponses(inspection);
      inspection.signatureFilePath = '/tmp/signature.png';

      final saved = await repository.saveInspection(inspection);

      expect(saved.status, InspectionStatus.inProgress);
      expect(saved.completedAt, isNull);
    },
  );

  test('an incomplete inspection cannot be marked as emailed', () async {
    final inspection = await repository.createInspection(
      createdAt: DateTime.utc(2026, 4, 20, 14),
    );

    await expectLater(
      repository.markEmailed(inspection),
      throwsA(isA<StateError>()),
    );

    final persisted = await repository.getInspection(inspection.id);
    expect(persisted?.emailedAt, isNull);
    expect(persisted?.status, InspectionStatus.draft);
  });

  test('a saved inspection document number cannot be changed', () async {
    final inspection = await repository.createInspection(
      createdAt: DateTime.utc(2026, 4, 20, 15),
    );
    final originalDocumentNumber = inspection.documentNumber;
    inspection.documentNumber = '20260420-9999';

    await expectLater(
      repository.saveInspection(inspection),
      throwsA(isA<StateError>()),
    );

    final persisted = await repository.getInspection(inspection.id);
    expect(persisted?.documentNumber, originalDocumentNumber);
  });

  test('invalid imported emailed state is downgraded safely', () async {
    final inspection = buildInspection(
      id: 'invalid-imported-email',
      documentNumber: '20260420-0006',
      status: InspectionStatus.emailed,
      completedAt: DateTime.utc(2026, 4, 20, 15),
      emailedAt: DateTime.utc(2026, 4, 20, 16),
    );

    final saved = await repository.saveInspection(inspection);

    expect(saved.emailedAt, isNull);
    expect(saved.completedAt, isNull);
    expect(saved.status, InspectionStatus.inProgress);
  });

  test(
    'search finds inspections by work order, customer, asset, document, and technician',
    () async {
      final inspection = buildInspection(
        id: 'searchable',
        documentNumber: '20260420-0003',
        status: InspectionStatus.inProgress,
        customer: 'Contoso Hydraulics',
        workOrderNumber: 'WO-4242',
        customerReference: 'PO-4242',
        assetName: 'Axle inspection record',
        equipmentModel: 'Boom Lift',
        machineSerialNumber: 'MACH-4242',
        axleSerialNumber: 'AXLE-4242',
        technicianName: 'Taylor Smith',
      );
      fillRequiredResponses(inspection);
      inspection.signatureFilePath = '/tmp/signature.png';
      inspection.completedAt = DateTime.utc(2026, 4, 20, 12, 30);
      await repository.saveInspection(inspection);

      expect(
        await repository.search(const InspectionSearchQuery(term: 'WO-4242')),
        hasLength(1),
      );
      expect(
        await repository.search(
          const InspectionSearchQuery(term: 'Contoso Hydraulics'),
        ),
        hasLength(1),
      );
      expect(
        await repository.search(const InspectionSearchQuery(term: 'Boom Lift')),
        hasLength(1),
      );
      expect(
        await repository.search(const InspectionSearchQuery(term: 'MACH-4242')),
        hasLength(1),
      );
      expect(
        await repository.search(const InspectionSearchQuery(term: 'AXLE-4242')),
        hasLength(1),
      );
      expect(
        await repository.search(
          const InspectionSearchQuery(term: '20260420-0003'),
        ),
        hasLength(1),
      );
      expect(
        await repository.search(
          const InspectionSearchQuery(term: 'Taylor Smith'),
        ),
        hasLength(1),
      );
    },
  );

  test('validation helper detects a complete inspection', () {
    final inspection = buildInspection(
      id: 'validate',
      documentNumber: '20260420-0004',
      status: InspectionStatus.inProgress,
    );
    fillRequiredResponses(inspection);
    inspection.signatureFilePath = '/tmp/signature.png';
    inspection.completedAt = DateTime.utc(2026, 4, 20, 12, 30);

    final validation = InspectionValidator.validateForCompletion(inspection);
    expect(validation.isValid, isTrue);
  });
}
