import 'dart:async';
import 'dart:io';

import 'package:cts_mining_axle_inspection/core/mining_axle_template.dart';
import 'package:cts_mining_axle_inspection/core/workspace_controller.dart';
import 'package:cts_mining_axle_inspection/core/workspace_models.dart';
import 'package:cts_mining_axle_inspection/core/workspace_providers.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_enums.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_models.dart';
import 'package:cts_mining_axle_inspection/data/repositories/inspection_repository.dart';
import 'package:cts_mining_axle_inspection/features/inspection_form/inspection_form_screen.dart';
import 'package:cts_mining_axle_inspection/services/document_number_service.dart';
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

  testWidgets(
    'new inspection form starts from a blank record and exposes real draft save',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InspectionFormScreen(initialRecord: _blankInspection()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('New Mining Axle Inspection'), findsOneWidget);
      expect(_editableTextWithValue('Moraine Quarry'), findsNothing);
      expect(_editableTextWithValue('R. Ellis'), findsNothing);
      expect(_editableTextWithValue('AXLE-1001'), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Save Draft'), findsWidgets);

      final axleHousing = tester.widget<DropdownButtonFormField<String>>(
        find.byWidgetPredicate(
          (widget) =>
              widget is DropdownButtonFormField<String> &&
              widget.decoration.labelText == 'Axle Housing *',
        ),
      );
      expect(axleHousing.initialValue, isNull);
    },
  );

  testWidgets('photo source sheet exposes only real device sources', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InspectionFormScreen(initialRecord: _blankInspection()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));

    final addPhotoButton = find.widgetWithText(FilledButton, 'Add first photo');
    await tester.ensureVisible(addPhotoButton.first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(addPhotoButton.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Sample photo'), findsNothing);
  });

  testWidgets('flagged rows expose a per-item evidence photo action', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InspectionFormScreen(initialRecord: _blankInspection()),
        ),
      ),
    );
    await tester.pump();

    final oilLeaksDropdown = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButtonFormField<String> &&
          widget.decoration.labelText == 'Oil Leaks *',
      description: 'Oil Leaks dropdown',
    );
    await tester.ensureVisible(oilLeaksDropdown);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(oilLeaksDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes').last);
    await tester.pumpAndSettle();

    expect(find.text('Comment, photo & action required'), findsOneWidget);
    expect(
      find.byKey(const Key('add_evidence_photo_oil_leaks')),
      findsOneWidget,
    );
  });

  testWidgets('an adverse row can be marked Critical / Out of Service', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InspectionFormScreen(initialRecord: _blankInspection()),
        ),
      ),
    );
    await tester.pump();

    final oilLeaksDropdown = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButtonFormField<String> &&
          widget.decoration.labelText == 'Oil Leaks *',
    );
    await tester.ensureVisible(oilLeaksDropdown);
    await tester.tap(oilLeaksDropdown);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Yes').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('critical_toggle_oil_leaks')));
    await tester.pump(const Duration(milliseconds: 300));

    final criticalChip = tester.widget<FilterChip>(
      find.byKey(const Key('critical_toggle_oil_leaks')),
    );
    expect(criticalChip.selected, isTrue);
    expect(
      find.text('Critical / Out of Service acknowledgement'),
      findsOneWidget,
    );
  });

  testWidgets('draft save failures are shown without crashing the form', (
    tester,
  ) async {
    final tempDir = Directory.systemTemp.createTempSync(
      'inspection_form_save_failure_',
    );
    final database = TestAppDatabase(tempDir);
    final repository = InspectionRepository(
      database: database,
      documentNumberService: DocumentNumberService(),
    );
    final workspace = _FailingWorkspaceController(repository: repository);
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
        overrides: [workspaceProvider.overrideWith((ref) => workspace)],
        child: MaterialApp(
          home: Scaffold(
            body: InspectionFormScreen(initialRecord: _blankInspection()),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Save Draft').first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('Unable to save this inspection'),
      findsOneWidget,
    );
    expect(find.text('New Mining Axle Inspection'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new-record load failures show a persistent retry state', (
    tester,
  ) async {
    final tempDir = Directory.systemTemp.createTempSync(
      'inspection_form_load_failure_',
    );
    final database = TestAppDatabase(tempDir);
    final repository = InspectionRepository(
      database: database,
      documentNumberService: DocumentNumberService(),
    );
    final workspace = _FailingCreateWorkspaceController(repository: repository);
    await tester.pump(const Duration(milliseconds: 1));
    addTearDown(() async {
      await database.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [workspaceProvider.overrideWith((ref) => workspace)],
        child: const MaterialApp(home: Scaffold(body: InspectionFormScreen())),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(find.byKey(const Key('inspection_load_failure')), findsOneWidget);
    expect(find.text('Unable to start a new inspection'), findsOneWidget);
    expect(
      find.textContaining('The inspection editor is safely paused'),
      findsOneWidget,
    );
    expect(workspace.createAttempts, 1);
    expect(
      find.byKey(const Key('retry_inspection_load_button')),
      findsOneWidget,
    );
    expect(find.text('Inspection record was not found.'), findsNothing);

    await tester.tap(find.byKey(const Key('retry_inspection_load_button')));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(find.text('Unable to start a new inspection'), findsOneWidget);
    expect(workspace.createAttempts, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('row comments and table inputs persist after save and reload', (
    tester,
  ) async {
    final tempDir = Directory.systemTemp.createTempSync(
      'inspection_form_persistence_',
    );
    final database = TestAppDatabase(tempDir);
    final repository = InspectionRepository(
      database: database,
      documentNumberService: DocumentNumberService(),
    );
    final workspace = _TrackingWorkspaceController(repository: repository);
    addTearDown(() async {
      await database.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
    final initial = _blankInspection();

    await tester.binding.setSurfaceSize(const Size(1600, 1400));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          workspaceProvider.overrideWith((ref) => workspace),
        ],
        child: MaterialApp(
          home: Scaffold(body: InspectionFormScreen(initialRecord: initial)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await _enterKeyedText(
      tester,
      const Key('comment_axle_housing'),
      'Axle housing scuffed near left mount',
    );
    await _enterKeyedText(
      tester,
      const Key('oil_result_iso_cleanliness_code'),
      '18/16/13',
    );
    await _enterKeyedText(
      tester,
      const Key('oil_limits_iso_cleanliness_code'),
      'Within CTS target',
    );
    await _enterKeyedText(
      tester,
      const Key('measurement_specification_crown_wheel_backlash'),
      '0.30-0.45 mm',
    );
    await _enterKeyedText(
      tester,
      const Key('measurement_actual_crown_wheel_backlash'),
      '0.39 mm',
    );
    await _enterKeyedText(
      tester,
      const Key('measurement_comments_crown_wheel_backlash'),
      'Pattern acceptable',
    );
    final thermographySwitch = find.byKey(
      const Key('thermography_performed_switch'),
    );
    await tester.ensureVisible(thermographySwitch);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(thermographySwitch);
    await tester.pump(const Duration(milliseconds: 100));
    await _enterKeyedText(
      tester,
      const Key('temperature_temperature_c_left_planetary_hub'),
      '72.5',
    );
    await _enterKeyedText(
      tester,
      const Key('temperature_comments_left_planetary_hub'),
      'Stable after haul cycle',
    );

    final saveButton = find.widgetWithText(FilledButton, 'Save Draft').last;
    final savedFuture = workspace.nextSavedInspection;
    await tester.ensureVisible(saveButton);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(saveButton);
    await tester.pump();
    final draftFromButton = await tester.runAsync<InspectionRecord>(
      () => savedFuture.timeout(const Duration(seconds: 5)),
    );
    expect(draftFromButton, isNotNull);
    final saved = await tester.runAsync<InspectionRecord>(() async {
      await repository.saveInspection(draftFromButton!);
      final persisted = await repository.getInspection(initial.id);
      if (persisted == null) {
        throw StateError('Inspection ${initial.id} was not persisted.');
      }
      return persisted;
    });
    await tester.pump(const Duration(milliseconds: 100));
    expect(saved, isNotNull);
    expect(
      saved!
          .responseByKey(MiningAxleTemplate.visualInspection, 'axle_housing')
          ?.comment,
      'Axle housing scuffed near left mount',
    );
    expect(saved.oilAnalysisRows.single.parameter, 'ISO Cleanliness Code');
    expect(saved.oilAnalysisRows.single.result, '18/16/13');
    expect(saved.oilAnalysisRows.single.limits, 'Within CTS target');
    expect(
      saved.mechanicalMeasurementRows.single.measurement,
      'Crown Wheel Backlash',
    );
    expect(
      saved.mechanicalMeasurementRows.single.specification,
      '0.30-0.45 mm',
    );
    expect(saved.mechanicalMeasurementRows.single.actual, '0.39 mm');
    expect(
      saved.mechanicalMeasurementRows.single.comments,
      'Pattern acceptable',
    );
    expect(saved.temperatureRows.single.location, 'Left Planetary Hub');
    expect(saved.temperatureRows.single.temperatureC, 72.5);
    expect(saved.temperatureRows.single.comments, 'Stable after haul cycle');
    expect(
      saved
          .responseByKey(
            MiningAxleTemplate.temperatureAssessment,
            'thermography_performed',
          )
          ?.value,
      'true',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          workspaceProvider.overrideWith((ref) => workspace),
        ],
        child: MaterialApp(
          home: Scaffold(body: InspectionFormScreen(initialRecord: saved)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      _editableTextWithValue('Axle housing scuffed near left mount'),
      findsOneWidget,
    );
    expect(_editableTextWithValue('18/16/13'), findsOneWidget);
    expect(_editableTextWithValue('0.39 mm'), findsOneWidget);
    expect(_editableTextWithValue('72.5'), findsOneWidget);
  });
}

InspectionRecord _blankInspection() {
  final now = DateTime.utc(2026, 7, 1, 12);
  return InspectionRecord(
    id: 'blank-form',
    documentNumber: '20260701-0001',
    status: InspectionStatus.draft,
    inspectionDateTime: now,
    createdAt: now,
    updatedAt: now,
    sections: MiningAxleTemplate.sections
        .map(
          (section) => InspectionSectionProgress(
            id: 'blank-form_${section.key}',
            inspectionId: 'blank-form',
            sectionKey: section.key,
            title: section.title,
            sortOrder: section.sortOrder,
            completionState: SectionCompletionState.notStarted,
          ),
        )
        .toList(growable: false),
  );
}

Finder _editableTextWithValue(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is EditableText && widget.controller.text == value,
    description: 'EditableText with value "$value"',
  );
}

Future<void> _enterKeyedText(WidgetTester tester, Key key, String value) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.enterText(finder, value);
  await tester.pump(const Duration(milliseconds: 50));
}

class _TrackingWorkspaceController extends AppWorkspaceController {
  _TrackingWorkspaceController({required super.repository});

  Completer<InspectionRecord>? _saveCompleter;

  Future<InspectionRecord> get nextSavedInspection {
    _saveCompleter = Completer<InspectionRecord>();
    return _saveCompleter!.future;
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<InspectionSummary> saveInspectionRecord(
    InspectionRecord inspection,
  ) async {
    final saved = inspection.clone();
    _saveCompleter?.complete(saved);
    _saveCompleter = null;
    return _summaryFor(saved);
  }

  @override
  Future<InspectionRecord?> inspectionRecordById(String id) async {
    return null;
  }
}

class _FailingWorkspaceController extends AppWorkspaceController {
  _FailingWorkspaceController({required super.repository});

  @override
  Future<void> refresh() async {}

  @override
  Future<InspectionSummary> saveInspectionRecord(
    InspectionRecord inspection,
  ) async {
    throw StateError('Injected storage failure.');
  }
}

class _FailingCreateWorkspaceController extends AppWorkspaceController {
  _FailingCreateWorkspaceController({required super.repository});

  int createAttempts = 0;

  @override
  Future<void> refresh() async {}

  @override
  Future<InspectionRecord> createInspectionRecord({DateTime? createdAt}) {
    createAttempts += 1;
    throw StateError('Injected database initialization failure.');
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
