import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models/inspection_enums.dart';
import '../data/models/inspection_models.dart';
import '../data/repositories/inspection_repository.dart';
import 'constants.dart';
import 'mining_axle_template.dart';
import 'theme.dart';
import 'workspace_models.dart';

class AppWorkspaceController extends ChangeNotifier {
  AppWorkspaceController({required InspectionRepository repository})
    : _repository = repository {
    Timer.run(() {
      if (!_disposed) {
        unawaited(refresh());
      }
    });
  }

  final InspectionRepository _repository;
  final List<InspectionSummary> _inspections = <InspectionSummary>[];
  final Map<String, InspectionRecord> _recordsById =
      <String, InspectionRecord>{};

  String _searchQuery = '';
  InspectionStatus? _statusFilter;
  bool _isLoading = true;
  bool _disposed = false;
  Object? _lastError;

  String get searchQuery => _searchQuery;
  InspectionStatus? get statusFilter => _statusFilter;
  bool get isLoading => _isLoading;
  Object? get lastError => _lastError;
  Set<String> get documentNumbers =>
      _inspections.map((item) => item.documentNumber).toSet();

  List<InspectionSummary> get inspections => List.unmodifiable(_inspections);

  List<InspectionSummary> get filteredInspections {
    final query = _searchQuery.trim().toLowerCase();
    return _inspections
        .where((inspection) {
          final matchesQuery =
              query.isEmpty || inspection.searchableText.contains(query);
          final matchesStatus =
              _statusFilter == null || inspection.status == _statusFilter;
          return matchesQuery && matchesStatus;
        })
        .toList(growable: false);
  }

  List<DashboardMetric> get dashboardMetrics => [
    DashboardMetric(
      label: 'Draft',
      value: _inspections
          .where((item) => item.status == InspectionStatus.draft)
          .length
          .toString(),
      icon: Icons.description_outlined,
      color: CtsPalette.slate,
      subtitle: 'Ready to continue',
    ),
    DashboardMetric(
      label: 'In Progress',
      value: _inspections
          .where((item) => item.status == InspectionStatus.inProgress)
          .length
          .toString(),
      icon: Icons.play_circle_outline,
      color: CtsPalette.orange,
      subtitle: 'Actively being filled out',
    ),
    DashboardMetric(
      label: 'Complete',
      value: _inspections
          .where((item) => item.status == InspectionStatus.complete)
          .length
          .toString(),
      icon: Icons.verified_outlined,
      color: CtsPalette.success,
      subtitle: 'Validated and signed',
    ),
    DashboardMetric(
      label: 'Emailed',
      value: _inspections
          .where((item) => item.status == InspectionStatus.emailed)
          .length
          .toString(),
      icon: Icons.mark_email_read_outlined,
      color: CtsPalette.info,
      subtitle: 'Handed off to the customer',
    ),
    DashboardMetric(
      label: 'Critical',
      value: _inspections
          .where((item) => item.criticalCount > 0)
          .length
          .toString(),
      icon: Icons.warning_amber_rounded,
      color: CtsPalette.danger,
      subtitle: 'LOTO attention required',
    ),
    DashboardMetric(
      label: 'Photos',
      value: _inspections
          .fold<int>(0, (sum, item) => sum + item.photoCount)
          .toString(),
      icon: Icons.photo_library_outlined,
      color: CtsPalette.orangeSoft,
      subtitle: 'Stored locally on device',
    ),
  ];

  InspectionSummary? inspectionById(String id) {
    for (final inspection in _inspections) {
      if (inspection.id == id) {
        return inspection;
      }
    }
    return null;
  }

  Future<InspectionRecord?> inspectionRecordById(String id) async {
    final cached = _recordsById[id];
    if (cached != null) {
      return cached.clone();
    }
    final record = await _repository.getInspection(id);
    if (record == null) {
      return null;
    }
    _cacheRecord(record);
    notifyListeners();
    return record.clone();
  }

  List<InspectionSummary> get recentInspections {
    final copy = List<InspectionSummary>.of(_inspections);
    copy.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
    return copy
        .take(AppConstants.recentInspectionLimit)
        .toList(growable: false);
  }

  List<InspectionActionItemView> get openActionItems =>
      _inspections.expand((item) => item.actionItems).toList(growable: false);

  void setSearchQuery(String value) {
    if (value == _searchQuery) {
      return;
    }
    _searchQuery = value;
    notifyListeners();
  }

