import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';

import '../../core/constants.dart';
import '../../core/file_utils.dart';
import '../../core/layout.dart';
import '../../core/mining_axle_template.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/workspace_models.dart';
import '../../core/workspace_providers.dart';
import '../../data/models/inspection_enums.dart';
import '../../data/models/inspection_models.dart';
import '../../services/photo_service.dart';
import '../../widgets/photo_grid.dart';
import '../../widgets/section_card.dart';
import '../../widgets/signature_pad.dart';

class InspectionFormScreen extends ConsumerStatefulWidget {
  const InspectionFormScreen({
    super.key,
    this.inspectionId,
    this.initialRecord,
  });

  final String? inspectionId;
  final InspectionRecord? initialRecord;

  @override
  ConsumerState<InspectionFormScreen> createState() =>
      _InspectionFormScreenState();
}

class _InspectionFormScreenState extends ConsumerState<InspectionFormScreen> {
  late final ScrollController _scrollController;
  late final SignatureController _signatureController;
  late final SignatureController _customerSignatureController;
  late final Map<String, GlobalKey> _keys;
  late final TextEditingController _customer;
  late final TextEditingController _customerRepresentative;
  late final TextEditingController _customerUnavailableNote;
  late final TextEditingController _workOrder;
  late final TextEditingController _site;
  late final TextEditingController _equipmentMake;
  late final TextEditingController _equipmentModel;
  late final TextEditingController _machineSerial;
  late final TextEditingController _axleManufacturer;
  late final TextEditingController _axleModel;
  late final TextEditingController _axleSerial;
  late final TextEditingController _hours;
  late final TextEditingController _inspector;
  late final TextEditingController _servicingShop;
  late final TextEditingController _purchaseOrder;
  late final TextEditingController _relatedReport;
  late final TextEditingController _sampleNumber;
  late final TextEditingController _findingDetails;
  late final TextEditingController _recommendation;
  late final TextEditingController _reviewNotes;

  final Map<String, String> _answers = <String, String>{};
  final Map<String, TextEditingController> _commentControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _tableControllers =
      <String, TextEditingController>{};
  final Set<String> _selectedPurposes = <String>{};
  final Set<String> _selectedFindings = <String>{};
  final List<InspectionPhoto> _recordPhotos = <InspectionPhoto>[];
  final List<InspectionPhotoView> _photos = <InspectionPhotoView>[];

  InspectionRecord? _record;
  bool _loadingRecord = true;
  bool _saving = false;
  bool _thermographyPerformed = false;
  bool _criticalAcknowledged = false;
  bool _signed = false;
  bool _customerSigned = false;
  List<ValidationIssue> _validationIssues = const <ValidationIssue>[];

