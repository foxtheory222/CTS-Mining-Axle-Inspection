import 'dart:convert';
import 'dart:io';

import 'package:cts_mining_axle_inspection/core/constants.dart';
import 'package:cts_mining_axle_inspection/data/database/app_database.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_enums.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_models.dart';
import 'package:cts_mining_axle_inspection/data/repositories/inspection_repository.dart';
import 'package:cts_mining_axle_inspection/services/document_number_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/persistence_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(sqfliteFfiInit);

  test('upgrades the original v1 schema without losing inspections', () async {
    final directory = await Directory.systemTemp.createTemp(
      'axle_database_v1_migration_',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final dbPath = _databasePath(directory);
    final legacyDatabase = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: 1, onCreate: _createOriginalV1),
    );
    final legacyRecord = buildInspection(
      id: 'legacy-inspection',
      documentNumber: '20260714-0001',
      status: InspectionStatus.inProgress,
      customer: 'Legacy Mine',
      workOrderNumber: 'WO-LEGACY-1',
      siteLocation: 'North Pit',
      equipmentMake: '',
      equipmentModel: '',
      machineSerialNumber: '',
      axleManufacturer: '',
      axleModel: '',
      axleSerialNumber: '',
    );
    final legacyPayload = legacyRecord.toJson()
      ..remove('equipmentMake')
      ..remove('equipmentModel')
      ..remove('machineSerialNumber')
      ..remove('axleManufacturer')
      ..remove('axleModel')
      ..remove('axleSerialNumber');
    await legacyDatabase.insert('inspections', <String, Object?>{
      'id': legacyRecord.id,
      'document_number': legacyRecord.documentNumber,
      'status': legacyRecord.status.value,
      'customer': legacyRecord.customer,
      'work_order_number': legacyRecord.workOrderNumber,
      'asset_name': legacyRecord.assetName,
      'technician_name': legacyRecord.technicianName,
      'customer_reference': legacyRecord.customerReference,
      'site_location': legacyRecord.siteLocation,
      'servicing_shop': legacyRecord.servicingShop,
      'inspection_date_time': legacyRecord.inspectionDateTime.toIso8601String(),
      'created_at': legacyRecord.createdAt.toIso8601String(),
      'updated_at': legacyRecord.updatedAt.toIso8601String(),
      'completed_at': null,
      'emailed_at': null,
      'generated_pdf_path': null,
      'has_critical': 0,
      'flagged_count': 0,
      'photo_count': 0,
      'payload_json': jsonEncode(legacyPayload),
    });
    await legacyDatabase.insert('document_sequences', <String, Object?>{
      'date_key': '20260714',
      'last_sequence': 1,
    });
    await legacyDatabase.close();

    final database = TestAppDatabase(directory);
    addTearDown(database.close);
    final repository = InspectionRepository(
      database: database,
      documentNumberService: DocumentNumberService(),
    );
    final upgradedDatabase = await database.open();

    expect(await upgradedDatabase.getVersion(), AppDatabase.schemaVersion);
    expect(
      await _inspectionColumnNames(upgradedDatabase),
      containsAll(<String>{
        'equipment_make',
        'equipment_model',
        'machine_serial_number',
        'axle_manufacturer',
        'axle_model',
        'axle_serial_number',
      }),
    );
    expect(
      await _inspectionIndexNames(upgradedDatabase),
      containsAll(<String>{
        'idx_inspections_equipment_model',
        'idx_inspections_machine_serial_number',
        'idx_inspections_axle_serial_number',
      }),
    );

    final restoredLegacy = await repository.getInspection(legacyRecord.id);
    expect(restoredLegacy, isNotNull);
    expect(restoredLegacy!.customer, 'Legacy Mine');
    expect(restoredLegacy.equipmentMake, isEmpty);

    final created = await repository.createInspection(
      createdAt: DateTime(2026, 7, 14, 12),
    );
    expect(created.documentNumber, '20260714-0002');
    created
      ..equipmentMake = 'Caterpillar'
      ..equipmentModel = '793F'
      ..machineSerialNumber = 'CAT-793-001'
      ..axleManufacturer = 'Dana'
      ..axleModel = '53R300'
      ..axleSerialNumber = 'AXLE-MIGRATED-2';
    await repository.saveInspection(created);

    final searchResults = await repository.search(
      const InspectionSearchQuery(term: 'AXLE-MIGRATED-2'),
    );
    expect(searchResults.map((record) => record.id), contains(created.id));

    await database.close();
    final reopenedDatabase = TestAppDatabase(directory);
    addTearDown(reopenedDatabase.close);
    final reopenedRepository = InspectionRepository(
      database: reopenedDatabase,
      documentNumberService: DocumentNumberService(),
    );
    expect(
      (await reopenedRepository.allInspections()).map((record) => record.id),
      containsAll(<String>{legacyRecord.id, created.id}),
    );
  });

  test('upgrades an expanded version-1 database idempotently', () async {
    final directory = await Directory.systemTemp.createTemp(
      'axle_database_expanded_v1_migration_',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final legacyDatabase = await databaseFactoryFfi.openDatabase(
      _databasePath(directory),
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: AppDatabase.createSchema,
      ),
    );
    await legacyDatabase.close();

    final database = TestAppDatabase(directory);
    addTearDown(database.close);
    final upgradedDatabase = await database.open();

    expect(await upgradedDatabase.getVersion(), AppDatabase.schemaVersion);
    expect(
      await _inspectionColumnNames(upgradedDatabase),
      contains('equipment_make'),
    );
    final repository = InspectionRepository(
      database: database,
      documentNumberService: DocumentNumberService(),
    );
    expect(await repository.createInspection(), isNotNull);
  });
}

String _databasePath(Directory directory) =>
    '${directory.path}${Platform.pathSeparator}${AppConstants.databaseName}';

Future<Set<String>> _inspectionColumnNames(Database database) async {
  final rows = await database.rawQuery('PRAGMA table_info(inspections)');
  return rows.map((row) => row['name'] as String).toSet();
}

Future<Set<String>> _inspectionIndexNames(Database database) async {
  final rows = await database.rawQuery('PRAGMA index_list(inspections)');
  return rows.map((row) => row['name'] as String).toSet();
}

Future<void> _createOriginalV1(Database database, int version) async {
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
