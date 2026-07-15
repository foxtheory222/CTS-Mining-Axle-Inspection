import 'dart:io';

import 'package:cts_mining_axle_inspection/core/constants.dart';
import 'package:cts_mining_axle_inspection/core/mining_axle_template.dart';
import 'package:cts_mining_axle_inspection/data/database/app_database.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_enums.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

class TestAppDatabase extends AppDatabase {
  TestAppDatabase(this.directory);

  final Directory directory;
  Database? _database;
  Future<Database>? _openingDatabase;

  @override
  Future<Database> open() async {
    if (_database != null) {
      return _database!;
    }
    final opening = _openingDatabase;
    if (opening != null) {
      return opening;
    }

    final dbPath =
        '${directory.path}${Platform.pathSeparator}${AppConstants.databaseName}';
    _openingDatabase = databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: AppDatabase.schemaVersion,
        onCreate: AppDatabase.createSchema,
        onUpgrade: AppDatabase.upgradeSchema,
      ),
    );
    try {
      _database = await _openingDatabase;
      return _database!;
    } finally {
      _openingDatabase = null;
    }
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

InspectionRecord buildInspection({
  required String id,
  required String documentNumber,
  required InspectionStatus status,
  String customer = 'Acme Manufacturing',
  String workOrderNumber = 'WO-1001',
  String customerReference = 'PO-1001',
  String assetName = 'HPU-1',
  String hpuAssetIdName = 'HPU-1',
  String equipmentMake = 'Caterpillar',
  String equipmentModel = '793F',
  String machineSerialNumber = 'CAT793-1001',
  String axleManufacturer = 'Dana',
  String axleModel = 'Spicer 53R300',
  String axleSerialNumber = 'AXLE-1001',
  String hoursOnMachine = '18000',
  String purchaseOrderNumber = 'PO-1001',
  String relatedMachineReportDocumentNumber = '',
  String siteLocation = 'Plant 1',
  String technicianName = 'Jordan Lee',
  String servicingShop = 'CTS North Shop',
  DateTime? inspectionDateTime,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? completedAt,
  DateTime? emailedAt,
  String finalTechComments = '',
  String? signatureFilePath,
  String customerRepresentativeName = '',
  String? customerSignatureFilePath,
  DateTime? customerSignatureDate,
  String customerUnavailableNote = '',
  bool criticalAcknowledged = false,
  String? generatedPdfPath,
  String? restoredFromExportPath,
  List<InspectionResponse>? responses,
  List<InspectionPhoto>? photos,
  List<ActionItem>? actionItems,
  List<HoseEntry>? hoseEntries,
  List<ComponentEntry>? componentEntries,
  List<FilterEntry>? filterEntries,
}) {
  final now = createdAt ?? DateTime.utc(2026, 4, 20, 12, 0);
  return InspectionRecord(
    id: id,
    documentNumber: documentNumber,
    status: status,
    customer: customer,
    workOrderNumber: workOrderNumber,
    customerReference: customerReference,
    assetName: assetName,
    hpuAssetIdName: hpuAssetIdName,
    equipmentMake: equipmentMake,
    equipmentModel: equipmentModel,
    machineSerialNumber: machineSerialNumber,
    axleManufacturer: axleManufacturer,
    axleModel: axleModel,
    axleSerialNumber: axleSerialNumber,
    hoursOnMachine: hoursOnMachine,
    purchaseOrderNumber: purchaseOrderNumber,
    relatedMachineReportDocumentNumber: relatedMachineReportDocumentNumber,
    siteLocation: siteLocation,
    technicianName: technicianName,
    servicingShop: servicingShop,
    inspectionDateTime: inspectionDateTime ?? now,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
    completedAt: completedAt,
    emailedAt: emailedAt,
    finalTechComments: finalTechComments,
    signatureFilePath: signatureFilePath,
    customerRepresentativeName: customerRepresentativeName,
    customerSignatureFilePath: customerSignatureFilePath,
    customerSignatureDate: customerSignatureDate,
    customerUnavailableNote: customerUnavailableNote,
    criticalAcknowledged: criticalAcknowledged,
    generatedPdfPath: generatedPdfPath,
    restoredFromExportPath: restoredFromExportPath,
    sections: MiningAxleTemplate.sections
        .map(
          (descriptor) => InspectionSectionProgress(
            id: '${id}_${descriptor.key}',
            inspectionId: id,
            sectionKey: descriptor.key,
            title: descriptor.title,
            sortOrder: descriptor.sortOrder,
            completionState: SectionCompletionState.inProgress,
          ),
        )
        .toList(growable: false),
    responses: responses ?? <InspectionResponse>[],
    photos: photos ?? <InspectionPhoto>[],
    actionItems: actionItems ?? <ActionItem>[],
    hoseEntries: hoseEntries ?? <HoseEntry>[],
    componentEntries: componentEntries ?? <ComponentEntry>[],
    filterEntries: filterEntries ?? <FilterEntry>[],
    requiredItems: const <RequiredItemEntry>[],
  );
}

