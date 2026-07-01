import 'package:cts_mining_axle_inspection/core/constants.dart';
import 'package:cts_mining_axle_inspection/core/mining_axle_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declares the standalone mining axle template identity', () {
    expect(AppConstants.appName, 'CTS Mining Axle Inspection');
    expect(AppConstants.templateKey, 'mining_axle_inspection');
    expect(AppConstants.templateVersion, '1.0.0');
    expect(MiningAxleTemplate.templateKey, AppConstants.templateKey);
    expect(MiningAxleTemplate.templateVersion, AppConstants.templateVersion);
  });

  test('contains the required ten mining axle report sections in order', () {
    expect(
      MiningAxleTemplate.sections.map((section) => section.title),
      const <String>[
        'Inspection Purpose',
        'Visual Inspection',
        'Lubrication Assessment',
        'Differential Inspection',
        'Planetary Hub Inspection',
        'Mechanical Measurements',
        'Temperature Assessment',
        'Condition Monitoring Findings',
        'Recommendations',
        'Overall Axle Health Assessment',
      ],
    );
    expect(
      MiningAxleTemplate.sections.map((section) => section.sortOrder),
      List<int>.generate(10, (index) => index),
    );
  });

  test('exposes fixed option sets exactly as specified', () {
    expect(MiningAxleTemplate.conditionOptions, const <String>[
      'Good',
      'Fair',
      'Poor',
      'N/A',
      'Not Inspected',
    ]);
    expect(MiningAxleTemplate.defectOptions, const <String>[
      'Yes',
      'No',
      'N/A',
      'Not Inspected',
    ]);
    expect(MiningAxleTemplate.acceptableOptions, const <String>[
      'Acceptable',
      'Not Acceptable',
      'N/A',
      'Not Inspected',
    ]);
    expect(MiningAxleTemplate.operationalOptions, const <String>[
      'Operational',
      'Not Operational',
      'N/A',
      'Not Inspected',
    ]);
    expect(MiningAxleTemplate.actionPriorities, const <String>[
      'Priority 1 Immediate',
      'Priority 2 Schedule Repair',
      'Priority 3 Monitor',
    ]);
  });

  test('covers header fields, purposes, rows, findings, and health fields', () {
    expect(
      MiningAxleTemplate.requiredHeaderFields,
      containsAll(<String>[
        'customer',
        'site',
        'equipmentMake',
        'equipmentModel',
        'machineSerialNumber',
        'axleManufacturer',
        'axleModel',
        'axleSerialNumber',
        'inspectionDate',
        'ctsInspector',
      ]),
    );
    expect(MiningAxleTemplate.purposeItems, hasLength(5));
    expect(MiningAxleTemplate.visualConditionItems, hasLength(7));
    expect(MiningAxleTemplate.visualDefectItems, hasLength(3));
    expect(MiningAxleTemplate.oilAnalysisParameters, hasLength(6));
    expect(MiningAxleTemplate.mechanicalMeasurements, hasLength(5));
    expect(MiningAxleTemplate.temperatureLocations, hasLength(4));
    expect(MiningAxleTemplate.conditionMonitoringFindings, hasLength(9));
    expect(MiningAxleTemplate.recommendationBuckets, hasLength(3));
    expect(MiningAxleTemplate.healthFields, const <String>[
      'Mechanical Condition',
      'Lubrication Condition',
      'Contamination Control',
      'Reliability Risk',
      'Overall Condition',
    ]);
  });
}
