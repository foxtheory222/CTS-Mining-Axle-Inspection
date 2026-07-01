import '../core/constants.dart';
import '../core/mining_axle_template.dart';
import '../data/models/inspection_enums.dart';
import '../data/models/inspection_models.dart';
import '../features/pdf_report/pdf_report_models.dart';

class InspectionReportMapper {
  const InspectionReportMapper._();

  static InspectionReportData fromRecord(InspectionRecord record) {
    final consumedPhotoIds = <String>{};
    final sections = <InspectionReportSection>[
      for (final section in MiningAxleTemplate.sections)
        _sectionFor(record, section, consumedPhotoIds),
    ];

    return InspectionReportData(
      documentNumber: record.documentNumber,
      customer: record.customer,
      workOrderNumber: record.workOrderNumber,
      customerReference: record.customerReference.trim().isNotEmpty
          ? record.customerReference.trim()
          : record.purchaseOrderNumber.trim(),
      assetName: record.assetName,
      equipmentMake: record.equipmentMake,
      equipmentModel: record.equipmentModel,
      machineSerialNumber: record.machineSerialNumber,
      axleManufacturer: record.axleManufacturer,
      axleModel: record.axleModel,
      axleSerialNumber: record.axleSerialNumber,
      siteLocation: record.siteLocation,
      technicianName: record.technicianName,
      servicingShop: record.servicingShop,
      inspectionDateTime: record.inspectionDateTime,
      createdAt: record.createdAt,
      completedAt: record.completedAt,
      emailedAt: record.emailedAt,
      status: _statusFor(record.status),
      finalTechComments: record.finalTechComments,
      criticalAcknowledged: record.criticalAcknowledged,
      signature: _signatureFor(record),
      sections: sections,
      actionItems: record.actionItems.map(_actionFor).toList(growable: false),
      branding: const InspectionReportBranding(
        logoAssetPath: AppConstants.placeholderLogoAsset,
      ),
    );
  }

  static InspectionReportSection _sectionFor(
    InspectionRecord record,
    MiningAxleSection section,
    Set<String> consumedPhotoIds,
  ) {
    final items = <InspectionReportItem>[
      ...record.responses
          .where((response) => response.sectionKey == section.key)
          .map((response) => _itemFor(record, response, consumedPhotoIds)),
      ..._tableItemsFor(record, section.key),
      ..._orphanPhotoItemsFor(record, section.key, consumedPhotoIds),
    ];
    return InspectionReportSection(
      key: section.key,
      title: section.title,
      items: items,
    );
  }

  static InspectionReportItem _itemFor(
    InspectionRecord record,
    InspectionResponse response,
    Set<String> consumedPhotoIds,
  ) {
    final photos = record.photos
        .where(
          (photo) =>
              photo.sectionKey == response.sectionKey &&
              photo.itemKey == response.itemKey,
        )
        .map((photo) {
          consumedPhotoIds.add(photo.id);
          return _photoFor(photo);
        })
        .toList(growable: false);

    return InspectionReportItem(
      label: response.itemLabel,
      value: (response.value ?? '').trim().isEmpty
          ? 'Not recorded'
          : response.value!.trim(),
      conditionRating: _ratingFor(response.conditionRating),
      comment: response.comment,
      photos: photos,
    );
  }

