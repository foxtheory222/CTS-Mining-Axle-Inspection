import 'dart:io';

import 'package:cts_mining_axle_inspection/core/workspace_controller.dart';
import 'package:cts_mining_axle_inspection/core/workspace_models.dart';
import 'package:cts_mining_axle_inspection/core/workspace_providers.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_enums.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_models.dart';
import 'package:cts_mining_axle_inspection/data/repositories/inspection_repository.dart';
import 'package:cts_mining_axle_inspection/features/inspection_detail/inspection_detail_screen.dart';
import 'package:cts_mining_axle_inspection/services/backup_service.dart';
import 'package:cts_mining_axle_inspection/services/document_number_service.dart';
import 'package:cts_mining_axle_inspection/services/email_service.dart';
import 'package:cts_mining_axle_inspection/services/inspection_workflow_service.dart';
import 'package:cts_mining_axle_inspection/services/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/persistence_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  testWidgets('generating a detail PDF offers a viewable report action', (
    tester,
  ) async {
    final tempDir = Directory.systemTemp.createTempSync(
      'inspection_detail_pdf_',
    );
    final database = TestAppDatabase(tempDir);
    final repository = InspectionRepository(
      database: database,
      documentNumberService: DocumentNumberService(),
    );
    final pdfFile = File('${tempDir.path}/generated.pdf')
      ..writeAsBytesSync(<int>[37, 80, 68, 70]);
    final inspection = buildInspection(
      id: 'inspection-detail-1',
      documentNumber: '20260701-0001',
      status: InspectionStatus.complete,
      completedAt: DateTime.utc(2026, 7, 1, 12),
    );
    final workspace = _DetailWorkspaceController(
      repository: repository,
      record: inspection,
    );
    final workflow = _FakeWorkflowService(
      repository: repository,
      pdfFile: pdfFile,
    );
    addTearDown(() async {
      await database.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workspaceProvider.overrideWith((ref) => workspace),
          inspectionWorkflowServiceProvider.overrideWithValue(workflow),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: InspectionDetailScreen(inspectionId: 'inspection-detail-1'),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Generate PDF'));
    await tester.pumpAndSettle();

    expect(workflow.generateCount, 1);
    expect(find.text('PDF ready'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'View'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Share'), findsOneWidget);
  });
}

class _DetailWorkspaceController extends AppWorkspaceController {
  _DetailWorkspaceController({required super.repository, required this.record});

  final InspectionRecord record;

  @override
  InspectionSummary? inspectionById(String id) {
    if (id != record.id) {
      return null;
    }
    return _summaryFor(record);
  }

  @override
  Future<InspectionRecord?> inspectionRecordById(String id) async {
    if (id != record.id) {
      return null;
    }
    return record.clone();
  }

  @override
  Future<void> refresh() async {}
}

class _FakeWorkflowService extends InspectionWorkflowService {
  _FakeWorkflowService({required super.repository, required this.pdfFile})
    : super(
        pdfService: PdfService(compress: false),
        backupService: BackupService(),
        emailService: EmailService(shareAdapter: FakeEmailShareAdapter()),
      );

  final File pdfFile;
  int generateCount = 0;

  @override
  Future<PdfGenerationResult> generatePdf(InspectionRecord inspection) async {
    generateCount++;
    return PdfGenerationResult(
      inspection: inspection.clone()..generatedPdfPath = pdfFile.path,
      pdfFile: pdfFile,
    );
  }

  @override
  Future<InspectionEmailWorkflowResult> shareInspectionPdf(
    InspectionRecord inspection, {
    List<String> recipients = const <String>[],
  }) async {
    return InspectionEmailWorkflowResult(
      inspection: inspection.clone(),
      pdfFile: pdfFile,
      handoffResult: EmailHandoffResult(
        launched: true,
        recipients: recipients,
        subject: 'CTS Mining Axle Inspection ${inspection.documentNumber}',
        body: 'Attached report',
        attachmentPath: pdfFile.path,
      ),
    );
  }
}

InspectionSummary _summaryFor(InspectionRecord record) {
  return InspectionSummary(
    id: record.id,
    documentNumber: record.documentNumber,
    customer: record.customer,
    workOrderNumber: record.workOrderNumber,
    customerReference: record.customerReference,
    assetName: record.assetName,
    siteLocation: record.siteLocation,
    technicianName: record.technicianName,
    servicingShop: record.servicingShop,
    inspectionDateTime: record.inspectionDateTime,
    createdAt: record.createdAt,
    status: record.status,
    sections: const <InspectionSectionView>[],
    actionItems: const <InspectionActionItemView>[],
    photos: const <InspectionPhotoView>[],
    flaggedCount: record.flaggedItemCount,
    atRiskCount: record.atRiskCount,
    unsatisfactoryCount: record.unsatisfactoryCount,
    criticalCount: record.criticalCount,
    photoCount: record.photoCount,
    lastUpdatedAt: record.updatedAt,
    completedAt: record.completedAt,
    emailedAt: record.emailedAt,
    finalTechComments: record.finalTechComments,
    criticalAcknowledged: record.criticalAcknowledged,
    generatedPdfPath: record.generatedPdfPath,
  );
}
