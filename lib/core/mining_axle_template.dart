import 'constants.dart';

enum MiningAxleResponseRule {
  purpose,
  condition,
  defect,
  acceptable,
  operational,
  text,
  number,
  checkbox,
  healthScore,
  reliabilityRisk,
  overallCondition,
}

class MiningAxleSection {
  const MiningAxleSection({
    required this.key,
    required this.title,
    required this.sortOrder,
  });

  final String key;
  final String title;
  final int sortOrder;
}

class MiningAxleItem {
  const MiningAxleItem({
    required this.sectionKey,
    required this.itemKey,
    required this.label,
    required this.rule,
    this.required = false,
    this.autoActionTitle,
  });

  final String sectionKey;
  final String itemKey;
  final String label;
  final MiningAxleResponseRule rule;
  final bool required;
  final String? autoActionTitle;
}

class MiningAxleTemplate {
  const MiningAxleTemplate._();

  static const String templateKey = AppConstants.templateKey;
  static const String templateVersion = AppConstants.templateVersion;

  static const String inspectionPurpose = 'inspection_purpose';
  static const String visualInspection = 'visual_inspection';
  static const String lubricationAssessment = 'lubrication_assessment';
  static const String differentialInspection = 'differential_inspection';
  static const String planetaryHubInspection = 'planetary_hub_inspection';
  static const String mechanicalMeasurementsSection = 'mechanical_measurements';
  static const String temperatureAssessment = 'temperature_assessment';
  static const String conditionMonitoringFindingsSection =
      'condition_monitoring_findings';
  static const String recommendations = 'recommendations';
  static const String overallHealth = 'overall_axle_health_assessment';

  static const String fair = 'Fair';
  static const String poor = 'Poor';
  static const String yes = 'Yes';
  static const String notInspected = 'Not Inspected';
  static const String notAcceptable = 'Not Acceptable';
  static const String notOperational = 'Not Operational';

  static const List<MiningAxleSection> sections = <MiningAxleSection>[
    MiningAxleSection(
      key: inspectionPurpose,
      title: 'Inspection Purpose',
      sortOrder: 0,
    ),
    MiningAxleSection(
      key: visualInspection,
      title: 'Visual Inspection',
      sortOrder: 1,
    ),
    MiningAxleSection(
      key: lubricationAssessment,
      title: 'Lubrication Assessment',
      sortOrder: 2,
    ),
    MiningAxleSection(
      key: differentialInspection,
      title: 'Differential Inspection',
      sortOrder: 3,
    ),
    MiningAxleSection(
      key: planetaryHubInspection,
      title: 'Planetary Hub Inspection',
      sortOrder: 4,
    ),
    MiningAxleSection(
      key: mechanicalMeasurementsSection,
      title: 'Mechanical Measurements',
      sortOrder: 5,
    ),
    MiningAxleSection(
      key: temperatureAssessment,
      title: 'Temperature Assessment',
      sortOrder: 6,
    ),
    MiningAxleSection(
      key: conditionMonitoringFindingsSection,
      title: 'Condition Monitoring Findings',
      sortOrder: 7,
    ),
    MiningAxleSection(
      key: recommendations,
      title: 'Recommendations',
      sortOrder: 8,
    ),
    MiningAxleSection(
      key: overallHealth,
      title: 'Overall Axle Health Assessment',
      sortOrder: 9,
    ),
  ];

  static const List<String> requiredHeaderFields = <String>[
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
  ];

  static const List<String> conditionOptions = <String>[
    'Good',
    fair,
    poor,
    'N/A',
    notInspected,
  ];

  static const List<String> defectOptions = <String>[
    yes,
    'No',
    'N/A',
    notInspected,
  ];

  static const List<String> acceptableOptions = <String>[
    'Acceptable',
    notAcceptable,
    'N/A',
    notInspected,
  ];

  static const List<String> operationalOptions = <String>[
    'Operational',
    notOperational,
    'N/A',
    notInspected,
  ];

  static const List<String> actionPriorities = <String>[
    'Priority 1 Immediate',
    'Priority 2 Schedule Repair',
    'Priority 3 Monitor',
  ];