  void setStatusFilter(InspectionStatus? status) {
    if (status == _statusFilter) {
      return;
    }
    _statusFilter = status;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_disposed) {
      return;
    }
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final records = await _repository.allInspections();
      _recordsById
        ..clear()
        ..addEntries(records.map((record) => MapEntry(record.id, record)));
      _inspections
        ..clear()
        ..addAll(records.map(_summaryFor));
      _sortSummaries();
    } catch (error) {
      _lastError = error;
    } finally {
      _isLoading = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  Future<InspectionRecord> createInspectionRecord({DateTime? createdAt}) async {
    final record = await _repository.createInspection(createdAt: createdAt);
    _cacheRecord(record);
    notifyListeners();
    return record.clone();
  }

  Future<InspectionSummary> createInspection({DateTime? createdAt}) async {
    final record = await createInspectionRecord(createdAt: createdAt);
    return _summaryFor(record);
  }

  Future<InspectionSummary> duplicateInspection(
    InspectionSummary source,
  ) async {
    final record = await _repository.getInspection(source.id);
    if (record == null) {
      throw StateError('Inspection ${source.id} no longer exists.');
    }
    final duplicate = await _repository.duplicateInspection(record);
    _cacheRecord(duplicate);
    notifyListeners();
    return _summaryFor(duplicate);
  }

  Future<InspectionSummary> saveInspectionRecord(
    InspectionRecord inspection,
  ) async {
    final saved = await _repository.saveInspection(inspection);
    _cacheRecord(saved);
    notifyListeners();
    return _summaryFor(saved);
  }

  void _cacheRecord(InspectionRecord record) {
    _recordsById[record.id] = record.clone();
    final summary = _summaryFor(record);
    final index = _inspections.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      _inspections.add(summary);
    } else {
      _inspections[index] = summary;
    }
    _sortSummaries();
  }

  void _sortSummaries() {
    _inspections.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
  }

  InspectionSummary _summaryFor(InspectionRecord record) {
    return InspectionSummary(
      id: record.id,
      documentNumber: record.documentNumber,
      customer: _displayOrPlaceholder(record.customer, 'Unassigned customer'),
      workOrderNumber: record.workOrderNumber,
      customerReference: record.customerReference,
      assetName: _assetLabel(record),
      siteLocation: record.siteLocation,
      technicianName: record.technicianName,
      servicingShop: record.servicingShop,
      inspectionDateTime: record.inspectionDateTime,
      createdAt: record.createdAt,
      status: record.status,
      sections: _sectionViews(record),
      actionItems: record.actionItems.map(_actionItemView).toList(),
      photos: record.photos.map(_photoView).toList(),
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

  List<InspectionSectionView> _sectionViews(InspectionRecord record) {
    final sections = record.sections.isEmpty
        ? MiningAxleTemplate.sections.map(
            (section) => InspectionSectionProgress(
              id: '${record.id}_${section.key}',
              inspectionId: record.id,
              sectionKey: section.key,
              title: section.title,
              sortOrder: section.sortOrder,
              completionState: SectionCompletionState.notStarted,
            ),
          )
        : record.sections;

    return sections
        .map(
          (section) => InspectionSectionView(
            key: section.sectionKey,
            title: section.title,
            completionState: section.completionState,
            summary: _sectionSummary(section.completionState),
            photoCount: record.photos
                .where((photo) => photo.sectionKey == section.sectionKey)
                .length,
            flaggedCount: record.responses
                .where(
                  (response) =>
                      response.sectionKey == section.sectionKey &&
                      (response.isFlagged ||
                          (response.conditionRating?.isFlagged ?? false)),
                )
                .length,
            criticalWarning: record.responses.any(
              (response) =>
                  response.sectionKey == section.sectionKey &&
                  response.conditionRating ==
                      ConditionRating.criticalOutOfService,
            ),
          ),
        )
        .toList(growable: false);
  }

  InspectionActionItemView _actionItemView(ActionItem item) {
    return InspectionActionItemView(
      title: item.title,
      description: item.description,
      conditionRating: item.conditionRating ?? ConditionRating.monitorAtRisk,
      sourceSection: item.sourceSectionKey == null
          ? 'Manual Action'
          : MiningAxleTemplate.sectionTitleFor(item.sourceSectionKey!),
      sourceItem: item.sourceItemKey ?? 'Manual',
      partsRequired: item.partsRequired,
      isAutoGenerated: item.isAutoGenerated,
    );
  }

  InspectionPhotoView _photoView(InspectionPhoto photo) {
    final item = MiningAxleTemplate.itemByKey(photo.sectionKey, photo.itemKey);
    return InspectionPhotoView(
      assetPath: photo.filePath,
      isAsset: false,
      caption: (photo.caption ?? '').trim().isEmpty
          ? 'Inspection photo'
          : photo.caption!.trim(),
      sectionTitle: MiningAxleTemplate.sectionTitleFor(photo.sectionKey),
      itemLabel: item?.label ?? photo.itemKey,
      capturedAt: photo.capturedAt,
    );
  }

  String _assetLabel(InspectionRecord record) {
    if (record.assetName.trim().isNotEmpty) {
      return record.assetName.trim();
    }
    final parts = <String>[
      record.equipmentMake,
      record.equipmentModel,
      record.axleSerialNumber,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    return parts.trim().isEmpty ? 'Unassigned axle' : parts.trim();
  }

  String _displayOrPlaceholder(String value, String placeholder) {
    return value.trim().isEmpty ? placeholder : value.trim();
  }

  String _sectionSummary(SectionCompletionState state) {
    return switch (state) {
      SectionCompletionState.notStarted => 'Required information not started.',
      SectionCompletionState.inProgress =>
        'Inspection information in progress.',
      SectionCompletionState.complete => 'Required information complete.',
      SectionCompletionState.blocked => 'Completion blockers need attention.',
    };
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
