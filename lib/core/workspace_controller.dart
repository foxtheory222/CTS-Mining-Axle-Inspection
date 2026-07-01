import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'mining_axle_template.dart';
import 'theme.dart';
import '../data/models/inspection_enums.dart';
import 'workspace_models.dart';

class AppWorkspaceController extends ChangeNotifier {
  AppWorkspaceController() : _inspections = _seedInspections();

  final List<InspectionSummary> _inspections;
  String _searchQuery = '';
  InspectionStatus? _statusFilter;

  String get searchQuery => _searchQuery;
  InspectionStatus? get statusFilter => _statusFilter;

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

  List<InspectionSummary> get recentInspections {
    final copy = List<InspectionSummary>.of(_inspections);
    copy.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
    return copy.take(6).toList(growable: false);
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

  InspectionSummary createInspection() {
    final now = DateTime.now();
    final documentNumber = _nextDocumentNumberForDate(now);
    final inspection = InspectionSummary(
      id: _makeId(documentNumber),
      documentNumber: documentNumber,
      customer: '',
      workOrderNumber: '',
      customerReference: '',
      assetName: '',
      siteLocation: '',
      technicianName: '',
      servicingShop: '',
      inspectionDateTime: now,
      createdAt: now,
      status: InspectionStatus.draft,
      sections: _defaultSections(),
      actionItems: [],
      photos: [],
      flaggedCount: 0,
      atRiskCount: 0,
      unsatisfactoryCount: 0,
      criticalCount: 0,
      photoCount: 0,
      lastUpdatedAt: now,
    );
    _inspections.insert(0, inspection);
    notifyListeners();
    return inspection;
  }

  InspectionSummary duplicateInspection(InspectionSummary source) {
    final now = DateTime.now();
    final documentNumber = _nextDocumentNumberForDate(now);
    final clone = source.copyWith(
      id: _makeId(documentNumber),
      documentNumber: documentNumber,
      status: InspectionStatus.draft,
      createdAt: now,
      inspectionDateTime: now,
      completedAt: null,
      emailedAt: null,
      finalTechComments: null,
      criticalAcknowledged: false,
      generatedPdfPath: null,
      sections: _defaultSections(),
      actionItems: [],
      photos: [],
      flaggedCount: 0,
      atRiskCount: 0,
      unsatisfactoryCount: 0,
      criticalCount: 0,
      photoCount: 0,
      lastUpdatedAt: now,
    );
    _inspections.insert(0, clone);
    notifyListeners();
    return clone;
  }

  void replaceInspection(InspectionSummary updated) {
    final index = _inspections.indexWhere((item) => item.id == updated.id);
    if (index != -1) {
      _inspections[index] = updated;
      notifyListeners();
    }
  }

  String _nextDocumentNumberForDate(DateTime date) {
    final dayStamp = DateFormat('yyyyMMdd').format(date);
    final matches = _inspections
        .where((item) => item.documentNumber.startsWith('$dayStamp-'))
        .length;
    final sequence = matches + 1;
    return '$dayStamp-${sequence.toString().padLeft(4, '0')}';
  }

  String _makeId(String documentNumber) {
    return 'inspection_${documentNumber.replaceAll('-', '_')}';
  }

  static List<InspectionSummary> _seedInspections() {
    final today = DateTime(2026, 4, 20, 8, 30);
    final yesterday = today.subtract(const Duration(days: 1));
    final inspection1 = InspectionSummary(
      id: 'inspection_20260420_0001',
      documentNumber: '20260420-0001',
      customer: 'Moraine Quarry',
      workOrderNumber: 'WO-48912',
      customerReference: 'PO-55412',
      assetName: 'CAT 793F Rear Axle AXLE-1001',
      siteLocation: 'East Pit Service Bay',
      technicianName: 'R. Ellis',
      servicingShop: 'CTS Edmonton Service',
      inspectionDateTime: today,
      createdAt: today,
      status: InspectionStatus.complete,
      sections: _defaultSections(
        atRisk: 1,
        unsat: 1,
        critical: 0,
        photoCount: 5,
      ),
      actionItems: [
        InspectionActionItemView(
          title: 'Schedule hub seal replacement',
          description:
              'Light seepage was noted at the left planetary hub seal during the inspection.',
          conditionRating: ConditionRating.unsatisfactory,
          sourceSection: 'Planetary Hub Inspection',
          sourceItem: 'Hub Seals',
          partsRequired: 'Hub seal kit and axle oil top-up',
        ),
      ],
      photos: [
        InspectionPhotoView(
          assetPath: 'assets/demo/sample_photo_1.jpg',
          caption: 'As-found axle overview',
          sectionTitle: 'Visual Inspection',
          itemLabel: 'Axle Housing',
          capturedAt: DateTime(2026, 4, 20, 8, 45),
        ),
        InspectionPhotoView(
          assetPath: 'assets/demo/sample_photo_2.jpg',
          caption: 'Planetary hub evidence',
          sectionTitle: 'Planetary Hub Inspection',
          itemLabel: 'Wheel Bearings',
          capturedAt: DateTime(2026, 4, 20, 9, 10),
        ),
      ],
      flaggedCount: 2,
      atRiskCount: 1,
      unsatisfactoryCount: 1,
      criticalCount: 0,
      photoCount: 5,
      lastUpdatedAt: today.add(const Duration(minutes: 32)),
      completedAt: today.add(const Duration(hours: 1, minutes: 14)),
      finalTechComments:
          'Axle operating within service limits with hub seal replacement planned.',
      generatedPdfPath:
          '/storage/emulated/0/Download/CTS_AXLE_Moraine_Quarry_AXLE-1001_20260420_20260420-0001.pdf',
    );

    final inspection2 = InspectionSummary(
      id: 'inspection_20260420_0002',
      documentNumber: '20260420-0002',
      customer: 'North Basin Processing',
      workOrderNumber: 'WO-48921',
      customerReference: 'JOB-7745',
      assetName: 'Komatsu 830E Front Axle AXLE-2002',
      siteLocation: 'North Pit Maintenance Pad',
      technicianName: 'K. Morgan',
      servicingShop: 'CTS Calgary Service',
      inspectionDateTime: today.add(const Duration(hours: 2)),
      createdAt: today.add(const Duration(hours: 2)),
      status: InspectionStatus.emailed,
      sections: _defaultSections(
        atRisk: 2,
        unsat: 1,
        critical: 1,
        photoCount: 7,
      ),
      actionItems: [
        InspectionActionItemView(
          title: 'Lockout/Tagout before restart',
          description:
              'Critical axle housing crack requires isolation until corrective work is complete.',
          conditionRating: ConditionRating.criticalOutOfService,
          sourceSection: 'Visual Inspection',
          sourceItem: 'Axle Housing',
          partsRequired: 'Housing repair plan and lockout hardware',
        ),
        InspectionActionItemView(
          title: 'Replace contaminated breather',
          description:
              'Breather contamination noted; replacement recommended before return to service.',
          conditionRating: ConditionRating.monitorAtRisk,
          sourceSection: 'Visual Inspection',
          sourceItem: 'Breathers',
          partsRequired: 'Axle breather element 12-7781',
        ),
      ],
      photos: [
        InspectionPhotoView(
          assetPath: 'assets/demo/sample_photo_1.jpg',
          caption: 'Critical housing crack',
          sectionTitle: 'Visual Inspection',
          itemLabel: 'Axle Housing',
          capturedAt: DateTime(2026, 4, 20, 10, 12),
        ),
        InspectionPhotoView(
          assetPath: 'assets/demo/sample_photo_2.jpg',
          caption: 'Oil sample evidence',
          sectionTitle: 'Lubrication Assessment',
          itemLabel: 'Oil Condition',
          capturedAt: DateTime(2026, 4, 20, 10, 18),
        ),
      ],
      flaggedCount: 3,
      atRiskCount: 2,
      unsatisfactoryCount: 1,
      criticalCount: 1,
      photoCount: 7,
      lastUpdatedAt: today.add(const Duration(hours: 2, minutes: 55)),
      completedAt: today.add(const Duration(hours: 3, minutes: 10)),
      emailedAt: today.add(const Duration(hours: 3, minutes: 42)),
      criticalAcknowledged: true,
      generatedPdfPath:
          '/storage/emulated/0/Download/CTS_AXLE_North_Basin_Processing_AXLE-2002_20260420_20260420-0002.pdf',
    );

    final inspection3 = InspectionSummary(
      id: 'inspection_20260419_0001',
      documentNumber: '20260419-0001',
      customer: 'Prairie Rail Services',
      workOrderNumber: 'WO-48888',
      customerReference: 'PR-1182',
      assetName: 'CAT 777G Rear Axle AXLE-3003',
      siteLocation: 'Maintenance Yard',
      technicianName: 'T. Singh',
      servicingShop: 'CTS Red Deer Service',
      inspectionDateTime: yesterday,
      createdAt: yesterday,
      status: InspectionStatus.inProgress,
      sections: _defaultSections(
        atRisk: 0,
        unsat: 0,
        critical: 0,
        photoCount: 2,
      ),
      actionItems: [],
      photos: [
        InspectionPhotoView(
          assetPath: 'assets/demo/sample_photo_1.jpg',
          caption: 'Axle identification photo',
          sectionTitle: 'Inspection Purpose',
          itemLabel: 'Axle serial plate',
          capturedAt: DateTime(2026, 4, 19, 15, 01),
        ),
      ],
      flaggedCount: 0,
      atRiskCount: 0,
      unsatisfactoryCount: 0,
      criticalCount: 0,
      photoCount: 2,
      lastUpdatedAt: yesterday.add(const Duration(hours: 1, minutes: 45)),
    );

    return [inspection2, inspection1, inspection3];
  }

  static List<InspectionSectionView> _defaultSections({
    int atRisk = 0,
    int unsat = 0,
    int critical = 0,
    int photoCount = 0,
  }) {
    return [
      InspectionSectionView(
        key: MiningAxleTemplate.inspectionPurpose,
        title: 'Inspection Purpose',
        completionState: SectionCompletionState.complete,
        summary: 'Purpose and header details captured.',
        photoCount: 0,
      ),
      InspectionSectionView(
        key: MiningAxleTemplate.visualInspection,
        title: 'Visual Inspection',
        completionState: SectionCompletionState.complete,
        summary: 'Axle housing, wheel ends, breathers, and fasteners checked.',
        photoCount: photoCount > 1 ? 2 : 0,
        flaggedCount: atRisk + unsat + critical,
        criticalWarning: critical > 0,
      ),
      InspectionSectionView(
        key: MiningAxleTemplate.lubricationAssessment,
        title: 'Lubrication Assessment',
        completionState: critical > 0
            ? SectionCompletionState.blocked
            : atRisk > 0 || unsat > 0
            ? SectionCompletionState.inProgress
            : SectionCompletionState.complete,
        summary: critical > 0
            ? 'Critical lubrication-related warning acknowledged.'
            : atRisk > 0 || unsat > 0
            ? 'Flagged lubrication findings need follow-up.'
            : 'Oil level and condition are within tolerance.',
        photoCount: photoCount > 2 ? 1 : 0,
        flaggedCount: atRisk,
        criticalWarning: critical > 0,
      ),
      InspectionSectionView(
        key: MiningAxleTemplate.differentialInspection,
        title: 'Differential Inspection',
        completionState: atRisk > 0 || unsat > 0
            ? SectionCompletionState.inProgress
            : SectionCompletionState.complete,
        summary: 'Crown wheel, pinion, bearings, backlash, and lock reviewed.',
        photoCount: photoCount > 3 ? 1 : 0,
        flaggedCount: unsat > 0 ? 1 : 0,
      ),
      InspectionSectionView(
        key: MiningAxleTemplate.planetaryHubInspection,
        title: 'Planetary Hub Inspection',
        completionState: atRisk > 0
            ? SectionCompletionState.inProgress
            : SectionCompletionState.complete,
        summary: 'Sun gears, planet gears, seals, and wheel bearings checked.',
        photoCount: photoCount > 4 ? 1 : 0,
        flaggedCount: atRisk > 0 ? 1 : 0,
      ),
      InspectionSectionView(
        key: MiningAxleTemplate.mechanicalMeasurementsSection,
        title: 'Mechanical Measurements',
        completionState: SectionCompletionState.complete,
        summary: 'Backlash, preload, end float, and runout values stored.',
        photoCount: photoCount > 5 ? 1 : 0,
      ),
      InspectionSectionView(
        key: MiningAxleTemplate.temperatureAssessment,
        title: 'Temperature Assessment',
        completionState: atRisk > 0
            ? SectionCompletionState.inProgress
            : SectionCompletionState.complete,
        summary: 'Infrared thermography readings captured.',
        photoCount: photoCount > 6 ? 1 : 0,
      ),
      InspectionSectionView(
        key: MiningAxleTemplate.conditionMonitoringFindingsSection,
        title: 'Condition Monitoring Findings',
        completionState: atRisk > 0 || unsat > 0 || critical > 0
            ? SectionCompletionState.inProgress
            : SectionCompletionState.complete,
        summary: 'Abnormal findings and supporting details reviewed.',
        photoCount: 0,
        flaggedCount: atRisk + unsat + critical,
        criticalWarning: critical > 0,
      ),
      InspectionSectionView(
        key: MiningAxleTemplate.recommendations,
        title: 'Recommendations',
        completionState: atRisk > 0 || unsat > 0 || critical > 0
            ? SectionCompletionState.inProgress
            : SectionCompletionState.complete,
        summary: 'Priority actions and monitoring recommendations tracked.',
        photoCount: 0,
        flaggedCount: atRisk + unsat + critical,
      ),
      InspectionSectionView(
        key: MiningAxleTemplate.overallHealth,
        title: 'Overall Axle Health Assessment',
        completionState: atRisk > 0 || unsat > 0 || critical > 0
            ? SectionCompletionState.blocked
            : SectionCompletionState.complete,
        summary: 'Ready for signoff when validation is clear.',
        photoCount: 0,
        flaggedCount: atRisk + unsat + critical,
        criticalWarning: critical > 0,
      ),
    ];
  }
}
