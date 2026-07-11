import '../data/models/inspection_enums.dart';
import '../data/models/inspection_models.dart';
import 'constants.dart';
import 'mining_axle_template.dart';

class ValidationIssue {
  const ValidationIssue({
    required this.sectionKey,
    this.itemKey,
    required this.message,
    this.severity = ValidationSeverity.error,
  });

  final String sectionKey;
  final String? itemKey;
  final String message;
  final ValidationSeverity severity;
}

class ValidationResult {
  const ValidationResult(this.issues);

  final List<ValidationIssue> issues;

  bool get isValid => issues.isEmpty;
}

class InspectionValidator {
  static const String conditionMonitoringDetailsKey =
      'condition_monitoring_details';
  static const String healthMechanicalConditionKey =
      'health_mechanical_condition';
  static const String healthLubricationConditionKey =
      'health_lubrication_condition';
  static const String healthContaminationControlKey =
      'health_contamination_control';
  static const String healthReliabilityRiskKey = 'health_reliability_risk';
  static const String healthOverallConditionKey = 'health_overall_condition';

  static ValidationResult validateForCompletion(InspectionRecord inspection) {
    final issues = <ValidationIssue>[];

    void requireHeader(String value, String message) {
      if (value.trim().isEmpty) {
        issues.add(
          ValidationIssue(
            sectionKey: MiningAxleTemplate.inspectionPurpose,
            message: message,
          ),
        );
      }
    }

    requireHeader(inspection.customer, 'Customer is required.');
    requireHeader(inspection.siteLocation, 'Site is required.');
    requireHeader(inspection.equipmentMake, 'Equipment Make is required.');
    requireHeader(inspection.equipmentModel, 'Equipment Model is required.');
    requireHeader(
      inspection.machineSerialNumber,
      'Machine Serial No. is required.',
    );
    requireHeader(
      inspection.axleManufacturer,
      'Axle Manufacturer is required.',
    );
    requireHeader(inspection.axleModel, 'Axle Model is required.');
    requireHeader(
      inspection.axleSerialNumber,
      'Axle Serial Number is required.',
    );
    requireHeader(inspection.technicianName, 'CTS Inspector is required.');

    if (!_hasSelectedPurpose(inspection)) {
      issues.add(
        const ValidationIssue(
          sectionKey: MiningAxleTemplate.inspectionPurpose,
          message: 'At least one inspection purpose is required.',
        ),
      );
    }

    _validateRequiredSelections(inspection, issues);
    _validateChecklistResponses(inspection, issues);
    _validateOilSample(inspection, issues);
    final hasAbnormalFindings = _hasAbnormalFindings(inspection);
    _validateFindings(inspection, issues, hasAbnormalFindings);
    _validateHealth(inspection, issues);
    _validateRecommendations(inspection, issues, hasAbnormalFindings);

    if (inspection.hasCriticalItems && !inspection.criticalAcknowledged) {
      issues.add(
        const ValidationIssue(
          sectionKey: MiningAxleTemplate.overallHealth,
          itemKey: 'critical_acknowledgement',
          message: AppConstants.lotOWarning,
        ),
      );
    }

    if ((inspection.signatureFilePath ?? '').trim().isEmpty) {
      issues.add(
        const ValidationIssue(
          sectionKey: MiningAxleTemplate.overallHealth,
          itemKey: 'inspector_signature',
          message: 'Inspector signature is required.',
        ),
      );
    }

    return ValidationResult(issues);
  }

  static InspectionStatus deriveStatus(InspectionRecord inspection) {
    if (inspection.emailedAt != null) {
      return InspectionStatus.emailed;
    }
    final ValidationResult result = validateForCompletion(inspection);
    if (result.isValid && inspection.completedAt != null) {
      return InspectionStatus.complete;
    }
    if (_hasMeaningfulProgress(inspection)) {
      return InspectionStatus.inProgress;
    }
    return InspectionStatus.draft;
  }

  static bool _hasSelectedPurpose(InspectionRecord inspection) {
    final purposeKeys = MiningAxleTemplate.purposeItems
        .map((item) => item.itemKey)
        .toSet();
    return inspection.responses.any((response) {
      return response.sectionKey == MiningAxleTemplate.inspectionPurpose &&
          purposeKeys.contains(response.itemKey) &&
          MiningAxleTemplate.isTruthy(response.value);
    });
  }

