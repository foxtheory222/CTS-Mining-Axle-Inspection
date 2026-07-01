import 'package:cts_mining_axle_inspection/core/constants.dart';
import 'package:cts_mining_axle_inspection/core/mining_axle_template.dart';
import 'package:cts_mining_axle_inspection/core/validators.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_enums.dart';
import 'package:cts_mining_axle_inspection/data/models/inspection_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import '../support/persistence_test_helpers.dart';

void main() {
  test(
    'completion passes when all required mining axle fields are present',
    () {
      final inspection = _completeMiningInspection();

      final result = InspectionValidator.validateForCompletion(inspection);

      expect(result.isValid, isTrue);
    },
  );

  test('required mining axle header fields are enforced', () {
    final inspection = _completeMiningInspection(axleSerialNumber: '');

    final result = InspectionValidator.validateForCompletion(inspection);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.message),
      contains('Axle Serial Number is required.'),
    );
  });

  test('at least one inspection purpose is required', () {
    final inspection = _completeMiningInspection(includePurpose: false);

    final result = InspectionValidator.validateForCompletion(inspection);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.message),
      contains('At least one inspection purpose is required.'),
    );
  });

  test('oil sampling taken requires sample number', () {
    final inspection = _completeMiningInspection();
    _upsert(
      inspection,
      MiningAxleTemplate.lubricationAssessment,
      'oil_sampling_taken',
      'Oil Sampling Taken',
      'Yes',
    );
    _removeResponse(inspection, 'sample_no');

    final result = InspectionValidator.validateForCompletion(inspection);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.message),
      contains('Sample No. is required when Oil Sampling Taken is Yes.'),
    );
  });

  test('Fair and Not Inspected rows require comments', () {
    final inspection = _completeMiningInspection();
    _upsert(
      inspection,
      MiningAxleTemplate.visualInspection,
      'axle_housing',
      'Axle Housing',
      'Fair',
      comment: '',
    );
    _upsert(
      inspection,
      MiningAxleTemplate.planetaryHubInspection,
      'sun_gear',
      'Sun Gear',
      'Not Inspected',
      comment: '',
    );

    final result = InspectionValidator.validateForCompletion(inspection);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.message),
      contains('Axle Housing requires a comment.'),
    );
    expect(
      result.issues.map((issue) => issue.message),
      contains('Sun Gear requires a comment.'),
    );
  });

  test(
    'Poor, defect Yes, Not Acceptable, and Not Operational require evidence',
    () {
      final inspection = _completeMiningInspection();
      _upsert(
        inspection,
        MiningAxleTemplate.visualInspection,
        'oil_leaks',
        'Oil Leaks',
        'Yes',
        comment: '',
      );
      _upsert(
        inspection,
        MiningAxleTemplate.differentialInspection,
        'backlash_measurement',
        'Backlash Measurement',
        'Not Acceptable',
        comment: '',
      );
      _upsert(
        inspection,
        MiningAxleTemplate.differentialInspection,
        'differential_lock',
        'Differential Lock',
        'Not Operational',
        comment: '',
      );
      _upsert(
        inspection,
        MiningAxleTemplate.planetaryHubInspection,
        'wheel_bearings',
        'Wheel Bearings',
        'Poor',
        comment: '',
      );

      final result = InspectionValidator.validateForCompletion(inspection);

      expect(result.isValid, isFalse);
      expect(
        result.issues.map((issue) => issue.message),
        containsAll(<String>[
          'Oil Leaks requires a comment.',
          'Oil Leaks requires at least one photo.',
          'Oil Leaks requires a linked action item.',
          'Backlash Measurement requires a comment.',
          'Differential Lock requires a comment.',
          'Wheel Bearings requires a comment.',
        ]),
      );
    },
  );

  test('critical rows require acknowledgement in addition to evidence', () {
    final inspection = _completeMiningInspection();
    _upsert(
      inspection,
      MiningAxleTemplate.visualInspection,
      'axle_housing',
      'Axle Housing',
      'Poor',
      conditionRating: ConditionRating.criticalOutOfService,
      comment: 'Cracked housing.',
    );
    _addPhoto(inspection, MiningAxleTemplate.visualInspection, 'axle_housing');
    _addAction(
      inspection,
      MiningAxleTemplate.visualInspection,
      'axle_housing',
      ConditionRating.criticalOutOfService,
    );
    inspection.criticalAcknowledged = false;

    final result = InspectionValidator.validateForCompletion(inspection);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.message),
      contains(AppConstants.lotOWarning),
    );
  });

  test('abnormal findings require details and recommendations or actions', () {
    final inspection = _completeMiningInspection(includeRecommendations: false);
    _upsert(
      inspection,
      MiningAxleTemplate.conditionMonitoringFindingsSection,
      'finding_oil_leakage',
      'Oil Leakage',
      'true',
    );
    _removeResponse(inspection, 'condition_monitoring_details');

    final result = InspectionValidator.validateForCompletion(inspection);

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.message),
      contains(
        'Condition monitoring details are required when abnormal findings are selected.',
      ),
    );
    expect(
      result.issues.map((issue) => issue.message),
      contains(
        'At least one recommendation or action item is required for Fair/Poor overall condition or abnormal findings.',
      ),
    );
  });

  test(
    'health scores, reliability risk, and overall condition are required',
    () {
      final inspection = _completeMiningInspection();
      _removeResponse(inspection, 'health_mechanical_condition');
      _removeResponse(inspection, 'health_reliability_risk');
      _removeResponse(inspection, 'health_overall_condition');

      final result = InspectionValidator.validateForCompletion(inspection);

      expect(result.isValid, isFalse);
      expect(
        result.issues.map((issue) => issue.message),
        containsAll(<String>[
          'Mechanical Condition score is required.',
          'Reliability Risk is required.',
          'Overall Condition is required.',
        ]),
      );
    },
  );
}

