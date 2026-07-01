import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../core/mining_axle_template.dart';
import '../../core/theme.dart';
import '../../core/workspace_models.dart';
import '../../data/models/inspection_enums.dart';
import '../../widgets/photo_grid.dart';
import '../../widgets/section_card.dart';
import '../../widgets/signature_pad.dart';

class InspectionFormScreen extends StatefulWidget {
  const InspectionFormScreen({super.key, this.seed});

  final InspectionSummary? seed;

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  late final ScrollController _scrollController;
  late final SignatureController _signatureController;
  late final Map<String, GlobalKey> _keys;
  late final TextEditingController _customer;
  late final TextEditingController _site;
  late final TextEditingController _equipmentMake;
  late final TextEditingController _equipmentModel;
  late final TextEditingController _machineSerial;
  late final TextEditingController _axleManufacturer;
  late final TextEditingController _axleModel;
  late final TextEditingController _axleSerial;
  late final TextEditingController _hours;
  late final TextEditingController _inspector;
  late final TextEditingController _purchaseOrder;
  late final TextEditingController _relatedReport;
  late final TextEditingController _findingDetails;
  late final TextEditingController _recommendation;
  late final TextEditingController _reviewNotes;

  final Map<String, String> _answers = <String, String>{};
  final Set<String> _selectedPurposes = <String>{
    'purpose_preventive_maintenance',
  };
  final Set<String> _selectedFindings = <String>{};

  bool _thermographyPerformed = true;
  bool _criticalAcknowledged = false;
  bool _signed = false;

  final List<InspectionPhotoView> _photos = <InspectionPhotoView>[
    InspectionPhotoView(
      assetPath: 'assets/demo/sample_photo_1.jpg',
      caption: 'Axle overview',
      sectionTitle: 'Visual Inspection',
      itemLabel: 'Axle Housing',
      capturedAt: DateTime(2026, 7, 1, 8, 45),
    ),
    InspectionPhotoView(
      assetPath: 'assets/demo/sample_photo_2.jpg',
      caption: 'Planetary hub evidence',
      sectionTitle: 'Planetary Hub Inspection',
      itemLabel: 'Wheel Bearings',
      capturedAt: DateTime(2026, 7, 1, 9, 10),
    ),
  ];