  static void _validateRequiredSelections(
    InspectionRecord inspection,
    List<ValidationIssue> issues,
  ) {
    for (final item in MiningAxleTemplate.allChecklistItems) {
      final options = switch (item.rule) {
        MiningAxleResponseRule.condition => MiningAxleTemplate.conditionOptions,
        MiningAxleResponseRule.defect => MiningAxleTemplate.defectOptions,
        MiningAxleResponseRule.acceptable =>
          MiningAxleTemplate.acceptableOptions,
        MiningAxleResponseRule.operational =>
          MiningAxleTemplate.operationalOptions,
        _ => null,
      };
      if (options == null) {
        continue;
      }
      final value = inspection
          .responseByKey(item.sectionKey, item.itemKey)
          ?.value
          ?.trim();
      if (value == null || !options.contains(value)) {
        issues.add(
          ValidationIssue(
            sectionKey: item.sectionKey,
            itemKey: item.itemKey,
            message: '${item.label} selection is required.',
          ),
        );
      }
    }
  }

  static void _validateChecklistResponses(
    InspectionRecord inspection,
    List<ValidationIssue> issues,
  ) {
    for (final response in inspection.responses) {
      final item = MiningAxleTemplate.itemByKey(
        response.sectionKey,
        response.itemKey,
      );
      if (item == null) {
        continue;
      }
      final value = (response.value ?? '').trim();
      final critical =
          response.conditionRating == ConditionRating.criticalOutOfService;
      final needsComment =
          critical ||
          value == MiningAxleTemplate.fair ||
          value == MiningAxleTemplate.notInspected ||
          _requiresEvidence(item, value);
      final needsEvidence = critical || _requiresEvidence(item, value);

      if (needsComment && (response.comment ?? '').trim().isEmpty) {
        issues.add(
          ValidationIssue(
            sectionKey: response.sectionKey,
            itemKey: response.itemKey,
            message: '${response.itemLabel} requires a comment.',
          ),
        );
      }

      if (!needsEvidence) {
        continue;
      }
      if (_photosForResponse(inspection, response).isEmpty) {
        issues.add(
          ValidationIssue(
            sectionKey: response.sectionKey,
            itemKey: response.itemKey,
            message: '${response.itemLabel} requires at least one photo.',
          ),
        );
      }
      if (!_hasActionForResponse(inspection, response)) {
        issues.add(
          ValidationIssue(
            sectionKey: response.sectionKey,
            itemKey: response.itemKey,
            message: '${response.itemLabel} requires a linked action item.',
          ),
        );
      }
    }
  }

  static bool _requiresEvidence(MiningAxleItem item, String value) {
    return switch (item.rule) {
      MiningAxleResponseRule.condition => value == MiningAxleTemplate.poor,
      MiningAxleResponseRule.defect =>
        value == MiningAxleTemplate.yes && item.itemKey != 'oil_sampling_taken',
      MiningAxleResponseRule.acceptable =>
        value == MiningAxleTemplate.notAcceptable,
      MiningAxleResponseRule.operational =>
        value == MiningAxleTemplate.notOperational,
      _ => false,
    };
  }

  static List<InspectionPhoto> _photosForResponse(
    InspectionRecord inspection,
    InspectionResponse response,
  ) {
    return inspection.photos
        .where(
          (photo) =>
              photo.sectionKey == response.sectionKey &&
              photo.itemKey == response.itemKey,
        )
        .toList(growable: false);
  }

  static bool _hasActionForResponse(
    InspectionRecord inspection,
    InspectionResponse response,
  ) {
    return inspection.actionItems.any(
      (actionItem) =>
          actionItem.sourceSectionKey == response.sectionKey &&
          actionItem.sourceItemKey == response.itemKey,
    );
  }

  static void _validateOilSample(
    InspectionRecord inspection,
    List<ValidationIssue> issues,
  ) {
    final samplingTaken = inspection.responseByKey(
      MiningAxleTemplate.lubricationAssessment,
      'oil_sampling_taken',
    );
    if ((samplingTaken?.value ?? '') != MiningAxleTemplate.yes) {
      return;
    }
    final sampleNumber = inspection.responseByKey(
      MiningAxleTemplate.lubricationAssessment,
      'sample_no',
    );
    if ((sampleNumber?.value ?? '').trim().isEmpty) {
      issues.add(
        const ValidationIssue(
          sectionKey: MiningAxleTemplate.lubricationAssessment,
          itemKey: 'sample_no',
          message: 'Sample No. is required when Oil Sampling Taken is Yes.',
        ),
      );
    }
  }

  static bool _hasAbnormalFindings(InspectionRecord inspection) {
    final findingKeys = MiningAxleTemplate.conditionMonitoringFindings
        .map((item) => item.itemKey)
        .toSet();
    return inspection.responses.any(
      (response) =>
          response.sectionKey ==
              MiningAxleTemplate.conditionMonitoringFindingsSection &&
          findingKeys.contains(response.itemKey) &&
          MiningAxleTemplate.isTruthy(response.value),
    );
  }