InspectionRecord _completeMiningInspection({
  String axleSerialNumber = 'AX-1001',
  bool includePurpose = true,
  bool includeRecommendations = true,
}) {
  final inspection = buildInspection(
    id: 'inspection-${const Uuid().v4()}',
    documentNumber: '20260701-0001',
    status: InspectionStatus.inProgress,
    customer: 'Moraine Quarry',
    siteLocation: 'East Pit',
    equipmentMake: 'Caterpillar',
    equipmentModel: '793F',
    machineSerialNumber: 'CAT793-1001',
    axleManufacturer: 'Dana',
    axleModel: 'Spicer 53R300',
    axleSerialNumber: axleSerialNumber,
    technicianName: 'R. Ellis',
    signatureFilePath: '/tmp/inspector-signature.png',
  );
  if (includePurpose) {
    _upsert(
      inspection,
      MiningAxleTemplate.inspectionPurpose,
      'purpose_preventive_maintenance',
      'Preventive Maintenance Inspection',
      'true',
    );
  }
  for (final item in <MiningAxleItem>[
    ...MiningAxleTemplate.visualConditionItems,
    ...MiningAxleTemplate.planetaryHubItems,
    ...MiningAxleTemplate.differentialConditionItems.where(
      (item) => item.rule == MiningAxleResponseRule.condition,
    ),
  ]) {
    _upsert(inspection, item.sectionKey, item.itemKey, item.label, 'Good');
  }
  for (final item in <MiningAxleItem>[
    ...MiningAxleTemplate.visualDefectItems,
    ...MiningAxleTemplate.lubricationItems.where(
      (item) => item.rule == MiningAxleResponseRule.defect,
    ),
  ]) {
    _upsert(inspection, item.sectionKey, item.itemKey, item.label, 'No');
  }
  _upsert(
    inspection,
    MiningAxleTemplate.lubricationAssessment,
    'oil_condition',
    'Oil Condition',
    'Good',
  );
  _upsert(
    inspection,
    MiningAxleTemplate.lubricationAssessment,
    'sample_no',
    'Sample No.',
    'S-1001',
  );
  _upsert(
    inspection,
    MiningAxleTemplate.differentialInspection,
    'backlash_measurement',
    'Backlash Measurement',
    'Acceptable',
  );
  _upsert(
    inspection,
    MiningAxleTemplate.differentialInspection,
    'differential_lock',
    'Differential Lock',
    'Operational',
  );
  _upsert(
    inspection,
    MiningAxleTemplate.conditionMonitoringFindingsSection,
    'condition_monitoring_details',
    'Condition Monitoring Details',
    'No abnormal findings.',
  );
  _upsert(
    inspection,
    MiningAxleTemplate.overallHealth,
    'health_mechanical_condition',
    'Mechanical Condition',
    '9',
  );
  _upsert(
    inspection,
    MiningAxleTemplate.overallHealth,
    'health_lubrication_condition',
    'Lubrication Condition',
    '8',
  );
  _upsert(
    inspection,
    MiningAxleTemplate.overallHealth,
    'health_contamination_control',
    'Contamination Control',
    '8',
  );
  _upsert(
    inspection,
    MiningAxleTemplate.overallHealth,
    'health_reliability_risk',
    'Reliability Risk',
    'Low',
  );
  _upsert(
    inspection,
    MiningAxleTemplate.overallHealth,
    'health_overall_condition',
    'Overall Condition',
    includeRecommendations ? 'Good' : 'Poor',
  );
  if (includeRecommendations) {
    inspection.recommendationRows.add(
      RecommendationRow(
        priority: 'Priority 3 Monitor',
        recommendation: 'Continue routine monitoring.',
      ),
    );
  }
  return inspection;
}