  static List<InspectionReportItem> _tableItemsFor(
    InspectionRecord record,
    String sectionKey,
  ) {
    if (sectionKey == MiningAxleTemplate.lubricationAssessment) {
      return record.oilAnalysisRows
          .map(
            (row) => InspectionReportItem(
              label: row.parameter,
              value: row.result.trim().isEmpty ? 'Not recorded' : row.result,
              comment: row.limits.trim().isEmpty ? null : row.limits,
            ),
          )
          .toList(growable: false);
    }
    if (sectionKey == MiningAxleTemplate.mechanicalMeasurementsSection) {
      return record.mechanicalMeasurementRows
          .map(
            (row) => InspectionReportItem(
              label: row.measurement,
              value: row.actual.trim().isEmpty ? 'Not recorded' : row.actual,
              comment: [
                if (row.specification.trim().isNotEmpty)
                  'Specification: ${row.specification.trim()}',
                if (row.comments.trim().isNotEmpty) row.comments.trim(),
              ].join(' | '),
              conditionRating: row.flaggedOutOfSpec
                  ? ReportConditionRating.unsatisfactory
                  : null,
            ),
          )
          .toList(growable: false);
    }
    if (sectionKey == MiningAxleTemplate.temperatureAssessment) {
      return record.temperatureRows
          .map(
            (row) => InspectionReportItem(
              label: row.location,
              value: row.temperatureC == null
                  ? 'Not recorded'
                  : '${row.temperatureC} C',
              comment: row.comments.trim().isEmpty ? null : row.comments,
              conditionRating: row.abnormalFlagged
                  ? ReportConditionRating.monitor
                  : null,
            ),
          )
          .toList(growable: false);
    }
    if (sectionKey == MiningAxleTemplate.recommendations) {
      return record.recommendationRows
          .map(
            (row) => InspectionReportItem(
              label: row.priority,
              value: row.recommendation.trim().isEmpty
                  ? 'Not recorded'
                  : row.recommendation,
            ),
          )
          .toList(growable: false);
    }
    return const <InspectionReportItem>[];
  }

  static List<InspectionReportItem> _orphanPhotoItemsFor(
    InspectionRecord record,
    String sectionKey,
    Set<String> consumedPhotoIds,
  ) {
    return record.photos
        .where(
          (photo) =>
              photo.sectionKey == sectionKey &&
              !consumedPhotoIds.contains(photo.id),
        )
        .map((photo) {
          consumedPhotoIds.add(photo.id);
          final item = MiningAxleTemplate.itemByKey(
            photo.sectionKey,
            photo.itemKey,
          );
          return InspectionReportItem(
            label: item?.label ?? photo.itemKey,
            value: 'Photo evidence',
            photos: <InspectionReportPhoto>[_photoFor(photo)],
          );
        })
        .toList(growable: false);
  }

  static InspectionReportPhoto _photoFor(InspectionPhoto photo) {
    final item = MiningAxleTemplate.itemByKey(photo.sectionKey, photo.itemKey);
    return InspectionReportPhoto(
      filePath: photo.filePath,
      caption: (photo.caption ?? '').trim().isEmpty
          ? 'Inspection photo'
          : photo.caption!.trim(),
      sectionTitle: MiningAxleTemplate.sectionTitleFor(photo.sectionKey),
      itemLabel: item?.label ?? photo.itemKey,
      capturedAt: photo.capturedAt,
      sortOrder: photo.sortOrder,
    );
  }

  static InspectionReportActionItem _actionFor(ActionItem action) {
    return InspectionReportActionItem(
      title: action.title,
      description: action.description,
      sourceSection: action.sourceSectionKey == null
          ? null
          : MiningAxleTemplate.sectionTitleFor(action.sourceSectionKey!),
      sourceItem: action.sourceItemKey,
      partsRequired: action.partsRequired,
      isAutoGenerated: action.isAutoGenerated,
      conditionRating: _ratingFor(action.conditionRating),
    );
  }

  static InspectionReportSignature? _signatureFor(InspectionRecord record) {
    final path = record.signatureFilePath?.trim();
    if (path == null || path.isEmpty) {
      return null;
    }
    return InspectionReportSignature(
      filePath: path,
      signerName: record.technicianName,
      signedAt: record.completedAt ?? record.updatedAt,
    );
  }

  static InspectionReportStatus _statusFor(InspectionStatus status) {
    return switch (status) {
      InspectionStatus.draft => InspectionReportStatus.draft,
      InspectionStatus.inProgress => InspectionReportStatus.inProgress,
      InspectionStatus.complete => InspectionReportStatus.complete,
      InspectionStatus.emailed => InspectionReportStatus.emailed,
    };
  }

  static ReportConditionRating? _ratingFor(ConditionRating? rating) {
    return switch (rating) {
      null => null,
      ConditionRating.satisfactory => ReportConditionRating.satisfactory,
      ConditionRating.monitorAtRisk => ReportConditionRating.monitor,
      ConditionRating.unsatisfactory => ReportConditionRating.unsatisfactory,
      ConditionRating.criticalOutOfService => ReportConditionRating.critical,
    };
  }
}