  static const List<MiningAxleItem> purposeItems = <MiningAxleItem>[
    MiningAxleItem(
      sectionKey: inspectionPurpose,
      itemKey: 'purpose_preventive_maintenance',
      label: 'Preventive Maintenance Inspection',
      rule: MiningAxleResponseRule.purpose,
    ),
    MiningAxleItem(
      sectionKey: inspectionPurpose,
      itemKey: 'purpose_condition_monitoring',
      label: 'Condition Monitoring Assessment',
      rule: MiningAxleResponseRule.purpose,
    ),
    MiningAxleItem(
      sectionKey: inspectionPurpose,
      itemKey: 'purpose_failure_investigation',
      label: 'Failure Investigation',
      rule: MiningAxleResponseRule.purpose,
    ),
    MiningAxleItem(
      sectionKey: inspectionPurpose,
      itemKey: 'purpose_pre_overhaul',
      label: 'Pre-Overhaul Assessment',
      rule: MiningAxleResponseRule.purpose,
    ),
    MiningAxleItem(
      sectionKey: inspectionPurpose,
      itemKey: 'purpose_warranty_evaluation',
      label: 'Warranty Evaluation',
      rule: MiningAxleResponseRule.purpose,
    ),
  ];

  static const List<MiningAxleItem> visualConditionItems = <MiningAxleItem>[
    MiningAxleItem(
      sectionKey: visualInspection,
      itemKey: 'axle_housing',
      label: 'Axle Housing',
      rule: MiningAxleResponseRule.condition,
    ),
    MiningAxleItem(
      sectionKey: visualInspection,
      itemKey: 'differential_housing',
      label: 'Differential Housing',
      rule: MiningAxleResponseRule.condition,
    ),
    MiningAxleItem(
      sectionKey: visualInspection,
      itemKey: 'planetary_hub_assemblies',
      label: 'Planetary Hub Assemblies',
      rule: MiningAxleResponseRule.condition,
    ),
    MiningAxleItem(
      sectionKey: visualInspection,
      itemKey: 'wheel_ends',
      label: 'Wheel Ends',
      rule: MiningAxleResponseRule.condition,
    ),
    MiningAxleItem(
      sectionKey: visualInspection,
      itemKey: 'mounting_points',
      label: 'Mounting Points',
      rule: MiningAxleResponseRule.condition,
    ),
    MiningAxleItem(
      sectionKey: visualInspection,
      itemKey: 'breathers',
      label: 'Breathers',
      rule: MiningAxleResponseRule.condition,
    ),
    MiningAxleItem(
      sectionKey: visualInspection,
      itemKey: 'fasteners_bolts',
      label: 'Fasteners & Bolts',
      rule: MiningAxleResponseRule.condition,
    ),
  ];

  static const List<MiningAxleItem> visualDefectItems = <MiningAxleItem>[
    MiningAxleItem(
      sectionKey: visualInspection,
      itemKey: 'oil_leaks',
      label: 'Oil Leaks',
      rule: MiningAxleResponseRule.defect,
      autoActionTitle: 'Oil leak correction required',
    ),
    MiningAxleItem(
      sectionKey: visualInspection,
      itemKey: 'external_damage',
      label: 'External Damage',
      rule: MiningAxleResponseRule.defect,
    ),
    MiningAxleItem(
      sectionKey: visualInspection,
      itemKey: 'corrosion',
      label: 'Corrosion',
      rule: MiningAxleResponseRule.defect,
    ),
  ];

  static const List<MiningAxleItem> lubricationItems = <MiningAxleItem>[
    MiningAxleItem(
      sectionKey: lubricationAssessment,
      itemKey: 'oil_level_correct',
      label: 'Oil Level Correct',
      rule: MiningAxleResponseRule.defect,
    ),
    MiningAxleItem(
      sectionKey: lubricationAssessment,
      itemKey: 'oil_condition',
      label: 'Oil Condition',
      rule: MiningAxleResponseRule.condition,
    ),
    MiningAxleItem(
      sectionKey: lubricationAssessment,
      itemKey: 'water_contamination',
      label: 'Water Contamination',
      rule: MiningAxleResponseRule.defect,
      autoActionTitle: 'Water contamination correction required',
    ),
    MiningAxleItem(
      sectionKey: lubricationAssessment,
      itemKey: 'metallic_debris_present',
      label: 'Metallic Debris Present',
      rule: MiningAxleResponseRule.defect,
      autoActionTitle: 'Metallic debris investigation required',
    ),
    MiningAxleItem(
      sectionKey: lubricationAssessment,
      itemKey: 'burnt_oil_odor',
      label: 'Burnt Oil Odor',
      rule: MiningAxleResponseRule.defect,
      autoActionTitle: 'Burnt oil odor investigation required',
    ),
    MiningAxleItem(
      sectionKey: lubricationAssessment,
      itemKey: 'oil_sampling_taken',
      label: 'Oil Sampling Taken',
      rule: MiningAxleResponseRule.defect,
    ),
    MiningAxleItem(
      sectionKey: lubricationAssessment,
      itemKey: 'sample_no',
      label: 'Sample No.',
      rule: MiningAxleResponseRule.text,
    ),
  ];

