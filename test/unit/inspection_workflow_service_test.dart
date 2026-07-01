import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_enums.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_models.dart';
import 'package:cts_mining_axle_inspection/data/repositories/inspection_repository.dart';
import 'package:cts_mining_axle_inspection/services/backup_service.dart';
import 'package:cts_mining_axle_inspection/services/document_number_service.dart';
import 'package:cts_mining_axle_inspection/services/email_service.dart';
import 'package:cts_mining_axle_inspection/services/inspection_workflow_service.dart';
import 'package:cts_mining_axle_inspection/services/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../support/persistence_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late TestAppDatabase database;
  late InspectionRepository repository;
  late BackupService backupService;
  late FakeEmailShareAdapter shareAdapter;
  late EmailService emailService;
  late InspectionWorkflowService workflow;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'inspection_workflow_test_',
    );
    database = TestAppDatabase(tempDir);
    repository = InspectionRepository(
      database: database,
      documentNumberService: DocumentNumberService(),
      uuid: const Uuid(),
    );
    backupService = BackupService(
      documentsDirectoryProvider: () async => tempDir,
    );
    shareAdapter = FakeEmailShareAdapter();
    emailService = EmailService(
      shareAdapter: shareAdapter,
      recipientStore: JsonFileRecipientStore(
        documentsDirectoryProvider: () async => tempDir,
      ),
    );
    workflow = InspectionWorkflowService(
      repository: repository,
      pdfService: PdfService(compress: false),
      backupService: backupService,
      emailService: emailService,
      reportDirectoryProvider: (inspection) async {
        final directory = Directory(p.join(tempDir.path, 'reports'));
        await directory.create(recursive: true);
        return directory;
      },
    );
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('persisted inspection can generate a PDF and store the path', () async {
    final inspection = await _savedCompleteInspection(repository, tempDir);

    final result = await workflow.generatePdf(inspection);

    expect(await result.pdfFile.exists(), isTrue);
    expect(await result.pdfFile.length(), greaterThan(1000));
    expect(result.inspection.generatedPdfPath, result.pdfFile.path);

    final persisted = await repository.getInspection(inspection.id);
    expect(persisted?.generatedPdfPath, result.pdfFile.path);
  });

  test(
    'email handoff shares the generated PDF and marks emailed on success',
    () async {
      final inspection = await _savedCompleteInspection(repository, tempDir);

      final result = await workflow.shareInspectionPdf(
        inspection,
        recipients: const <String>['customer@example.com'],
      );

      expect(result.handoffResult.attachmentPath, result.pdfFile.path);
      expect(shareAdapter.lastSharedPdf?.path, result.pdfFile.path);
      expect(await File(result.handoffResult.attachmentPath).exists(), isTrue);

      final persisted = await repository.getInspection(inspection.id);
      expect(persisted?.status, InspectionStatus.emailed);
      expect(persisted?.emailedAt, isNotNull);
    },
  );

  test('email handoff does not mark emailed when share fails', () async {
    final failingEmailService = EmailService(
      shareAdapter: FakeEmailShareAdapter(shouldThrow: true),
      recipientStore: JsonFileRecipientStore(
        documentsDirectoryProvider: () async => tempDir,
      ),
    );
    final failingWorkflow = InspectionWorkflowService(
      repository: repository,
      pdfService: PdfService(compress: false),
      backupService: backupService,
      emailService: failingEmailService,
      reportDirectoryProvider: workflow.reportDirectoryProvider,
    );
    final inspection = await _savedCompleteInspection(repository, tempDir);

    await expectLater(
      failingWorkflow.shareInspectionPdf(inspection),
      throwsA(isA<EmailServiceException>()),
    );

    final persisted = await repository.getInspection(inspection.id);
    expect(persisted?.status, InspectionStatus.complete);
    expect(persisted?.emailedAt, isNull);
  });

  test(
    'export and import includes inspection JSON, photos, and generated PDF',
    () async {
      final inspection = await _savedCompleteInspection(
        repository,
        tempDir,
        includePhoto: true,
      );

      final exportResult = await workflow.exportInspection(inspection);

      expect(await exportResult.exportResult.archiveFile.exists(), isTrue);
      final archive = ZipDecoder().decodeBytes(
        await exportResult.exportResult.archiveFile.readAsBytes(),
        verify: true,
      );
      expect(
        archive.files.map((file) => file.name),
        contains('inspection.json'),
      );
      expect(
        archive.files.map((file) => file.name),
        contains(startsWith('photos/')),
      );
      expect(
        archive.files.map((file) => file.name),
        contains(startsWith('generated_pdf/')),
      );

      final importResult = await backupService.importInspection(
        archiveFile: exportResult.exportResult.archiveFile,
      );
      expect(importResult.restoredPhotoFiles, isNotEmpty);
      expect(await importResult.restoredPhotoFiles.single.exists(), isTrue);
      expect(importResult.restoredPdfFile, isNotNull);
      expect(await importResult.restoredPdfFile!.exists(), isTrue);
      expect(
        importResult.inspectionJson['generatedPdfPath'],
        importResult.restoredPdfFile!.path,
      );
    },
  );

  test('completion workflow persists valid signoff state', () async {
    final inspection = _completeInspection(tempDir);

    final result = await workflow.completeInspection(inspection);

    expect(result.inspection.status, InspectionStatus.complete);
    expect(result.inspection.completedAt, isNotNull);
    expect(result.inspection.signatureFilePath, isNotNull);

    final persisted = await repository.getInspection(inspection.id);
    expect(persisted?.status, InspectionStatus.complete);
    expect(persisted?.completedAt, isNotNull);
  });
}

Future<InspectionRecord> _savedCompleteInspection(
  InspectionRepository repository,
  Directory tempDir, {
  bool includePhoto = false,
}) async {
  final inspection = _completeInspection(tempDir);
  if (includePhoto) {
    final photo = await _copyAsset(
      tempDir,
      'assets/demo/sample_photo_1.jpg',
      'axle_housing.jpg',
    );
    inspection.photos.add(
      InspectionPhoto(
        id: 'photo-1',
        inspectionId: inspection.id,
        sectionKey: 'visual_inspection',
        itemKey: 'axle_housing',
        filePath: photo.path,
        caption: 'Axle housing evidence',
        sortOrder: 0,
        capturedAt: DateTime.utc(2026, 7, 1, 10),
        createdAt: DateTime.utc(2026, 7, 1, 10),
      ),
    );
  }
  return repository.saveInspection(inspection);
}

InspectionRecord _completeInspection(Directory tempDir) {
  final signatureFile = File(
    p.join(tempDir.path, 'signature.png'),
  )..writeAsBytesSync(File('assets/demo/sample_photo_1.jpg').readAsBytesSync());
  final inspection = buildInspection(
    id: 'workflow-${const Uuid().v4()}',
    documentNumber: '20260701-0001',
    status: InspectionStatus.inProgress,
    signatureFilePath: signatureFile.path,
    criticalAcknowledged: true,
    finalTechComments: 'Ready for customer handoff.',
  );
  fillRequiredResponses(inspection);
  return inspection;
}

Future<File> _copyAsset(
  Directory tempDir,
  String assetPath,
  String fileName,
) async {
  final output = File(p.join(tempDir.path, fileName));
  await output.writeAsBytes(await File(assetPath).readAsBytes(), flush: true);
  return output;
}
