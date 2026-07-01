import 'dart:io';

import '../core/file_utils.dart';
import '../core/validators.dart';
import '../data/models/inspection_models.dart';
import '../data/repositories/inspection_repository.dart';
import 'backup_service.dart';
import 'email_service.dart';
import 'inspection_report_mapper.dart';
import 'pdf_service.dart';

typedef ReportDirectoryProvider =
    Future<Directory> Function(InspectionRecord inspection);

class PdfGenerationResult {
  const PdfGenerationResult({required this.inspection, required this.pdfFile});

  final InspectionRecord inspection;
  final File pdfFile;
}

class InspectionExportWorkflowResult {
  const InspectionExportWorkflowResult({
    required this.inspection,
    required this.exportResult,
  });

  final InspectionRecord inspection;
  final BackupExportResult exportResult;
}

class InspectionEmailWorkflowResult {
  const InspectionEmailWorkflowResult({
    required this.inspection,
    required this.pdfFile,
    required this.handoffResult,
  });

  final InspectionRecord inspection;
  final File pdfFile;
  final EmailHandoffResult handoffResult;
}

class InspectionCompletionWorkflowResult {
  const InspectionCompletionWorkflowResult({required this.inspection});

  final InspectionRecord inspection;
}

class InspectionWorkflowService {
  InspectionWorkflowService({
    required InspectionRepository repository,
    required PdfService pdfService,
    required BackupService backupService,
    required EmailService emailService,
    ReportDirectoryProvider? reportDirectoryProvider,
  }) : _repository = repository,
       _pdfService = pdfService,
       _backupService = backupService,
       _emailService = emailService,
       reportDirectoryProvider =
           reportDirectoryProvider ??
           ((inspection) =>
               FileUtils.inspectionReportsDirectory(inspection.id));

  final InspectionRepository _repository;
  final PdfService _pdfService;
  final BackupService _backupService;
  final EmailService _emailService;
  final ReportDirectoryProvider reportDirectoryProvider;

  Future<PdfGenerationResult> generatePdf(InspectionRecord inspection) async {
    final saved = await _repository.saveInspection(inspection.clone());
    final pdfFile = await _generatePdfForSavedInspection(saved);
    saved.generatedPdfPath = pdfFile.path;
    final updated = await _repository.saveInspection(saved);
    return PdfGenerationResult(inspection: updated.clone(), pdfFile: pdfFile);
  }

  Future<InspectionExportWorkflowResult> exportInspection(
    InspectionRecord inspection,
  ) async {
    final pdfResult = await generatePdf(inspection);
    final record = pdfResult.inspection;
    final result = await _backupService.exportInspection(
      data: _backupData(record, generatedPdfFile: pdfResult.pdfFile),
    );
    return InspectionExportWorkflowResult(
      inspection: record.clone(),
      exportResult: result,
    );
  }

  Future<InspectionEmailWorkflowResult> shareInspectionPdf(
    InspectionRecord inspection, {
    List<String> recipients = const <String>[],
  }) async {
    final pdfResult = await generatePdf(inspection);
    final record = pdfResult.inspection;
    final handoff = await _emailService.handoffPdf(
      request: EmailHandoffRequest(
        pdfFile: pdfResult.pdfFile,
        subject: 'CTS Mining Axle Inspection ${record.documentNumber}',
        body:
            'Attached is the Combined Technical Services mining axle inspection report for ${record.customer}.',
        recipients: recipients,
        customer: record.customer,
      ),
    );
    final emailed = await _repository.markEmailed(record);
    return InspectionEmailWorkflowResult(
      inspection: emailed.clone(),
      pdfFile: pdfResult.pdfFile,
      handoffResult: handoff,
    );
  }

  Future<InspectionCompletionWorkflowResult> completeInspection(
    InspectionRecord inspection,
  ) async {
    final validation = InspectionValidator.validateForCompletion(inspection);
    if (!validation.isValid) {
      throw StateError(
        'Inspection has ${validation.issues.length} completion blocker(s).',
      );
    }
    final saved = await _repository.saveInspection(inspection.clone());
    return InspectionCompletionWorkflowResult(inspection: saved.clone());
  }

  Future<PdfGenerationResult> ensurePdfExists(
    InspectionRecord inspection,
  ) async {
    final path = inspection.generatedPdfPath;
    if (path != null && path.trim().isNotEmpty) {
      final file = File(path);
      if (await file.exists()) {
        return PdfGenerationResult(
          inspection: inspection.clone(),
          pdfFile: file,
        );
      }
    }
    return generatePdf(inspection);
  }

  Future<File> _generatePdfForSavedInspection(
    InspectionRecord inspection,
  ) async {
    final directory = await reportDirectoryProvider(inspection);
    await directory.create(recursive: true);
    return _pdfService.generateInspectionReportFile(
      InspectionReportMapper.fromRecord(inspection),
      outputDirectory: directory,
    );
  }

  InspectionBackupData _backupData(
    InspectionRecord record, {
    File? generatedPdfFile,
  }) {
    return InspectionBackupData(
      inspectionJson: record.toJson(),
      documentNumber: record.documentNumber,
      customer: record.customer,
      workOrderNumber: record.workOrderNumber,
      axleSerialNumber: record.axleSerialNumber,
      machineSerialNumber: record.machineSerialNumber,
      photoFiles: record.photos.map((photo) => File(photo.filePath)).toList(),
      generatedPdfFile:
          generatedPdfFile ??
          (record.generatedPdfPath == null
              ? null
              : File(record.generatedPdfPath!)),
    );
  }
}