  static const List<String> oilAnalysisParameters = <String>[
    'ISO Cleanliness Code',
    'Water Content',
    'Iron (Fe)',
    'Copper (Cu)',
    'Silicon (Si)',
    'Viscosity',
  ];

  static const List<MiningAxleItem> differentialConditionItems =
      <MiningAxleItem>[
        MiningAxleItem(
          sectionKey: differentialInspection,
          itemKey: 'crown_wheel',
          label: 'Crown Wheel',
          rule: MiningAxleResponseRule.condition,
        ),
        MiningAxleItem(
          sectionKey: differentialInspection,
          itemKey: 'pinion_gear',
          label: 'Pinion Gear',
          rule: MiningAxleResponseRule.condition,
        ),
        MiningAxleItem(
          sectionKey: differentialInspection,
          itemKey: 'gear_tooth_wear',
          label: 'Gear Tooth Wear',
          rule: MiningAxleResponseRule.condition,
        ),
        MiningAxleItem(
          sectionKey: differentialInspection,
          itemKey: 'gear_tooth_pitting',
          label: 'Gear Tooth Pitting',
          rule: MiningAxleResponseRule.condition,
        ),
        MiningAxleItem(
          sectionKey: differentialInspection,
          itemKey: 'bearings',
          label: 'Bearings',
          rule: MiningAxleResponseRule.condition,
        ),
        MiningAxleItem(
          sectionKey: differentialInspection,
          itemKey: 'backlash_measurement',
          label: 'Backlash Measurement',
          rule: MiningAxleResponseRule.acceptable,
          autoActionTitle: 'Backlash measurement correction required',
        ),
        MiningAxleItem(
          sectionKey: differentialInspection,
          itemKey: 'differential_lock',
          label: 'Differential Lock',
          rule: MiningAxleResponseRule.operational,
          autoActionTitle: 'Differential lock repair required',
        ),
      ];

  static const List<MiningAxleItem> planetaryHubItems = <MiningAxleItem>[
    MiningAxleItem(
      sectionKey: planetaryHubInspection,
      itemKey: 'sun_gear',
      label: 'Sun Gear',
      rule: MiningAxleResponseRule.condition,
    ),
    MiningAxleItem(
      sectionKey: planetaryHubInspection,
      itemKey: 'planet_gears',
      label: 'Planet Gears',
      rule: MiningAxleResponseRule.condition,
    ),
    MiningAxleItem(
      sectionKey: planetaryHubInspection,
      itemKey: 'ring_gear',
      label: 'Ring Gear',
      rule: MiningAxleResponseRule.condition,
    ),
    MiningAxleItem(
      sectionKey: planetaryHubInspection,
      itemKey: 'planet_bearings',
      label: 'Planet Bearings',
      rule: MiningAxleResponseRule.condition,
    ),
    MiningAxleItem(
      sectionKey: planetaryHubInspection,
      itemKey: 'thrust_washers',
      label: 'Thrust Washers',
      rule: MiningAxleResponseRule.condition,
    ),
    MiningAxleItem(
      sectionKey: planetaryHubInspection,
      itemKey: 'hub_seals',
      label: 'Hub Seals',
      rule: MiningAxleResponseRule.condition,
      autoActionTitle: 'Hub seal correction required',
    ),
    MiningAxleItem(
      sectionKey: planetaryHubInspection,
      itemKey: 'wheel_bearings',
      label: 'Wheel Bearings',
      rule: MiningAxleResponseRule.condition,
    ),
  ];