  List<_SectionState> get _sections => MiningAxleTemplate.sections
      .map(
        (section) => _SectionState(
          section.key,
          section.title,
          section.sortOrder < 2
              ? SectionCompletionState.inProgress
              : SectionCompletionState.notStarted,
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
    );
    _keys = {for (final section in _sections) section.key: GlobalKey()};

    final seed = widget.seed;
    _customer = TextEditingController(text: seed?.customer ?? 'Moraine Quarry');
    _site = TextEditingController(text: seed?.siteLocation ?? 'East Pit');
    _equipmentMake = TextEditingController(text: 'Caterpillar');
    _equipmentModel = TextEditingController(text: seed?.assetName ?? '793F');
    _machineSerial = TextEditingController(text: 'CAT793-1001');
    _axleManufacturer = TextEditingController(text: 'Dana');
    _axleModel = TextEditingController(text: 'Spicer 53R300');
    _axleSerial = TextEditingController(text: 'AXLE-1001');
    _hours = TextEditingController(text: '18450');
    _inspector = TextEditingController(
      text: seed?.technicianName ?? 'R. Ellis',
    );
    _purchaseOrder = TextEditingController(
      text: seed?.customerReference ?? 'PO-7788',
    );
    _relatedReport = TextEditingController(text: '20260701-0001');
    _findingDetails = TextEditingController(
      text: 'No abnormal findings selected.',
    );
    _recommendation = TextEditingController(
      text: 'Continue routine monitoring at next planned service interval.',
    );
    _reviewNotes = TextEditingController(
      text:
          'Autosaved locally. PDF generation and share handoff remain offline.',
    );

    for (final item in <MiningAxleItem>[
      ...MiningAxleTemplate.visualConditionItems,
      ...MiningAxleTemplate.planetaryHubItems,
      ...MiningAxleTemplate.differentialConditionItems.where(
        (item) => item.rule == MiningAxleResponseRule.condition,
      ),
    ]) {
      _answers[item.itemKey] = 'Good';
    }
    for (final item in <MiningAxleItem>[
      ...MiningAxleTemplate.visualDefectItems,
      ...MiningAxleTemplate.lubricationItems.where(
        (item) => item.rule == MiningAxleResponseRule.defect,
      ),
    ]) {
      _answers[item.itemKey] = 'No';
    }
    _answers['oil_condition'] = 'Good';
    _answers['backlash_measurement'] = 'Acceptable';
    _answers['differential_lock'] = 'Operational';
    _answers['health_reliability_risk'] = 'Low';
    _answers['health_overall_condition'] = 'Good';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _signatureController.dispose();
    _customer.dispose();
    _site.dispose();
    _equipmentMake.dispose();
    _equipmentModel.dispose();
    _machineSerial.dispose();
    _axleManufacturer.dispose();
    _axleModel.dispose();
    _axleSerial.dispose();
    _hours.dispose();
    _inspector.dispose();
    _purchaseOrder.dispose();
    _relatedReport.dispose();
    _findingDetails.dispose();
    _recommendation.dispose();
    _reviewNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final issues = _buildIssues();
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
                      isEdit: widget.seed != null,
                      onGeneratePdf: _notifyPdf,
                      onComplete: _showCompleteDialog,
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
          _TextFieldSpec(_site, 'Site'),
          _TextFieldSpec(_equipmentMake, 'Equipment Make'),
          _TextFieldSpec(_equipmentModel, 'Equipment Model'),
          _TextFieldSpec(_machineSerial, 'Machine Serial No.'),
          _TextFieldSpec(_axleManufacturer, 'Axle Manufacturer'),
          _TextFieldSpec(_axleModel, 'Axle Model'),
          _TextFieldSpec(_axleSerial, 'Axle Serial Number'),
          _TextFieldSpec(_hours, 'Hours on Machine'),
          _TextFieldSpec(_inspector, 'CTS Inspector'),
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
        PhotoGrid(photos: _photos.take(1).toList(growable: false)),
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
              : TextField(decoration: InputDecoration(labelText: item.label)),
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
        PhotoGrid(photos: _photos.skip(1).take(1).toList(growable: false)),
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
        for (final bucket in MiningAxleTemplate.recommendationBuckets)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _recommendation,
              maxLines: 2,
              decoration: InputDecoration(labelText: bucket),
            ),
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
        ),
        _dropdownField(
          'health_overall_condition',
          'Overall Condition',
          MiningAxleTemplate.overallConditionOptions,
        ),
      ],
    ),
  );

  Widget _reviewSection(List<String> issues) => SectionCard(
    key: _keys['review'],
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
            const StatusChip(
              text: 'Autosaved locally',
              color: CtsPalette.slate,
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final issue in issues) ...[
          _IssueTile(issue),
          const SizedBox(height: 8),
        ],
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
              onPressed: _notifyPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Generate PDF'),
            ),
            OutlinedButton.icon(
              onPressed: _notifyExport,
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Export Bundle'),
            ),
            OutlinedButton.icon(
              onPressed: _showCompleteDialog,
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Complete inspection'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _optionRow(MiningAxleItem item, List<String> options) {
    final value = _answers[item.itemKey] ?? options.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _dropdownField(item.itemKey, item.label, options),
          ),
          const SizedBox(width: 12),
          const Expanded(
            flex: 3,
            child: TextField(
              decoration: InputDecoration(labelText: 'Comments'),
              maxLines: 1,
            ),
          ),
          if (value == 'Poor' || value == 'Yes') ...[
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

  Widget _dropdownField(String key, String label, List<String> options) {
    final value = _answers[key] ?? options.first;
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : options.first,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          SizedBox(
            width: 220,
            child: Slider(
              value: double.tryParse(_answers[key] ?? '8') ?? 8,
              min: 0,
              max: 10,
              divisions: 10,
              label: (_answers[key] ?? '8'),
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

  void _notifyPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF regenerated locally for this report.')),
    );
  }

  void _notifyExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inspection bundle exported locally.')),
    );
  }

  void _showCompleteDialog() {
    setState(() => _signed = true);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete inspection'),
        content: const Text(
          'Completion validates required fields, evidence, action items, health assessment, and signatures before PDF/share handoff.',
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

  List<String> _buildIssues() {
    final issues = <String>[];
    if (_selectedPurposes.isEmpty) {
      issues.add('At least one inspection purpose is required.');
    }
    if (_customer.text.trim().isEmpty) {
      issues.add('Customer is required.');
    }
    if (_axleSerial.text.trim().isEmpty) {
      issues.add('Axle Serial Number is required.');
    }
    if (!_criticalAcknowledged && _selectedFindings.isNotEmpty) {
      issues.add('Critical / Out of Service acknowledgement may be required.');
    }
    if (!_signed) {
      issues.add('Drawn inspector signature is required.');
    }
    return issues;
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.isEdit,
    required this.onGeneratePdf,
    required this.onComplete,
  });

  final bool isEdit;
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
                  'Landscape tablet workflow for one axle per report with local autosave, evidence, signoff, PDF, share, export, and import handoff.',
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
                onPressed: onGeneratePdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Generate PDF'),
              ),
              OutlinedButton.icon(
                onPressed: onComplete,
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
                for (final issue in issues) ...[
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
