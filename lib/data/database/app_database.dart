import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../../core/file_utils.dart';

class AppDatabase {
  AppDatabase();

  static const int schemaVersion = 2;

  static const Map<String, String> _version2InspectionColumns =
      <String, String>{
        'equipment_make': "TEXT NOT NULL DEFAULT ''",
        'equipment_model': "TEXT NOT NULL DEFAULT ''",
        'machine_serial_number': "TEXT NOT NULL DEFAULT ''",
        'axle_manufacturer': "TEXT NOT NULL DEFAULT ''",
        'axle_model': "TEXT NOT NULL DEFAULT ''",
        'axle_serial_number': "TEXT NOT NULL DEFAULT ''",
      };

  Database? _database;
  Future<Database>? _openingDatabase;

  Future<Database> open() async {
    if (_database != null) {
      return _database!;
    }
    final opening = _openingDatabase;
    if (opening != null) {
      return opening;
    }

    final String dbPath = p.join(
      (await FileUtils.appRootDirectory()).path,
      AppConstants.databaseName,
    );

    _openingDatabase = openDatabase(
      dbPath,
      version: schemaVersion,
      onCreate: createSchema,
      onUpgrade: upgradeSchema,
    );

    try {
      _database = await _openingDatabase;
      return _database!;
    } finally {
      _openingDatabase = null;
    }
  }

  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''
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
        equipment_make TEXT NOT NULL DEFAULT '',
        equipment_model TEXT NOT NULL DEFAULT '',
        machine_serial_number TEXT NOT NULL DEFAULT '',
        axle_manufacturer TEXT NOT NULL DEFAULT '',
        axle_model TEXT NOT NULL DEFAULT '',
        axle_serial_number TEXT NOT NULL DEFAULT '',
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

    await db.execute('''
      CREATE TABLE document_sequences(
        date_key TEXT PRIMARY KEY,
        last_sequence INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE email_recipients(
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        customer TEXT,
        last_used_at TEXT NOT NULL,
        usage_count INTEGER NOT NULL DEFAULT 0,
        is_customer_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await _createInspectionIndexes(db);
  }

  static Future<void> upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await _upgradeToVersion2(db);
    }
  }

  static Future<void> _upgradeToVersion2(Database db) async {
    final tableInfo = await db.rawQuery('PRAGMA table_info(inspections)');
    final existingColumns = tableInfo
        .map((row) => row['name'] as String)
        .toSet();

    // Some v1.1.0 installs created the expanded table while still reporting
    // schema version 1. Check each column so both original v1.0 databases and
    // those partially upgraded databases can move to version 2 safely.
    for (final column in _version2InspectionColumns.entries) {
      if (existingColumns.contains(column.key)) {
        continue;
      }
      await db.execute(
        'ALTER TABLE inspections ADD COLUMN ${column.key} ${column.value}',
      );
    }

    await _createInspectionIndexes(db);
  }

  static Future<void> _createInspectionIndexes(Database db) async {
    const indexes = <String>[
      'CREATE INDEX IF NOT EXISTS idx_inspections_status '
          'ON inspections(status)',
      'CREATE INDEX IF NOT EXISTS idx_inspections_updated '
          'ON inspections(updated_at DESC)',
      'CREATE INDEX IF NOT EXISTS idx_inspections_document_number '
          'ON inspections(document_number)',
      'CREATE INDEX IF NOT EXISTS idx_inspections_customer '
          'ON inspections(customer)',
      'CREATE INDEX IF NOT EXISTS idx_inspections_work_order_number '
          'ON inspections(work_order_number)',
      'CREATE INDEX IF NOT EXISTS idx_inspections_asset_name '
          'ON inspections(asset_name)',
      'CREATE INDEX IF NOT EXISTS idx_inspections_technician_name '
          'ON inspections(technician_name)',
      'CREATE INDEX IF NOT EXISTS idx_inspections_equipment_model '
          'ON inspections(equipment_model)',
      'CREATE INDEX IF NOT EXISTS idx_inspections_machine_serial_number '
          'ON inspections(machine_serial_number)',
      'CREATE INDEX IF NOT EXISTS idx_inspections_axle_serial_number '
          'ON inspections(axle_serial_number)',
      'CREATE INDEX IF NOT EXISTS idx_inspections_inspection_date_time '
          'ON inspections(inspection_date_time)',
    ];
    for (final statement in indexes) {
      await db.execute(statement);
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
