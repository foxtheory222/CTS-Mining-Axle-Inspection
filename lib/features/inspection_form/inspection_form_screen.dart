import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';

import '../../core/mining_axle_template.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/workspace_models.dart';
import '../../core/workspace_providers.dart';
import '../../data/models/inspection_enums.dart';
import '../../data/models/inspection_models.dart';
import '../../services/backup_service.dart';
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
  late final Map<String, GlobalKey> _keys;
  late final TextEditingController _customer;
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
    _keys = {for (final section in _sections) section.key: GlobalKey()};

    _customer = TextEditingController();
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
    _customer.dispose();
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
        final showRail = constraints.maxWidth >= 1120;
        final showSummary = constraints.maxWidth >= 1350;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showRail) ...[
              SizedBox(
                width: 250,
                child: SingleChildScrollView(
                  child: _SectionRail(sections: _sections, onJump: _jumpTo),
                ),
              ),
              const SizedBox(width: 18),
            ],
            Expanded(
              child: SingleChildScrollView(
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
                    const SizedBox(height: 18),
                    _purposeSection(),
                    const SizedBox(height: 18),
                    _visualSection(),
                    const SizedBox(height: 18),
                    _lubricationSection(),
                    const SizedBox(height: 18),
                    _differentialSection(),
                    const SizedBox(height: 18),
                    _planetarySection(),
                    const SizedBox(height: 18),
                    _measurementSection(),
                    const SizedBox(height: 18),
                    _temperatureSection(),
                    const SizedBox(height: 18),
                    _findingsSection(),
                    const SizedBox(height: 18),
                    _recommendationsSection(),
                    const SizedBox(height: 18),
                    _healthSection(),
                    const SizedBox(height: 18),
                    _reviewSection(issues),
                  ],
                ),
              ),
            ),
            if (showSummary) ...[
              const SizedBox(width: 18),
              SizedBox(
                width: 360,
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
        ),
      ],
    ),
  );

  Widget _measurementSection() => SectionCard(
    key: _keys[MiningAxleTemplate.mechanicalMeasurementsSection],
    title: 'Mechanical Measurements',
    subtitle: 'Specifications and actual values are free text for V1.',
    child: _simpleTable(
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
          value: _thermographyPerformed,
          onChanged: (value) => setState(() => _thermographyPerformed = value),
          title: const Text('Performed Using Infrared Thermography'),
          activeThumbColor: CtsPalette.orange,
        ),
        _simpleTable(
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _dropdownField(
              item.itemKey,
              item.label,
              options,
              defaultValue: _defaultValueFor(item, options),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            flex: 3,
            child: TextField(
              decoration: InputDecoration(labelText: 'Comments'),
              maxLines: 1,
            ),
          ),
          if (_requiresEvidenceBadge(item, value)) ...[
            const SizedBox(width: 12),
            const StatusChip(
              text: 'Evidence required',
              color: CtsPalette.orange,
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
    required List<String> headers,
    required List<String> rows,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              for (final header in headers)
                Expanded(
                  child: Text(
                    header,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
        ),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(child: Text(row)),
                for (var i = 1; i < headers.length; i++) ...[
                  const SizedBox(width: 8),
                  const Expanded(child: TextField()),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _fieldGrid(List<_TextFieldSpec> fields) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1100
          ? 3
          : constraints.maxWidth >= 760
          ? 2
          : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: fields.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 3.0 : 2.5,
        ),
        itemBuilder: (context, index) {
          final field = fields[index];
          return TextField(
            controller: field.controller,
            decoration: InputDecoration(labelText: field.label),
          );
        },
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

    _answers
      ..clear()
      ..addEntries(
        record.responses.map(
          (response) => MapEntry(response.itemKey, response.value ?? ''),
        ),
      );
    _sampleNumber.text = _answers['sample_no'] ?? '';
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
      await ref.read(workspaceProvider).saveInspectionRecord(draft);
      if (!mounted) {
        return draft;
      }
      setState(() {
        _record = draft.clone();
        _validationIssues = InspectionValidator.validateForCompletion(
          draft,
        ).issues;
      });
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Draft ${draft.documentNumber} saved locally.'),
          ),
        );
      }
      return draft;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _notifyPdf() async {
    await _saveDraft(showMessage: false);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF data saved locally for generation.')),
    );
  }

  Future<void> _notifyExport() async {
    final record = await _saveDraft(showMessage: false);
    if (record == null) {
      return;
    }
    final result = await ref
        .read(backupServiceProvider)
        .exportInspection(
          data: InspectionBackupData(
            inspectionJson: record.toJson(),
            documentNumber: record.documentNumber,
            customer: record.customer,
            workOrderNumber: record.workOrderNumber,
            axleSerialNumber: record.axleSerialNumber,
            machineSerialNumber: record.machineSerialNumber,
            photoFiles: record.photos
                .map((photo) => File(photo.filePath))
                .toList(),
            generatedPdfFile: record.generatedPdfPath == null
                ? null
                : File(record.generatedPdfPath!),
          ),
        );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Inspection bundle exported to ${result.archiveFile.path}',
        ),
      ),
    );
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

    await _saveDraft(showMessage: false);
    if (!mounted) {
      return;
    }
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

    draft
      ..customer = _customer.text.trim()
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
      ..responses = _responsesFor(draft, now)
      ..photos = List<InspectionPhoto>.of(_recordPhotos)
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
      );
    }

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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [CtsPalette.navyAlt, CtsPalette.navy, Color(0xFF132944)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    StatusChip(
                      text: documentNumber,
                      color: CtsPalette.orangeSoft,
                    ),
                    if (isSaving)
                      const StatusChip(text: 'Saving', color: CtsPalette.info),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isEdit
                      ? 'Edit Mining Axle Inspection'
                      : 'New Mining Axle Inspection',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Landscape tablet workflow for one axle per report with local SQLite storage, validation, evidence, signoff, PDF, share, export, and import handoff.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Wrap(
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
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Mark complete'),
              ),
            ],
          ),
        ],
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
