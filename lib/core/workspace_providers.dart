import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/database/app_database.dart';
import '../data/repositories/inspection_repository.dart';
import '../services/backup_service.dart';
import '../services/document_number_service.dart';
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

final workspaceProvider = ChangeNotifierProvider<AppWorkspaceController>(
  (ref) => AppWorkspaceController(
    repository: ref.watch(inspectionRepositoryProvider),
  ),
);
