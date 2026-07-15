import 'dart:convert';

import 'package:cts_mining_axle_inspection/app.dart';
import 'package:cts_mining_axle_inspection/core/constants.dart';
import 'package:cts_mining_axle_inspection/core/date_time_utils.dart';
import 'package:cts_mining_axle_inspection/core/file_utils.dart';
import 'package:cts_mining_axle_inspection/data/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('legacy v1 data upgrades and Start New Inspection works', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final dateKey = DateTimeUtils.documentDateKey(now);
    final databasePath = p.join(
      (await FileUtils.appRootDirectory()).path,
      AppConstants.databaseName,
    );
    await deleteDatabase(databasePath);
    final legacyDatabase = await openDatabase(
      databasePath,
      version: 1,
      onCreate: _createLegacyV1Schema,
    );
    final legacyPayload = jsonEncode(<String, Object?>{
      'id': 'legacy-device-record',
      'documentNumber': '$dateKey-0001',
      'status': 'in_progress',
      'customer': 'Legacy Mine',
      'inspectionDateTime': now.toIso8601String(),
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
    await legacyDatabase.insert('inspections', <String, Object?>{
      'id': 'legacy-device-record',
      'document_number': '$dateKey-0001',
      'status': 'in_progress',
      'customer': 'Legacy Mine',
      'work_order_number': 'WO-LEGACY',
      'asset_name': 'Legacy Axle',
      'technician_name': 'Legacy Inspector',
      'customer_reference': '',
      'site_location': 'Legacy Pit',
      'servicing_shop': '',
      'inspection_date_time': now.toIso8601String(),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'has_critical': 0,
      'flagged_count': 0,
      'photo_count': 0,
      'payload_json': legacyPayload,
    });
    await legacyDatabase.insert('document_sequences', <String, Object?>{
      'date_key': dateKey,
      'last_sequence': 1,
    });
    await legacyDatabase.close();

    await tester.pumpWidget(
      const ProviderScope(child: CtsMiningAxleInspectionApp()),
    );
    final newInspectionButton = find.widgetWithText(
      FilledButton,
      'New Inspection',
    );
    await _pumpUntil(
      tester,
      () =>
          newInspectionButton.evaluate().isNotEmpty &&
          tester.widget<FilledButton>(newInspectionButton).onPressed != null,
    );
    expect(find.byKey(const Key('storage_error_banner')), findsNothing);

    await tester.tap(newInspectionButton);
    await _pumpUntil(
      tester,
      () => find.text('New Mining Axle Inspection').evaluate().isNotEmpty,
    );
    expect(find.byKey(const Key('inspection_load_failure')), findsNothing);

    final upgradedDatabase = await openDatabase(databasePath, readOnly: true);
    addTearDown(upgradedDatabase.close);
    expect(await upgradedDatabase.getVersion(), AppDatabase.schemaVersion);
    final columns = await upgradedDatabase.rawQuery(
      'PRAGMA table_info(inspections)',
    );
    expect(
      columns.map((row) => row['name']),
      containsAll(<String>{
        'equipment_make',
        'equipment_model',
        'machine_serial_number',
        'axle_manufacturer',
        'axle_model',
        'axle_serial_number',
      }),
    );
    final rows = await upgradedDatabase.query(
      'inspections',
      columns: <String>['id', 'document_number'],
      orderBy: 'document_number',
    );
    expect(rows, hasLength(2));
    expect(rows.first['id'], 'legacy-device-record');
    expect(rows.last['document_number'], '$dateKey-0002');
  });
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 60; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
  }
  fail('Condition was not met within 12 seconds.');
}

Future<void> _createLegacyV1Schema(Database database, int version) async {
  await database.execute('''
    CREATE TABLE inspections(
      id TEXT PRIMARY KEY,
      document_number TEXT NOT NULL UNIQUE,
      status TEXT NOT NULL,
      customer TEXT NOT NULL,
      work_order_number TEXT NOT NULL,
      asset_name TEXT NOT NULL,
      technician_name TEXT NOT NULL,
      customer_reference TEXT NOT NULL,
      site_location TEXT NOT NULL,
      servicing_shop TEXT NOT NULL,
      inspection_date_time TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      completed_at TEXT,
      emailed_at TEXT,
      generated_pdf_path TEXT,
      has_critical INTEGER NOT NULL DEFAULT 0,
      flagged_count INTEGER NOT NULL DEFAULT 0,
      photo_count INTEGER NOT NULL DEFAULT 0,
      payload_json TEXT NOT NULL
    )
  ''');
  await database.execute('''
    CREATE TABLE document_sequences(
      date_key TEXT PRIMARY KEY,
      last_sequence INTEGER NOT NULL
    )
  ''');
  await database.execute('''
    CREATE TABLE email_recipients(
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL,
      customer TEXT,
      last_used_at TEXT NOT NULL,
      usage_count INTEGER NOT NULL DEFAULT 0,
      is_customer_default INTEGER NOT NULL DEFAULT 0
    )
  ''');
}