  static const List<String> mechanicalMeasurements = <String>[
    'Crown Wheel Backlash',
    'Pinion Bearing Preload',
    'Wheel Bearing End Float',
    'Differential Bearing Preload',
    'Axle Shaft Runout',
  ];

  static const List<String> temperatureLocations = <String>[
    'Left Planetary Hub',
    'Right Planetary Hub',
    'Differential Housing',
    'Pinion Housing',
  ];

  static const List<MiningAxleItem> conditionMonitoringFindings =
      <MiningAxleItem>[
        MiningAxleItem(
          sectionKey: conditionMonitoringFindingsSection,
          itemKey: 'finding_excessive_bearing_wear',
          label: 'Excessive Bearing Wear',
          rule: MiningAxleResponseRule.checkbox,
        ),
        MiningAxleItem(
          sectionKey: conditionMonitoringFindingsSection,
          itemKey: 'finding_gear_tooth_damage',
          label: 'Gear Tooth Damage',
          rule: MiningAxleResponseRule.checkbox,
        ),
        MiningAxleItem(
          sectionKey: conditionMonitoringFindingsSection,
          itemKey: 'finding_water_contamination',
          label: 'Water Contamination',
          rule: MiningAxleResponseRule.checkbox,
        ),
        MiningAxleItem(
          sectionKey: conditionMonitoringFindingsSection,
          itemKey: 'finding_oil_leakage',
          label: 'Oil Leakage',
          rule: MiningAxleResponseRule.checkbox,
        ),
        MiningAxleItem(
          sectionKey: conditionMonitoringFindingsSection,
          itemKey: 'finding_excessive_temperature',
          label: 'Excessive Temperature',
          rule: MiningAxleResponseRule.checkbox,
        ),
        MiningAxleItem(
          sectionKey: conditionMonitoringFindingsSection,
          itemKey: 'finding_excessive_backlash',
          label: 'Excessive Backlash',
          rule: MiningAxleResponseRule.checkbox,
        ),
        MiningAxleItem(
          sectionKey: conditionMonitoringFindingsSection,
          itemKey: 'finding_seal_failure',
          label: 'Seal Failure',
          rule: MiningAxleResponseRule.checkbox,
        ),
        MiningAxleItem(
          sectionKey: conditionMonitoringFindingsSection,
          itemKey: 'finding_axle_housing_damage',
          label: 'Axle Housing Damage',
          rule: MiningAxleResponseRule.checkbox,
        ),
        MiningAxleItem(
          sectionKey: conditionMonitoringFindingsSection,
          itemKey: 'finding_other',
          label: 'Other',
          rule: MiningAxleResponseRule.checkbox,
        ),
      ];

  static const List<String> recommendationBuckets = <String>[
    'Priority 1 — Immediate Action Required',
    'Priority 2 — Schedule Repair',
    'Priority 3 — Monitor',
  ];

  static const List<String> healthFields = <String>[
    'Mechanical Condition',
    'Lubrication Condition',
    'Contamination Control',
    'Reliability Risk',
    'Overall Condition',
  ];

  static const List<String> reliabilityRiskOptions = <String>[
    'Low',
    'Medium',
    'High',
  ];

  static const List<String> overallConditionOptions = <String>[
    'Excellent',
    'Good',
    'Fair',
    'Poor',
  ];

  static List<MiningAxleItem> get allChecklistItems => <MiningAxleItem>[
    ...purposeItems,
    ...visualConditionItems,
    ...visualDefectItems,
    ...lubricationItems,
    ...differentialConditionItems,
    ...planetaryHubItems,
    ...conditionMonitoringFindings,
  ];

  static MiningAxleItem? itemByKey(String sectionKey, String itemKey) {
    for (final item in allChecklistItems) {
      if (item.sectionKey == sectionKey && item.itemKey == itemKey) {
        return item;
      }
    }
    return null;
  }

  static String sectionTitleFor(String key) {
    return sections
        .firstWhere(
          (section) => section.key == key,
          orElse: () => const MiningAxleSection(
            key: 'unknown',
            title: 'Unknown',
            sortOrder: 999,
          ),
        )
        .title;
  }

  static bool isTruthy(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == 'true' || normalized == 'yes' || normalized == '1';
  }
}