void fillRequiredResponses(
  InspectionRecord inspection, {
  bool critical = false,
}) {
  final now = DateTime.utc(2026, 4, 20, 12, 0);
  final responses = <InspectionResponse>[];

  void add(
    MiningAxleItem item,
    String value, {
    ConditionRating? conditionRating,
    bool isFlagged = false,
    String? comment,
  }) {
    responses.add(
      _response(
        inspection,
        item.sectionKey,
        item.itemKey,
        item.label,
        value: value,
        conditionRating: conditionRating,
        isFlagged: isFlagged,
        comment: comment,
        now: now,
      ),
    );
  }

  add(MiningAxleTemplate.purposeItems.first, 'true');
  for (final item in MiningAxleTemplate.visualConditionItems) {
    final isCriticalItem = critical && item.itemKey == 'axle_housing';
    add(
      item,
      isCriticalItem ? MiningAxleTemplate.poor : 'Good',
      conditionRating: isCriticalItem
          ? ConditionRating.criticalOutOfService
          : ConditionRating.satisfactory,
      isFlagged: isCriticalItem,
      comment: isCriticalItem ? 'Cracked housing.' : null,
    );
  }
  for (final item in MiningAxleTemplate.visualDefectItems) {
    add(item, 'No');
  }
  for (final item in MiningAxleTemplate.lubricationItems) {
    final value = switch (item.itemKey) {
      'oil_condition' => 'Good',
      'oil_sampling_taken' => MiningAxleTemplate.yes,
      'sample_no' => 'S-1001',
      _ => 'No',
    };
    add(
      item,
      value,
      conditionRating: item.itemKey == 'oil_condition'
          ? ConditionRating.satisfactory
          : null,
    );
  }
  for (final item in MiningAxleTemplate.differentialConditionItems) {
    final value = switch (item.rule) {
      MiningAxleResponseRule.acceptable => 'Acceptable',
      MiningAxleResponseRule.operational => 'Operational',
      _ => 'Good',
    };
    add(
      item,
      value,
      conditionRating: item.rule == MiningAxleResponseRule.condition
          ? ConditionRating.satisfactory
          : null,
    );
  }
  for (final item in MiningAxleTemplate.planetaryHubItems) {
    add(item, 'Good', conditionRating: ConditionRating.satisfactory);
  }
  for (final item in MiningAxleTemplate.conditionMonitoringFindings) {
    add(item, 'false');
  }

  responses.addAll(<InspectionResponse>[
    _response(
      inspection,
      MiningAxleTemplate.conditionMonitoringFindingsSection,
      'condition_monitoring_details',
      'Condition Monitoring Details',
      value: 'No abnormal findings.',
      now: now,
    ),
    _response(
      inspection,
      MiningAxleTemplate.overallHealth,
      'health_mechanical_condition',
      'Mechanical Condition',
      value: '9',
      now: now,
    ),
    _response(
      inspection,
      MiningAxleTemplate.overallHealth,
      'health_lubrication_condition',
      'Lubrication Condition',
      value: '8',
      now: now,
    ),
    _response(
      inspection,
      MiningAxleTemplate.overallHealth,
      'health_contamination_control',
      'Contamination Control',
      value: '8',
      now: now,
    ),
    _response(
      inspection,
      MiningAxleTemplate.overallHealth,
      'health_reliability_risk',
      'Reliability Risk',
      value: 'Low',
      now: now,
    ),
    _response(
      inspection,
      MiningAxleTemplate.overallHealth,
      'health_overall_condition',
      'Overall Condition',
      value: critical ? 'Poor' : 'Good',
      conditionRating: critical ? ConditionRating.criticalOutOfService : null,
      now: now,
    ),
  ]);
  inspection.responses = responses;

  if (inspection.recommendationRows.isEmpty) {
    inspection.recommendationRows.add(
      RecommendationRow(
        priority: 'Priority 3 Monitor',
        recommendation: 'Continue routine monitoring.',
      ),
    );
  }

  if (critical) {
    inspection.criticalAcknowledged = false;
    inspection.photos.add(
      InspectionPhoto(
        id: const Uuid().v4(),
        inspectionId: inspection.id,
        sectionKey: MiningAxleTemplate.visualInspection,
        itemKey: 'axle_housing',
        filePath: '/tmp/axle_housing.jpg',
        caption: 'Cracked housing.',
        sortOrder: 0,
        capturedAt: now,
        createdAt: now,
      ),
    );
    inspection.actionItems.add(
      ActionItem(
        id: const Uuid().v4(),
        inspectionId: inspection.id,
        sourceSectionKey: MiningAxleTemplate.visualInspection,
        sourceItemKey: 'axle_housing',
        conditionRating: ConditionRating.criticalOutOfService,
        title: 'Axle housing repair required',
        description: 'Remove axle from service and repair cracked housing.',
        isAutoGenerated: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

InspectionResponse _response(
  InspectionRecord inspection,
  String sectionKey,
  String itemKey,
  String itemLabel, {
  required String value,
  ConditionRating? conditionRating,
  bool isFlagged = false,
  String? comment,
  required DateTime now,
}) {
  return InspectionResponse(
    id: const Uuid().v4(),
    inspectionId: inspection.id,
    sectionKey: sectionKey,
    itemKey: itemKey,
    itemLabel: itemLabel,
    fieldType: InspectionFieldType.dropdown,
    value: value,
    conditionRating: conditionRating,
    isFlagged: isFlagged,
    comment: comment,
    createdAt: now,
    updatedAt: now,
  );
}
