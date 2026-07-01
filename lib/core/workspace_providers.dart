import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/database/app_database.dart';
import '../data/repositories/inspection_repository.dart';
import '../services/backup_service.dart';
import '../services/document_number_service.dart';
import '../services/email_service.dart';
import '../services/inspection_workflow_service.dart';
import '../services/pdf_service.dart';
import '../services/photo_service.dart';
import 'workspace_controller.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final documentNumberServiceProvider = Provider<DocumentNumberService>(
  (ref) => DocumentNumberService(),
);

final inspectionRepositoryProvider = Provider<InspectionRepository>((ref) {
  return InspectionRepository(
    database: ref.watch(appDatabaseProvider),
    documentNumberService: ref.watch(documentNumberServiceProvider),
  );
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});

final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService();
});

final photoServiceProvider = Provider<PhotoService>((ref) {
  return PhotoService();
});

final inspectionWorkflowServiceProvider = Provider<InspectionWorkflowService>((
  ref,
) {
  return InspectionWorkflowService(
    repository: ref.watch(inspectionRepositoryProvider),
    pdfService: ref.watch(pdfServiceProvider),
    backupService: ref.watch(backupServiceProvider),
    emailService: ref.watch(emailServiceProvider),
  );
});

final workspaceProvider = ChangeNotifierProvider<AppWorkspaceController>(
  (ref) => AppWorkspaceController(
    repository: ref.watch(inspectionRepositoryProvider),
  ),
);
