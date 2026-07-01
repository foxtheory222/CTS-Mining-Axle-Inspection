import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cts_mining_axle_inspection/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Backup service exports and imports inspection archives', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'backup_service_test_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final photoFile = await _writePhoto(tempDir, 'photo.jpg');
    final pdfFile = await _writePdf(tempDir, 'report.pdf');
    final service = BackupService(
      documentsDirectoryProvider: () async => tempDir,
    );
    final exportResult = await service.exportInspection(
      data: InspectionBackupData(
        inspectionJson: <String, dynamic>{
          'documentNumber': '20260420-0001',
          'templateKey': 'mining_axle_inspection',
          'templateVersion': '1.0.0',
          'customer': 'CTS',
          'workOrderNumber': 'WO-1001',
          'axleSerialNumber': 'AX-1001',
          'photos': <Map<String, dynamic>>[
            <String, dynamic>{'filePath': photoFile.path},
          ],
        },
        documentNumber: '20260420-0001',
        customer: 'CTS',
        workOrderNumber: 'WO-1001',
        axleSerialNumber: 'AX-1001',
        photoFiles: <File>[photoFile],
        generatedPdfFile: pdfFile,
      ),
    );

    expect(await exportResult.archiveFile.exists(), isTrue);
    expect(await exportResult.archiveFile.length(), greaterThan(0));
    expect(
      p.basename(exportResult.archiveFile.path),
      'CTS_InspectionBundle_20260420-0001_AXLE.zip',
    );

    expect(
      () => service.importInspection(
        archiveFile: exportResult.archiveFile,
        existingDocumentNumbers: const <String>{'20260420-0001'},
      ),
      throwsA(
        isA<BackupServiceException>().having(
          (exception) => exception.code,
          'code',
          BackupServiceErrorCode.conflict,
        ),
      ),
    );

    final importResult = await service.importInspection(
      archiveFile: exportResult.archiveFile,
    );
    expect(importResult.documentNumberChanged, isFalse);
    expect(importResult.documentNumber, '20260420-0001');
    expect(importResult.restoredPhotoFiles, isNotEmpty);
    final photos = importResult.inspectionJson['photos'] as List<dynamic>;
    expect(
      (photos.single as Map<String, dynamic>)['filePath'],
      importResult.restoredPhotoFiles.single.path,
    );
    expect(importResult.restoredPdfFile, isNotNull);
  });

  test(
    'Backup service preserves document number when there is no conflict',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'backup_service_no_conflict_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final pdfFile = await _writePdf(tempDir, 'report.pdf');
      final service = BackupService(
        documentsDirectoryProvider: () async => tempDir,
      );
      final exportResult = await service.exportInspection(
        data: InspectionBackupData(
          inspectionJson: <String, dynamic>{
            'documentNumber': '20260420-0002',
            'templateKey': 'mining_axle_inspection',
            'templateVersion': '1.0.0',
            'customer': 'CTS',
            'workOrderNumber': 'WO-1002',
            'machineSerialNumber': 'MACH-1002',
          },
          documentNumber: '20260420-0002',
          customer: 'CTS',
          workOrderNumber: 'WO-1002',
          machineSerialNumber: 'MACH-1002',
          generatedPdfFile: pdfFile,
        ),
      );

      final importResult = await service.importInspection(
        archiveFile: exportResult.archiveFile,
        existingDocumentNumbers: const <String>{'20260420-9999'},
      );

      expect(importResult.documentNumber, '20260420-0002');
      expect(importResult.documentNumberChanged, isFalse);
    },
  );

  test(
    'Backup import rejects zip entries that escape restore folder',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'backup_service_traversal_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final archive = Archive()
        ..addFile(
          ArchiveFile.string(
            'inspection.json',
            jsonEncode(<String, dynamic>{
              'documentNumber': '20260420-0042',
              'templateKey': 'mining_axle_inspection',
              'templateVersion': '1.0.0',
            }),
          ),
        )
        ..addFile(ArchiveFile.string('../../outside.txt', 'owned'));
      final zipFile = File(p.join(tempDir.path, 'malicious.zip'));
      await zipFile.writeAsBytes(ZipEncoder().encode(archive), flush: true);

      final service = BackupService(
        documentsDirectoryProvider: () async => tempDir,
      );

      expect(
        () => service.importInspection(archiveFile: zipFile),
        throwsA(
          isA<BackupServiceException>().having(
            (exception) => exception.code,
            'code',
            BackupServiceErrorCode.archive,
          ),
        ),
      );
      expect(await File(p.join(tempDir.path, 'outside.txt')).exists(), isFalse);
    },
  );
}

Future<File> _writePhoto(Directory directory, String fileName) async {
  final image = img.Image(width: 60, height: 40);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixelRgba(x, y, 200, 40 + x, 40 + y, 255);
    }
  }
  final file = File(p.join(directory.path, fileName));
  await file.writeAsBytes(
    Uint8List.fromList(img.encodeJpg(image, quality: 90)),
  );
  return file;
}

Future<File> _writePdf(Directory directory, String fileName) async {
  final file = File(p.join(directory.path, fileName));
  await file.writeAsBytes(
    Uint8List.fromList(List<int>.generate(72, (index) => (index * 3) % 255)),
  );
  return file;
}