  List<_SectionState> get _sections => MiningAxleTemplate.sections
      .map(
        (section) => _SectionState(
          section.key,
          section.title,
          SectionCompletionState.notStarted,
        ),
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: CtsPalette.orange,
      exportBackgroundColor: Colors.white,
    )..addListener(_handleSignatureChanged);
    _customerSignatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: CtsPalette.orange,
      exportBackgroundColor: Colors.white,
    )..addListener(_handleCustomerSignatureChanged);
    _keys = {for (final section in _sections) section.key: GlobalKey()};

    _customer = TextEditingController();
    _customerRepresentative = TextEditingController();
    _customerUnavailableNote = TextEditingController();
    _workOrder = TextEditingController();
    _site = TextEditingController();
    _equipmentMake = TextEditingController();
    _equipmentModel = TextEditingController();
    _machineSerial = TextEditingController();
    _axleManufacturer = TextEditingController();
    _axleModel = TextEditingController();
    _axleSerial = TextEditingController();
    _hours = TextEditingController();
    _inspector = TextEditingController();
    _servicingShop = TextEditingController();
    _purchaseOrder = TextEditingController();
    _relatedReport = TextEditingController();
    _sampleNumber = TextEditingController();
    _findingDetails = TextEditingController();
    _recommendation = TextEditingController();
    _reviewNotes = TextEditingController();

    final initialRecord = widget.initialRecord;
    if (initialRecord == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_loadRecord());
        }
      });
    } else {
      _record = initialRecord.clone();
      _applyRecord(_record!);
      _loadingRecord = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _signatureController
      ..removeListener(_handleSignatureChanged)
      ..dispose();
    _customerSignatureController
      ..removeListener(_handleCustomerSignatureChanged)
      ..dispose();
    _customer.dispose();
    _customerRepresentative.dispose();
    _customerUnavailableNote.dispose();
    _workOrder.dispose();
    _site.dispose();
    _equipmentMake.dispose();
    _equipmentModel.dispose();
    _machineSerial.dispose();
    _axleManufacturer.dispose();
    _axleModel.dispose();
    _axleSerial.dispose();
    _hours.dispose();
    _inspector.dispose();
    _servicingShop.dispose();
    _purchaseOrder.dispose();
    _relatedReport.dispose();
    _sampleNumber.dispose();
    _findingDetails.dispose();
    _recommendation.dispose();
    _reviewNotes.dispose();
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    for (final controller in _tableControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRecord) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_record == null) {
      return const Center(child: Text('Inspection record was not found.'));
    }

    final issues = _visibleIssueMessages();
    return LayoutBuilder(
      builder: (context, constraints) {
        final showRail = constraints.maxWidth >= Breakpoints.formRail;
        final showSummary = constraints.maxWidth >= Breakpoints.formSummary;
        final form = SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Banner(
                isEdit: widget.inspectionId != null,
                documentNumber: _record!.documentNumber,
                isSaving: _saving,
                onSaveDraft: _saveDraft,
                onGeneratePdf: _notifyPdf,
                onComplete: _completeInspection,
              ),
              const SizedBox(height: 16),
              _purposeSection(),
              const SizedBox(height: 16),
              _visualSection(),
              const SizedBox(height: 16),
              _lubricationSection(),
              const SizedBox(height: 16),
              _differentialSection(),
              const SizedBox(height: 16),
              _planetarySection(),
              const SizedBox(height: 16),
              _measurementSection(),
              const SizedBox(height: 16),
              _temperatureSection(),
              const SizedBox(height: 16),
              _findingsSection(),
              const SizedBox(height: 16),
              _recommendationsSection(),
              const SizedBox(height: 16),
              _healthSection(),
              const SizedBox(height: 16),
              _reviewSection(issues),
            ],
          ),
        );

        // Constrain the reading column so fields never stretch edge-to-edge on
        // very wide tablets when the side panels are not shown.
        final centeredForm = showSummary
            ? form
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Breakpoints.readableColumn,
                  ),
                  child: form,
                ),
              );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showRail) ...[
              SizedBox(
                width: 236,
                child: SingleChildScrollView(
                  child: _SectionRail(sections: _sections, onJump: _jumpTo),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(child: centeredForm),
            if (showSummary) ...[
              const SizedBox(width: 16),
              SizedBox(
                width: 340,
                child: _SummaryPanel(
                  issues: issues,
                  photos: _photos,
                  onJump: _jumpTo,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _purposeSection() => SectionCard(
    key: _keys[MiningAxleTemplate.inspectionPurpose],
    title: 'Inspection Purpose',
    subtitle: 'Required header details and one or more purpose selections.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldGrid(<_TextFieldSpec>[
          _TextFieldSpec(_customer, 'Customer'),
          _TextFieldSpec(_workOrder, 'Work Order Number'),
          _TextFieldSpec(_site, 'Site'),
          _TextFieldSpec(_equipmentMake, 'Equipment Make'),
          _TextFieldSpec(_equipmentModel, 'Equipment Model'),
          _TextFieldSpec(_machineSerial, 'Machine Serial No.'),
          _TextFieldSpec(_axleManufacturer, 'Axle Manufacturer'),
          _TextFieldSpec(_axleModel, 'Axle Model'),
          _TextFieldSpec(_axleSerial, 'Axle Serial Number'),
          _TextFieldSpec(_hours, 'Hours on Machine'),
          _TextFieldSpec(_inspector, 'CTS Inspector'),
          _TextFieldSpec(_servicingShop, 'Servicing Shop'),
          _TextFieldSpec(_purchaseOrder, 'Purchase Order Number'),
          _TextFieldSpec(_relatedReport, 'Related Machine Report Reference'),
        ]),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final purpose in MiningAxleTemplate.purposeItems)
              FilterChip(
                label: Text(purpose.label),
                selected: _selectedPurposes.contains(purpose.itemKey),
                onSelected: (selected) {
                  setState(() {
                    selected
                        ? _selectedPurposes.add(purpose.itemKey)
                        : _selectedPurposes.remove(purpose.itemKey);
                  });
                },
              ),
          ],
        ),
      ],
    ),
  );

  Widget _visualSection() => SectionCard(
    key: _keys[MiningAxleTemplate.visualInspection],
    title: 'Visual Inspection',
    subtitle: 'Condition rows use Good/Fair/Poor/N/A/Not Inspected.',
    child: Column(
      children: [
        ...MiningAxleTemplate.visualConditionItems.map(
          (item) => _optionRow(item, MiningAxleTemplate.conditionOptions),
        ),
        ...MiningAxleTemplate.visualDefectItems.map(
          (item) => _optionRow(item, MiningAxleTemplate.defectOptions),
        ),
        const SizedBox(height: 12),
        PhotoGrid(
          photos: _photosForSection(MiningAxleTemplate.visualInspection),
          onAddPhoto: () => _addPhoto(MiningAxleTemplate.visualInspection),
        ),
      ],
    ),
  );

  Widget _lubricationSection() => SectionCard(
    key: _keys[MiningAxleTemplate.lubricationAssessment],
    title: 'Lubrication Assessment',
    subtitle: 'Oil sample number is required when a sample is taken.',
    child: Column(
      children: [
        for (final item in MiningAxleTemplate.lubricationItems)
          item.rule == MiningAxleResponseRule.condition
              ? _optionRow(item, MiningAxleTemplate.conditionOptions)
              : item.rule == MiningAxleResponseRule.defect
              ? _optionRow(item, MiningAxleTemplate.defectOptions)
              : TextField(
                  onChanged: (value) => _answers[item.itemKey] = value,
                  controller: _sampleNumber,
                  decoration: InputDecoration(labelText: item.label),
                ),
        const SizedBox(height: 12),
        _simpleTable(
          tableKey: 'oil',
          headers: const ['Parameter', 'Result', 'Limits'],
          rows: MiningAxleTemplate.oilAnalysisParameters,
        ),
      ],
    ),
  );

  Widget _differentialSection() => SectionCard(
    key: _keys[MiningAxleTemplate.differentialInspection],
    title: 'Differential Inspection',
    subtitle: 'Backlash and differential lock use their special option sets.',
    child: Column(
      children: [
        for (final item in MiningAxleTemplate.differentialConditionItems)
          _optionRow(item, switch (item.rule) {
            MiningAxleResponseRule.acceptable =>
              MiningAxleTemplate.acceptableOptions,
            MiningAxleResponseRule.operational =>
              MiningAxleTemplate.operationalOptions,
            _ => MiningAxleTemplate.conditionOptions,
          }),
      ],
    ),
  );

  Widget _planetarySection() => SectionCard(
    key: _keys[MiningAxleTemplate.planetaryHubInspection],
    title: 'Planetary Hub Inspection',
    subtitle: 'Use comments to specify left or right side where relevant.',
    child: Column(
      children: [
        for (final item in MiningAxleTemplate.planetaryHubItems)
          _optionRow(item, MiningAxleTemplate.conditionOptions),
        const SizedBox(height: 12),
        PhotoGrid(
          photos: _photosForSection(MiningAxleTemplate.planetaryHubInspection),
          onAddPhoto: () =>
              _addPhoto(MiningAxleTemplate.planetaryHubInspection),
        ),
      ],
    ),
  );

  Widget _measurementSection() => SectionCard(
    key: _keys[MiningAxleTemplate.mechanicalMeasurementsSection],
    title: 'Mechanical Measurements',
    subtitle: 'Specifications and actual values are free text for V1.',
    child: _simpleTable(
      tableKey: 'measurement',
      headers: const ['Measurement', 'Specification', 'Actual', 'Comments'],
      rows: MiningAxleTemplate.mechanicalMeasurements,
    ),
  );

  Widget _temperatureSection() => SectionCard(
    key: _keys[MiningAxleTemplate.temperatureAssessment],
    title: 'Temperature Assessment',
    subtitle: 'Optional infrared thermography readings in degrees C.',
    child: Column(
      children: [
        SwitchListTile(
          key: const Key('thermography_performed_switch'),
          value: _thermographyPerformed,
          onChanged: (value) => setState(() => _thermographyPerformed = value),
          title: const Text('Performed Using Infrared Thermography'),
          activeThumbColor: CtsPalette.orange,
        ),
        _simpleTable(
          tableKey: 'temperature',
          headers: const ['Location', 'Temperature C', 'Comments'],
          rows: MiningAxleTemplate.temperatureLocations,
        ),
      ],
    ),
  );

  Widget _findingsSection() => SectionCard(
    key: _keys[MiningAxleTemplate.conditionMonitoringFindingsSection],
    title: 'Condition Monitoring Findings',
    subtitle: 'Selected abnormal findings require supporting details.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final finding
                in MiningAxleTemplate.conditionMonitoringFindings)
              FilterChip(
                label: Text(finding.label),
                selected: _selectedFindings.contains(finding.itemKey),
                onSelected: (selected) {
                  setState(() {
                    selected
                        ? _selectedFindings.add(finding.itemKey)
                        : _selectedFindings.remove(finding.itemKey);
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _findingDetails,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Details'),
        ),
      ],
    ),
  );

  Widget _recommendationsSection() => SectionCard(
    key: _keys[MiningAxleTemplate.recommendations],
    title: 'Recommendations',
    subtitle: 'Priority 1/2/3 recommendations can be edited before PDF output.',
    child: Column(
      children: [
        TextField(
          controller: _recommendation,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Recommendation'),
        ),
      ],
    ),
  );

  Widget _healthSection() => SectionCard(
    key: _keys[MiningAxleTemplate.overallHealth],
    title: 'Overall Axle Health Assessment',
    subtitle: 'Health scores are selected manually by the inspector.',
    child: Column(
      children: [
        _scoreRow('Mechanical Condition'),
        _scoreRow('Lubrication Condition'),
        _scoreRow('Contamination Control'),
        _dropdownField(
          'health_reliability_risk',
          'Reliability Risk',
          MiningAxleTemplate.reliabilityRiskOptions,
          defaultValue: 'Low',
        ),
        _dropdownField(
          'health_overall_condition',
          'Overall Condition',
          MiningAxleTemplate.overallConditionOptions,
          defaultValue: 'Good',
        ),
      ],
    ),
  );

  Widget _reviewSection(List<String> issues) => SectionCard(
    title: 'Review Summary',
    subtitle:
        'Completion blockers, evidence, PDF/share/export actions, and signoff.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            StatusChip(
              text: '${issues.length} issue${issues.length == 1 ? '' : 's'}',
              color: issues.isEmpty ? CtsPalette.success : CtsPalette.danger,
            ),
            StatusChip(
              text: '${_photos.length} photos',
              color: CtsPalette.info,
            ),
            const StatusChip(text: 'Saved to SQLite', color: CtsPalette.slate),
          ],
        ),
        const SizedBox(height: 12),
        for (final issue in issues.take(8)) ...[
          _IssueTile(issue),
          const SizedBox(height: 8),
        ],
        if (issues.length > 8)
          _IssueTile('${issues.length - 8} more completion issue(s).'),
        CheckboxListTile(
          value: _criticalAcknowledged,
          onChanged: (value) =>
              setState(() => _criticalAcknowledged = value ?? false),
          title: const Text('Critical / Out of Service acknowledgement'),
          subtitle: const Text(
            'Inspector acknowledges critical/out-of-service item has been communicated/escalated according to CTS/site procedure.',
          ),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: CtsPalette.orange,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reviewNotes,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Review notes'),
        ),
        const SizedBox(height: 12),
        SignaturePad(
          controller: _signatureController,
          isSigned: _signed,
          onClear: () {
            _signatureController.clear();
            setState(() => _signed = false);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _customerRepresentative,
          decoration: const InputDecoration(
            labelText: 'Customer representative name',
          ),
        ),
        const SizedBox(height: 12),
        SignaturePad(
          title: 'Customer signature',
          controller: _customerSignatureController,
          isSigned: _customerSigned,
          onClear: () {
            _customerSignatureController.clear();
            setState(() => _customerSigned = false);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _customerUnavailableNote,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Customer unavailable reason (optional)',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: _saving ? null : _saveDraft,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Draft'),
            ),
            FilledButton.icon(
              onPressed: _saving ? null : _notifyPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Generate PDF'),
            ),
            OutlinedButton.icon(
              onPressed: _saving ? null : _notifyExport,
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Export Bundle'),
            ),
            OutlinedButton.icon(
              onPressed: _saving ? null : _completeInspection,
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Complete inspection'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _optionRow(MiningAxleItem item, List<String> options) {
    final value = _answerValue(item, options);
    final needsEvidence = _requiresEvidenceBadge(item, value);
    final commentController = _commentControllerFor(item.itemKey);
    final dropdown = _dropdownField(
      item.itemKey,
      item.label,
      options,
      defaultValue: _defaultValueFor(item, options),
    );
    final comments = TextField(
      key: Key('comment_${item.itemKey}'),
      controller: commentController,
      decoration: const InputDecoration(labelText: 'Comments'),
      maxLines: 1,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (needsEvidence)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const StatusChip(
                    text: 'Evidence required',
                    color: CtsPalette.orange,
                  ),
                  OutlinedButton.icon(
                    key: Key('add_evidence_photo_${item.itemKey}'),
                    onPressed: _saving
                        ? null
                        : () =>
                              _addPhoto(item.sectionKey, itemKey: item.itemKey),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Add evidence photo'),
                  ),
                ],
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < Breakpoints.stackRow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [dropdown, const SizedBox(height: 10), comments],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: dropdown),
                  const SizedBox(width: 12),
                  Expanded(flex: 6, child: comments),
                ],
              );
            },
          ),
          if (needsEvidence) ...[
            const SizedBox(height: 8),
            PhotoGrid(
              photos: _photosForItem(item.sectionKey, item.itemKey),
              emptyLabel: 'No evidence photos attached to this item yet.',
              showAddTile: false,
              onAddPhoto: _saving
                  ? null
                  : () => _addPhoto(item.sectionKey, itemKey: item.itemKey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dropdownField(
    String key,
    String label,
    List<String> options, {
    String? defaultValue,
  }) {
    final fallback = defaultValue ?? options.first;
    final value = _answers[key] ?? fallback;
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : fallback,
      decoration: InputDecoration(labelText: label),
      items: options
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(growable: false),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() => _answers[key] = value);
      },
    );
  }

  Widget _scoreRow(String label) {
    final key = label.toLowerCase().replaceAll(' ', '_');
    final value = double.tryParse(_answers[key] ?? '8') ?? 8;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          SizedBox(
            width: 220,
            child: Slider(
              value: value,
              min: 0,
              max: 10,
              divisions: 10,
              label: value.round().toString(),
              onChanged: (value) {
                setState(() => _answers[key] = value.round().toString());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleTable({
    required String tableKey,
    required List<String> headers,
    required List<String> rows,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final valueHeaders = headers.sublist(1);
    final headerStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: scheme.onSurfaceVariant,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Narrow: render each row as a stacked, labelled card so long
        // measurement names never get squeezed into a quarter-width cell.
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              for (var r = 0; r < rows.length; r++)
                Container(
                  margin: EdgeInsets.only(
                    bottom: r == rows.length - 1 ? 0 : 10,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rows[r],
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < valueHeaders.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        TextField(
                          key: _tableFieldKey(
                            tableKey,
                            valueHeaders[i],
                            rows[r],
                          ),
                          controller: _tableControllerFor(
                            tableKey,
                            rows[r],
                            valueHeaders[i],
                          ),
                          decoration: InputDecoration(
                            labelText: valueHeaders[i],
                            isDense: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        }
        // Wide: aligned columns with a generous label column and evenly
        // weighted value columns.
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(headers.first, style: headerStyle),
                  ),
                  for (final header in valueHeaders) ...[
                    const SizedBox(width: 12),
                    Expanded(flex: 4, child: Text(header, style: headerStyle)),
                  ],
                ],
              ),
            ),
            for (final row in rows)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: scheme.outlineVariant),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        row,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    for (var i = 0; i < valueHeaders.length; i++) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: TextField(
                          key: _tableFieldKey(tableKey, valueHeaders[i], row),
                          controller: _tableControllerFor(
                            tableKey,
                            row,
                            valueHeaders[i],
                          ),
                          decoration: const InputDecoration(isDense: true),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _fieldGrid(List<_TextFieldSpec> fields) => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 12.0;
      final columns = fieldColumnsForWidth(constraints.maxWidth);
      final itemWidth = gridItemWidth(constraints.maxWidth, columns, spacing);
      return Wrap(
        spacing: spacing,
        runSpacing: 12,
        children: [
          for (final field in fields)
            SizedBox(
              width: itemWidth,
              child: TextField(
                controller: field.controller,
                decoration: InputDecoration(labelText: field.label),
              ),
            ),
        ],
      );
    },
  );

  Future<void> _loadRecord() async {
    try {
      final workspace = ref.read(workspaceProvider);
      final record = widget.inspectionId == null
          ? await workspace.createInspectionRecord()
          : await workspace.inspectionRecordById(widget.inspectionId!);
      if (!mounted) {
        return;
      }
      setState(() {
        _record = record;
        if (record != null) {
          _applyRecord(record);
        }
        _loadingRecord = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingRecord = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open inspection: $error')),
      );
    }
  }

  void _applyRecord(InspectionRecord record) {
    _customer.text = record.customer;
    _customerRepresentative.text = record.customerRepresentativeName;
    _customerUnavailableNote.text = record.customerUnavailableNote;
    _workOrder.text = record.workOrderNumber;
    _site.text = record.siteLocation;
    _equipmentMake.text = record.equipmentMake;
    _equipmentModel.text = record.equipmentModel;
    _machineSerial.text = record.machineSerialNumber;
    _axleManufacturer.text = record.axleManufacturer;
    _axleModel.text = record.axleModel;
    _axleSerial.text = record.axleSerialNumber;
    _hours.text = record.hoursOnMachine;
    _inspector.text = record.technicianName;
    _servicingShop.text = record.servicingShop;
    _purchaseOrder.text = record.purchaseOrderNumber;
    _relatedReport.text = record.relatedMachineReportDocumentNumber;
    _reviewNotes.text = record.finalTechComments;
    _criticalAcknowledged = record.criticalAcknowledged;
    _signed = (record.signatureFilePath ?? '').trim().isNotEmpty;
    _customerSigned = (record.customerSignatureFilePath ?? '')
        .trim()
        .isNotEmpty;

    _answers
      ..clear()
      ..addEntries(
        record.responses.map(
          (response) => MapEntry(response.itemKey, response.value ?? ''),
        ),
      );
    for (final item in _commentedItems) {
      _commentControllerFor(item.itemKey).text =
          record.responseByKey(item.sectionKey, item.itemKey)?.comment ?? '';
    }
    _sampleNumber.text = _answers['sample_no'] ?? '';
    _thermographyPerformed = MiningAxleTemplate.isTruthy(
      record
          .responseByKey(
            MiningAxleTemplate.temperatureAssessment,
            _thermographyPerformedKey,
          )
          ?.value,
    );
    _applyTableRows(record);
    _selectedPurposes
      ..clear()
      ..addAll(
        record.responses
            .where(
              (response) =>
                  response.sectionKey == MiningAxleTemplate.inspectionPurpose &&
                  MiningAxleTemplate.isTruthy(response.value),
            )
            .map((response) => response.itemKey),
      );
    _selectedFindings
      ..clear()
      ..addAll(
        record.responses
            .where(
              (response) =>
                  response.sectionKey ==
                      MiningAxleTemplate.conditionMonitoringFindingsSection &&
                  MiningAxleTemplate.isTruthy(response.value),
            )
            .map((response) => response.itemKey),
      );
    _findingDetails.text =
        record
            .responseByKey(
              MiningAxleTemplate.conditionMonitoringFindingsSection,
              InspectionValidator.conditionMonitoringDetailsKey,
            )
            ?.value ??
        '';
    _recommendation.text = record.recommendationRows.isEmpty
        ? ''
        : record.recommendationRows.first.recommendation;
    _recordPhotos
      ..clear()
      ..addAll(record.photos);
    _refreshPhotoViews();
  }

  Future<InspectionRecord?> _saveDraft({bool showMessage = true}) async {
    if (_record == null || _saving) {
      return _record;
    }
    setState(() => _saving = true);
    try {
      final draft = _draftFromForm();
      await _persistSignatureIfNeeded(draft);
      await _persistCustomerSignatureIfNeeded(draft);
      await ref.read(workspaceProvider).saveInspectionRecord(draft);
      final saved =
          await ref.read(workspaceProvider).inspectionRecordById(draft.id) ??
          draft;
      if (!mounted) {
        return saved;
      }
      setState(() {
        _record = saved.clone();
        _validationIssues = InspectionValidator.validateForCompletion(
          saved,
        ).issues;
        _applyRecord(saved);
      });
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Draft ${saved.documentNumber} saved locally.'),
          ),
        );
      }
      return saved;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _notifyPdf() async {
    final record = await _saveDraft(showMessage: false);
    if (!mounted || record == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(inspectionWorkflowServiceProvider)
          .generatePdf(record);
      await ref.read(workspaceProvider).refresh();
      if (!mounted) {
        return;
      }
      setState(() {
        _record = result.inspection.clone();
        _applyRecord(result.inspection);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF generated: ${result.pdfFile.path}')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _notifyExport() async {
    final record = await _saveDraft(showMessage: false);
    if (record == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(inspectionWorkflowServiceProvider)
          .exportInspection(record);
      await ref.read(workspaceProvider).refresh();
      if (!mounted) {
        return;
      }
      setState(() {
        _record = result.inspection.clone();
        _applyRecord(result.inspection);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Inspection bundle exported to ${result.exportResult.archiveFile.path}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _completeInspection() async {
    if (_record == null || _saving) {
      return;
    }
    final draft = _draftFromForm();
    final validation = InspectionValidator.validateForCompletion(draft);
    if (!validation.isValid) {
      setState(() => _validationIssues = validation.issues);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complete blocked by ${validation.issues.length} validation issue(s).',
          ),
        ),
      );
      return;
    }

    final saved = await _saveDraft(showMessage: false);
    if (saved == null) {
      return;
    }
    final result = await ref
        .read(inspectionWorkflowServiceProvider)
        .completeInspection(saved);
    await ref.read(workspaceProvider).refresh();
    if (!mounted) {
      return;
    }
    setState(() {
      _record = result.inspection.clone();
      _applyRecord(result.inspection);
    });
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete inspection'),
        content: const Text(
          'Inspection validated, signed, and saved locally as complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  InspectionRecord _draftFromForm() {
    final source = _record!;
    final draft = source.clone();
    final now = DateTime.now();
    final signatureCaptured = _signed || _signatureController.isNotEmpty;
    final customerSignatureCaptured =
        _customerSigned || _customerSignatureController.isNotEmpty;

    draft
      ..customer = _customer.text.trim()
      ..customerRepresentativeName = _customerRepresentative.text.trim()
      ..customerUnavailableNote = _customerUnavailableNote.text.trim()
      ..workOrderNumber = _workOrder.text.trim()
      ..siteLocation = _site.text.trim()
      ..equipmentMake = _equipmentMake.text.trim()
      ..equipmentModel = _equipmentModel.text.trim()
      ..machineSerialNumber = _machineSerial.text.trim()
      ..axleManufacturer = _axleManufacturer.text.trim()
      ..axleModel = _axleModel.text.trim()
      ..axleSerialNumber = _axleSerial.text.trim()
      ..hoursOnMachine = _hours.text.trim()
      ..technicianName = _inspector.text.trim()
      ..servicingShop = _servicingShop.text.trim()
      ..purchaseOrderNumber = _purchaseOrder.text.trim()
      ..relatedMachineReportDocumentNumber = _relatedReport.text.trim()
      ..assetName = _assetNameFromForm()
      ..finalTechComments = _reviewNotes.text.trim()
      ..criticalAcknowledged = _criticalAcknowledged
      ..signatureFilePath = signatureCaptured
          ? (draft.signatureFilePath ?? 'signature://${draft.id}')
          : null
      ..customerSignatureFilePath = customerSignatureCaptured
          ? (draft.customerSignatureFilePath ??
                'signature://customer/${draft.id}')
          : null
      ..customerSignatureDate = customerSignatureCaptured
          ? (draft.customerSignatureDate ?? now)
          : null
      ..responses = _responsesFor(draft, now)
      ..photos = List<InspectionPhoto>.of(_recordPhotos)
      ..oilAnalysisRows = _oilAnalysisRowsFromForm()
      ..mechanicalMeasurementRows = _mechanicalRowsFromForm()
      ..temperatureRows = _temperatureRowsFromForm()
      ..recommendationRows = _recommendation.text.trim().isEmpty
          ? <RecommendationRow>[]
          : <RecommendationRow>[
              RecommendationRow(
                priority: 'Priority 3 Monitor',
                recommendation: _recommendation.text.trim(),
              ),
            ];
    return draft;
  }

  List<InspectionResponse> _responsesFor(InspectionRecord draft, DateTime now) {
    final responses = <InspectionResponse>[];

    void addResponse(
      String sectionKey,
      String itemKey,
      String label,
      String value, {
      InspectionFieldType fieldType = InspectionFieldType.dropdown,
      ConditionRating? conditionRating,
      bool isFlagged = false,
      String? comment,
    }) {
      responses.add(
        InspectionResponse(
          id: '${draft.id}_${sectionKey}_$itemKey',
          inspectionId: draft.id,
          sectionKey: sectionKey,
          itemKey: itemKey,
          itemLabel: label,
          fieldType: fieldType,
          value: value,
          conditionRating: conditionRating,
          isFlagged: isFlagged,
          comment: comment,
          createdAt: draft.createdAt,
          updatedAt: now,
        ),
      );
    }

    for (final purpose in MiningAxleTemplate.purposeItems) {
      addResponse(
        purpose.sectionKey,
        purpose.itemKey,
        purpose.label,
        _selectedPurposes.contains(purpose.itemKey) ? 'true' : 'false',
        fieldType: InspectionFieldType.toggle,
      );
    }

    for (final item in <MiningAxleItem>[
      ...MiningAxleTemplate.visualConditionItems,
      ...MiningAxleTemplate.visualDefectItems,
      ...MiningAxleTemplate.lubricationItems,
      ...MiningAxleTemplate.differentialConditionItems,
      ...MiningAxleTemplate.planetaryHubItems,
    ]) {
      final options = _optionsFor(item);
      final value = item.rule == MiningAxleResponseRule.text
          ? (item.itemKey == 'sample_no'
                    ? _sampleNumber.text
                    : (_answers[item.itemKey] ?? ''))
                .trim()
          : _answerValue(item, options);
      final rating = _conditionRatingFor(item, value);
      addResponse(
        item.sectionKey,
        item.itemKey,
        item.label,
        value,
        fieldType: item.rule == MiningAxleResponseRule.text
            ? InspectionFieldType.text
            : InspectionFieldType.dropdown,
        conditionRating: rating,
        isFlagged: _isFlagged(item, value, rating),
        comment: _trimmedCommentFor(item.itemKey),
      );
    }

    addResponse(
      MiningAxleTemplate.temperatureAssessment,
      _thermographyPerformedKey,
      'Performed Using Infrared Thermography',
      _thermographyPerformed ? 'true' : 'false',
      fieldType: InspectionFieldType.toggle,
    );

    for (final finding in MiningAxleTemplate.conditionMonitoringFindings) {
      addResponse(
        finding.sectionKey,
        finding.itemKey,
        finding.label,
        _selectedFindings.contains(finding.itemKey) ? 'true' : 'false',
        fieldType: InspectionFieldType.toggle,
      );
    }
    addResponse(
      MiningAxleTemplate.conditionMonitoringFindingsSection,
      InspectionValidator.conditionMonitoringDetailsKey,
      'Condition Monitoring Details',
      _findingDetails.text.trim(),
      fieldType: InspectionFieldType.multilineText,
    );
    addResponse(
      MiningAxleTemplate.overallHealth,
      InspectionValidator.healthMechanicalConditionKey,
      'Mechanical Condition',
      _answers[InspectionValidator.healthMechanicalConditionKey] ?? '8',
      fieldType: InspectionFieldType.number,
    );
    addResponse(
      MiningAxleTemplate.overallHealth,
      InspectionValidator.healthLubricationConditionKey,
      'Lubrication Condition',
      _answers[InspectionValidator.healthLubricationConditionKey] ?? '8',
      fieldType: InspectionFieldType.number,
    );
    addResponse(
      MiningAxleTemplate.overallHealth,
      InspectionValidator.healthContaminationControlKey,
      'Contamination Control',
      _answers[InspectionValidator.healthContaminationControlKey] ?? '8',
      fieldType: InspectionFieldType.number,
    );
    addResponse(
      MiningAxleTemplate.overallHealth,
      InspectionValidator.healthReliabilityRiskKey,
      'Reliability Risk',
      _answers[InspectionValidator.healthReliabilityRiskKey] ?? 'Low',
    );
    addResponse(
      MiningAxleTemplate.overallHealth,
      InspectionValidator.healthOverallConditionKey,
      'Overall Condition',
      _answers[InspectionValidator.healthOverallConditionKey] ?? 'Good',
      conditionRating: _overallConditionRating(
        _answers[InspectionValidator.healthOverallConditionKey] ?? 'Good',
      ),
    );
    return responses;
  }

  static const String _thermographyPerformedKey = 'thermography_performed';

  List<MiningAxleItem> get _commentedItems => <MiningAxleItem>[
    ...MiningAxleTemplate.visualConditionItems,
    ...MiningAxleTemplate.visualDefectItems,
    ...MiningAxleTemplate.lubricationItems.where(
      (item) => item.rule != MiningAxleResponseRule.text,
    ),
    ...MiningAxleTemplate.differentialConditionItems,
    ...MiningAxleTemplate.planetaryHubItems,
  ];

  TextEditingController _commentControllerFor(String itemKey) {
    return _commentControllers.putIfAbsent(itemKey, TextEditingController.new);
  }

  String? _trimmedCommentFor(String itemKey) {
    final value = _commentControllers[itemKey]?.text.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  TextEditingController _tableControllerFor(
    String tableKey,
    String row,
    String header,
  ) {
    return _tableControllers.putIfAbsent(
      _tableControllerKey(tableKey, row, header),
      TextEditingController.new,
    );
  }

  Key _tableFieldKey(String tableKey, String header, String row) {
    return Key('${tableKey}_${_slug(header)}_${_slug(row)}');
  }

  String _tableValue(String tableKey, String row, String header) {
    return _tableControllerFor(tableKey, row, header).text.trim();
  }

  void _setTableValue(
    String tableKey,
    String row,
    String header,
    String value,
  ) {
    _tableControllerFor(tableKey, row, header).text = value;
  }

  String _tableControllerKey(String tableKey, String row, String header) {
    return '$tableKey::${_slug(row)}::${_slug(header)}';
  }

  String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  void _applyTableRows(InspectionRecord record) {
    for (final row in MiningAxleTemplate.oilAnalysisParameters) {
      final saved = record.oilAnalysisRows.cast<OilAnalysisRow?>().firstWhere(
        (entry) => entry?.parameter == row,
        orElse: () => null,
      );
      _setTableValue('oil', row, 'Result', saved?.result ?? '');
      _setTableValue('oil', row, 'Limits', saved?.limits ?? '');
    }
    for (final row in MiningAxleTemplate.mechanicalMeasurements) {
      final saved = record.mechanicalMeasurementRows
          .cast<MechanicalMeasurementRow?>()
          .firstWhere((entry) => entry?.measurement == row, orElse: () => null);
      _setTableValue(
        'measurement',
        row,
        'Specification',
        saved?.specification ?? '',
      );
      _setTableValue('measurement', row, 'Actual', saved?.actual ?? '');
      _setTableValue('measurement', row, 'Comments', saved?.comments ?? '');
    }
    for (final row in MiningAxleTemplate.temperatureLocations) {
      final saved = record.temperatureRows.cast<TemperatureRow?>().firstWhere(
        (entry) => entry?.location == row,
        orElse: () => null,
      );
      _setTableValue(
        'temperature',
        row,
        'Temperature C',
        saved?.temperatureC?.toString() ?? '',
      );
      _setTableValue('temperature', row, 'Comments', saved?.comments ?? '');
    }
  }

  List<OilAnalysisRow> _oilAnalysisRowsFromForm() {
    return MiningAxleTemplate.oilAnalysisParameters
        .map(
          (parameter) => OilAnalysisRow(
            parameter: parameter,
            result: _tableValue('oil', parameter, 'Result'),
            limits: _tableValue('oil', parameter, 'Limits'),
          ),
        )
        .where(
          (row) => row.result.trim().isNotEmpty || row.limits.trim().isNotEmpty,
        )
        .toList(growable: false);
  }

  List<MechanicalMeasurementRow> _mechanicalRowsFromForm() {
    return MiningAxleTemplate.mechanicalMeasurements
        .map(
          (measurement) => MechanicalMeasurementRow(
            measurement: measurement,
            specification: _tableValue(
              'measurement',
              measurement,
              'Specification',
            ),
            actual: _tableValue('measurement', measurement, 'Actual'),
            comments: _tableValue('measurement', measurement, 'Comments'),
          ),
        )
        .where(
          (row) =>
              row.specification.trim().isNotEmpty ||
              row.actual.trim().isNotEmpty ||
              row.comments.trim().isNotEmpty,
        )
        .toList(growable: false);
  }

  List<TemperatureRow> _temperatureRowsFromForm() {
    return MiningAxleTemplate.temperatureLocations
        .map((location) {
          final rawTemperature = _tableValue(
            'temperature',
            location,
            'Temperature C',
          );
          return TemperatureRow(
            location: location,
            temperatureC: double.tryParse(rawTemperature),
            comments: _tableValue('temperature', location, 'Comments'),
            abnormalFlagged: false,
          );
        })
        .where(
          (row) => row.temperatureC != null || row.comments.trim().isNotEmpty,
        )
        .toList(growable: false);
  }

  List<String> _visibleIssueMessages() {
    if (_record == null) {
      return const <String>[];
    }
    final issues = _validationIssues.isEmpty
        ? InspectionValidator.validateForCompletion(_draftFromForm()).issues
        : _validationIssues;
    return issues.map((issue) => issue.message).toList(growable: false);
  }

  List<InspectionPhotoView> _photosForSection(String sectionKey) {
    return _photos
        .where(
          (photo) =>
              photo.sectionTitle ==
              MiningAxleTemplate.sectionTitleFor(sectionKey),
        )
        .toList(growable: false);
  }

  List<InspectionPhotoView> _photosForItem(String sectionKey, String itemKey) {
    return _recordPhotos
        .where(
          (photo) => photo.sectionKey == sectionKey && photo.itemKey == itemKey,
        )
        .map(_photoView)
        .toList(growable: false);
  }

  void _refreshPhotoViews() {
    _photos
      ..clear()
      ..addAll(_recordPhotos.map(_photoView));
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

  List<String> _optionsFor(MiningAxleItem item) {
    return switch (item.rule) {
      MiningAxleResponseRule.condition => MiningAxleTemplate.conditionOptions,
      MiningAxleResponseRule.defect => MiningAxleTemplate.defectOptions,
      MiningAxleResponseRule.acceptable => MiningAxleTemplate.acceptableOptions,
      MiningAxleResponseRule.operational =>
        MiningAxleTemplate.operationalOptions,
      _ => const <String>[],
    };
  }

  String _answerValue(MiningAxleItem item, List<String> options) {
    return _answers[item.itemKey] ?? _defaultValueFor(item, options);
  }

  String _defaultValueFor(MiningAxleItem item, List<String> options) {
    return switch (item.rule) {
      MiningAxleResponseRule.defect => 'No',
      MiningAxleResponseRule.acceptable => 'Acceptable',
      MiningAxleResponseRule.operational => 'Operational',
      MiningAxleResponseRule.condition => 'Good',
      _ => '',
    };
  }

  bool _requiresEvidenceBadge(MiningAxleItem item, String value) {
    return switch (item.rule) {
      MiningAxleResponseRule.condition =>
        value == MiningAxleTemplate.poor ||
            value == MiningAxleTemplate.notInspected,
      MiningAxleResponseRule.defect =>
        value == MiningAxleTemplate.yes && item.itemKey != 'oil_sampling_taken',
      MiningAxleResponseRule.acceptable =>
        value == MiningAxleTemplate.notAcceptable,
      MiningAxleResponseRule.operational =>
        value == MiningAxleTemplate.notOperational,
      _ => false,
    };
  }

  ConditionRating? _conditionRatingFor(MiningAxleItem item, String value) {
    return switch (item.rule) {
      MiningAxleResponseRule.condition => switch (value) {
        MiningAxleTemplate.fair => ConditionRating.monitorAtRisk,
        MiningAxleTemplate.poor => ConditionRating.unsatisfactory,
        MiningAxleTemplate.notInspected => ConditionRating.monitorAtRisk,
        _ => ConditionRating.satisfactory,
      },
      MiningAxleResponseRule.defect =>
        value == MiningAxleTemplate.yes && item.itemKey != 'oil_sampling_taken'
            ? ConditionRating.monitorAtRisk
            : null,
      MiningAxleResponseRule.acceptable =>
        value == MiningAxleTemplate.notAcceptable
            ? ConditionRating.unsatisfactory
            : value == MiningAxleTemplate.notInspected
            ? ConditionRating.monitorAtRisk
            : null,
      MiningAxleResponseRule.operational =>
        value == MiningAxleTemplate.notOperational
            ? ConditionRating.unsatisfactory
            : value == MiningAxleTemplate.notInspected
            ? ConditionRating.monitorAtRisk
            : null,
      _ => null,
    };
  }

  bool _isFlagged(
    MiningAxleItem item,
    String value,
    ConditionRating? conditionRating,
  ) {
    return (conditionRating?.isFlagged ?? false) ||
        _requiresEvidenceBadge(item, value);
  }

  ConditionRating? _overallConditionRating(String value) {
    return switch (value) {
      MiningAxleTemplate.fair => ConditionRating.monitorAtRisk,
      MiningAxleTemplate.poor => ConditionRating.unsatisfactory,
      _ => null,
    };
  }

  String _assetNameFromForm() {
    final explicit = _record?.assetName.trim() ?? '';
    if (explicit.isNotEmpty &&
        explicit !=
            '${_record?.equipmentMake ?? ''} ${_record?.equipmentModel ?? ''} ${_record?.axleSerialNumber ?? ''}'
                .trim()) {
      return explicit;
    }
    return <String>[
      _equipmentMake.text,
      _equipmentModel.text,
      _axleSerial.text,
    ].where((value) => value.trim().isNotEmpty).join(' ').trim();
  }

  void _handleSignatureChanged() {
    final signed = _signatureController.isNotEmpty;
    if (signed != _signed && mounted) {
      setState(() => _signed = signed);
    }
  }

  void _handleCustomerSignatureChanged() {
    final signed = _customerSignatureController.isNotEmpty;
    if (signed != _customerSigned && mounted) {
      setState(() => _customerSigned = signed);
    }
  }

  Future<void> _persistSignatureIfNeeded(InspectionRecord draft) async {
    if (!_signatureController.isNotEmpty) {
      return;
    }
    final bytes = await _signatureController.toPngBytes();
    if (bytes == null || bytes.isEmpty) {
      draft.signatureFilePath = null;
      return;
    }
    final directory = await FileUtils.inspectionDirectory(draft.id);
    final file = File('${directory.path}/${AppConstants.signatureFileName}');
    await file.writeAsBytes(bytes, flush: true);
    draft.signatureFilePath = file.path;
  }

  Future<void> _persistCustomerSignatureIfNeeded(InspectionRecord draft) async {
    if (!_customerSignatureController.isNotEmpty) {
      return;
    }
    final bytes = await _customerSignatureController.toPngBytes();
    if (bytes == null || bytes.isEmpty) {
      draft.customerSignatureFilePath = null;
      draft.customerSignatureDate = null;
      return;
    }
    final directory = await FileUtils.inspectionDirectory(draft.id);
    final file = File(
      '${directory.path}/${AppConstants.customerSignatureFileName}',
    );
    await file.writeAsBytes(bytes, flush: true);
    draft.customerSignatureFilePath = file.path;
    draft.customerSignatureDate ??= DateTime.now();
  }

  Future<void> _addPhoto(String sectionKey, {String? itemKey}) async {
    if (_record == null || _saving) {
      return;
    }
    final source = await showModalBottomSheet<PhotoInputSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(PhotoInputSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(PhotoInputSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) {
      return;
    }

    final saved = await _saveDraft(showMessage: false);
    if (saved == null) {
      return;
    }
    final resolvedItemKey = itemKey ?? _defaultPhotoItemForSection(sectionKey);
    try {
      final photo = await ref
          .read(photoServiceProvider)
          .addPhoto(
            inspectionId: saved.id,
            sectionKey: sectionKey,
            itemKey: resolvedItemKey,
            source: source,
            sortOrder: _nextPhotoSortOrder(sectionKey, resolvedItemKey),
            caption: MiningAxleTemplate.itemByKey(
              sectionKey,
              resolvedItemKey,
            )?.label,
          );
      if (photo == null) {
        return;
      }
      setState(() {
        _recordPhotos.add(photo);
        _refreshPhotoViews();
      });
      final updated = await _saveDraft(showMessage: false);
      if (!mounted || updated == null) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo saved to this inspection.')),
      );
    } on PhotoServiceException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  int _nextPhotoSortOrder(String sectionKey, String itemKey) {
    return _recordPhotos
        .where(
          (photo) => photo.sectionKey == sectionKey && photo.itemKey == itemKey,
        )
        .length;
  }

  String _defaultPhotoItemForSection(String sectionKey) {
    return switch (sectionKey) {
      MiningAxleTemplate.planetaryHubInspection => 'sun_gear',
      _ => 'axle_housing',
    };
  }

  void _jumpTo(String key) {
    final target = _keys[key]?.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.isEdit,
    required this.documentNumber,
    required this.isSaving,
    required this.onSaveDraft,
    required this.onGeneratePdf,
    required this.onComplete,
  });

  final bool isEdit;
  final String documentNumber;
  final bool isSaving;
  final VoidCallback onSaveDraft;
  final VoidCallback onGeneratePdf;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            StatusChip(text: documentNumber, color: CtsPalette.orangeSoft),
            if (isSaving)
              const StatusChip(text: 'Saving', color: CtsPalette.info),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          isEdit ? 'Edit Mining Axle Inspection' : 'New Mining Axle Inspection',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'One axle per report — local storage, validation, evidence, '
          'signoff, PDF, share, and export.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            height: 1.35,
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: isSaving ? null : onSaveDraft,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Draft'),
        ),
        FilledButton.icon(
          onPressed: isSaving ? null : onGeneratePdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Generate PDF'),
        ),
        OutlinedButton.icon(
          onPressed: isSaving ? null : onComplete,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
          ),
          icon: const Icon(Icons.verified_outlined),
          label: const Text('Mark complete'),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [CtsPalette.navyAlt, CtsPalette.navy, Color(0xFF132944)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [heading, const SizedBox(height: 16), actions],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: heading),
              const SizedBox(width: 18),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _SectionRail extends StatelessWidget {
  const _SectionRail({required this.sections, required this.onJump});

  final List<_SectionState> sections;
  final ValueChanged<String> onJump;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Sections',
      subtitle: 'Tap to jump.',
      child: Column(
        children: [
          for (final section in sections) ...[
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onJump(section.key),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  section.title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (section != sections.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.issues,
    required this.photos,
    required this.onJump,
  });

  final List<String> issues;
  final List<InspectionPhotoView> photos;
  final ValueChanged<String> onJump;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SectionCard(
            title: 'Validation',
            subtitle: 'Completion blockers.',
            child: Column(
              children: [
                for (final issue in issues.take(8)) ...[
                  _IssueTile(issue),
                  const SizedBox(height: 8),
                ],
                if (issues.isEmpty)
                  const _IssueTile('No blocking issues currently visible.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => onJump(MiningAxleTemplate.overallHealth),
                  child: const Text('Jump to health'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Photos',
            subtitle: 'Local evidence stack.',
            child: PhotoGrid(photos: photos),
          ),
        ],
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CtsPalette.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TextFieldSpec {
  const _TextFieldSpec(this.controller, this.label);

  final TextEditingController controller;
  final String label;
}

class _SectionState {
  const _SectionState(this.key, this.title, this.status);

  final String key;
  final String title;
  final SectionCompletionState status;
}