void _upsert(
  InspectionRecord inspection,
  String sectionKey,
  String itemKey,
  String itemLabel,
  String value, {
  ConditionRating? conditionRating,
  String? comment,
}) {
  _removeResponse(inspection, itemKey);
  final now = DateTime.utc(2026, 7, 1, 12);
  inspection.responses.add(
    InspectionResponse(
      id: const Uuid().v4(),
      inspectionId: inspection.id,
      sectionKey: sectionKey,
      itemKey: itemKey,
      itemLabel: itemLabel,
      fieldType: InspectionFieldType.dropdown,
      value: value,
      conditionRating: conditionRating,
      comment: comment,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

void _removeResponse(InspectionRecord inspection, String itemKey) {
  inspection.responses.removeWhere((response) => response.itemKey == itemKey);
}

void _addPhoto(InspectionRecord inspection, String sectionKey, String itemKey) {
  inspection.photos.add(
    InspectionPhoto(
      id: const Uuid().v4(),
      inspectionId: inspection.id,
      sectionKey: sectionKey,
      itemKey: itemKey,
      filePath: '/tmp/$itemKey.jpg',
      caption: itemKey,
      sortOrder: 0,
      capturedAt: DateTime.utc(2026, 7, 1, 12),
      createdAt: DateTime.utc(2026, 7, 1, 12),
    ),
  );
}

void _addAction(
  InspectionRecord inspection,
  String sectionKey,
  String itemKey,
  ConditionRating? conditionRating,
) {
  inspection.actionItems.add(
    ActionItem(
      id: const Uuid().v4(),
      inspectionId: inspection.id,
      sourceSectionKey: sectionKey,
      sourceItemKey: itemKey,
      conditionRating: conditionRating,
      title: '$itemKey action',
      description: 'Correct $itemKey.',
      isAutoGenerated: true,
      createdAt: DateTime.utc(2026, 7, 1, 12),
      updatedAt: DateTime.utc(2026, 7, 1, 12),
    ),
  );
}