  static void _validateFindings(
    InspectionRecord inspection,
    List<ValidationIssue> issues,
    bool hasAbnormalFindings,
  ) {
    if (!hasAbnormalFindings) {
      return;
    }
    final details = inspection.responseByKey(
      MiningAxleTemplate.conditionMonitoringFindingsSection,
      conditionMonitoringDetailsKey,
    );
    if ((details?.value ?? '').trim().isEmpty) {
      issues.add(
        const ValidationIssue(
          sectionKey: MiningAxleTemplate.conditionMonitoringFindingsSection,
          itemKey: conditionMonitoringDetailsKey,
          message:
              'Condition monitoring details are required when abnormal findings are selected.',
        ),
      );
    }
  }

  static void _validateHealth(
    InspectionRecord inspection,
    List<ValidationIssue> issues,
  ) {
    _requireScore(
      inspection,
      issues,
      key: healthMechanicalConditionKey,
      label: 'Mechanical Condition',
    );
    _requireScore(
      inspection,
      issues,
      key: healthLubricationConditionKey,
      label: 'Lubrication Condition',
    );
    _requireScore(
      inspection,
      issues,
      key: healthContaminationControlKey,
      label: 'Contamination Control',
    );
    _requireOption(
      inspection,
      issues,
      key: healthReliabilityRiskKey,
      label: 'Reliability Risk',
      options: MiningAxleTemplate.reliabilityRiskOptions,
    );
    _requireOption(
      inspection,
      issues,
      key: healthOverallConditionKey,
      label: 'Overall Condition',
      options: MiningAxleTemplate.overallConditionOptions,
    );
  }

  static void _requireScore(
    InspectionRecord inspection,
    List<ValidationIssue> issues, {
    required String key,
    required String label,
  }) {
    final response = inspection.responseByKey(
      MiningAxleTemplate.overallHealth,
      key,
    );
    final value = (response?.value ?? '').trim();
    final score = num.tryParse(value);
    if (score == null || score < 0 || score > 10) {
      issues.add(
        ValidationIssue(
          sectionKey: MiningAxleTemplate.overallHealth,
          itemKey: key,
          message: '$label score is required.',
        ),
      );
    }
  }

  static void _requireOption(
    InspectionRecord inspection,
    List<ValidationIssue> issues, {
    required String key,
    required String label,
    required List<String> options,
  }) {
    final response = inspection.responseByKey(
      MiningAxleTemplate.overallHealth,
      key,
    );
    if (!options.contains((response?.value ?? '').trim())) {
      issues.add(
        ValidationIssue(
          sectionKey: MiningAxleTemplate.overallHealth,
          itemKey: key,
          message: '$label is required.',
        ),
      );
    }
  }

  static void _validateRecommendations(
    InspectionRecord inspection,
    List<ValidationIssue> issues,
    bool hasAbnormalFindings,
  ) {
    final overall = inspection.responseByKey(
      MiningAxleTemplate.overallHealth,
      healthOverallConditionKey,
    );
    final overallValue = (overall?.value ?? '').trim();
    final needsRecommendation =
        hasAbnormalFindings ||
        overallValue == MiningAxleTemplate.fair ||
        overallValue == MiningAxleTemplate.poor;
    if (!needsRecommendation) {
      return;
    }
    final hasRecommendation = inspection.recommendationRows.any(
      (row) => row.recommendation.trim().isNotEmpty,
    );
    if (!hasRecommendation && inspection.actionItems.isEmpty) {
      issues.add(
        const ValidationIssue(
          sectionKey: MiningAxleTemplate.recommendations,
          message:
              'At least one recommendation or action item is required for Fair/Poor overall condition or abnormal findings.',
        ),
      );
    }
  }

  static bool _hasMeaningfulProgress(InspectionRecord inspection) {
    return inspection.customer.trim().isNotEmpty ||
        inspection.siteLocation.trim().isNotEmpty ||
        inspection.equipmentMake.trim().isNotEmpty ||
        inspection.equipmentModel.trim().isNotEmpty ||
        inspection.machineSerialNumber.trim().isNotEmpty ||
        inspection.axleSerialNumber.trim().isNotEmpty ||
        inspection.responses.isNotEmpty ||
        inspection.photos.isNotEmpty ||
        inspection.oilAnalysisRows.isNotEmpty ||
        inspection.mechanicalMeasurementRows.isNotEmpty ||
        inspection.temperatureRows.isNotEmpty ||
        inspection.recommendationRows.isNotEmpty;
  }
}
