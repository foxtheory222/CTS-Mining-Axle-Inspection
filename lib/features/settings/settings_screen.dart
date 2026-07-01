import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/workspace_providers.dart';
import '../../data/models/inspection_models.dart';
import '../../services/backup_service.dart';
import '../backup_import_export/backup_import_export_panel.dart';
import '../../widgets/section_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _lastExportPath;
  String? _lastImportPath;

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Settings',
            subtitle:
                'Tablet-safe local workflow settings and display preferences.',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _SettingsChip(text: 'Offline-first'),
                _SettingsChip(text: 'Local storage only'),
                _SettingsChip(text: 'Landscape preferred'),
                _SettingsChip(text: 'Large touch targets'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1180;
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const _SettingsPanel(),
                              const SizedBox(height: 18),
                              BackupImportExportPanel(
                                onExportPressed: workspace.inspections.isEmpty
                                    ? null
                                    : _exportLatestInspection,
                                onImportPressed: _importInspectionBundle,
                                lastExportPath: _lastExportPath,
                                lastImportPath: _lastImportPath,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        const SizedBox(width: 360, child: _AboutPanel()),
                      ],
                    )
                  : Column(
                      children: [
                        const _SettingsPanel(),
                        const SizedBox(height: 18),
                        BackupImportExportPanel(
                          onExportPressed: workspace.inspections.isEmpty
                              ? null
                              : _exportLatestInspection,
                          onImportPressed: _importInspectionBundle,
                          lastExportPath: _lastExportPath,
                          lastImportPath: _lastImportPath,
                        ),
                        const SizedBox(height: 18),
                        const _AboutPanel(),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportLatestInspection() async {
    final workspace = ref.read(workspaceProvider);
    if (workspace.recentInspections.isEmpty) {
      _showMessage('No inspection is available to export.');
      return;
    }
    final summary = workspace.recentInspections.first;
    final record = await workspace.inspectionRecordById(summary.id);
    if (record == null) {
      _showMessage('Inspection ${summary.documentNumber} was not found.');
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
    setState(() => _lastExportPath = result.archiveFile.path);
    _showMessage('Exported ${record.documentNumber}.');
  }

  Future<void> _importInspectionBundle() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['zip'],
      allowMultiple: false,
    );
    final path = picked?.files.single.path;
    if (path == null) {
      return;
    }

    try {
      final workspace = ref.read(workspaceProvider);
      final result = await ref
          .read(backupServiceProvider)
          .importInspection(
            archiveFile: File(path),
            existingDocumentNumbers: workspace.documentNumbers,
          );
      final record = InspectionRecord.fromJson(result.inspectionJson)
        ..restoredFromExportPath = path;
      await workspace.saveInspectionRecord(record);
      if (!mounted) {
        return;
      }
      setState(() => _lastImportPath = path);
      _showMessage('Imported ${record.documentNumber}.');
    } on BackupServiceException catch (error) {
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingsPanel extends StatefulWidget {
  const _SettingsPanel();

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  bool _lockLandscape = true;
  bool _compressImages = true;
  bool _saveRecipients = true;
  bool _useBrandedTheme = true;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Workflow Preferences',
      subtitle: 'These settings align the UI to the current V1 tablet scope.',
      child: Column(
        children: [
          SwitchListTile(
            value: _lockLandscape,
            onChanged: (value) => setState(() => _lockLandscape = value),
            title: const Text('Lock landscape mode'),
            subtitle: const Text('Keep the UI optimized for 10-inch tablets.'),
            activeThumbColor: CtsPalette.orange,
          ),
          SwitchListTile(
            value: _compressImages,
            onChanged: (value) => setState(() => _compressImages = value),
            title: const Text('Compress images for report output'),
            subtitle: const Text(
              'Keeps PDFs readable without unnecessary file size.',
            ),
            activeThumbColor: CtsPalette.orange,
          ),
          SwitchListTile(
            value: _saveRecipients,
            onChanged: (value) => setState(() => _saveRecipients = value),
            title: const Text('Save recent email recipients'),
            subtitle: const Text(
              'Recent addresses stay available for handoff workflows.',
            ),
            activeThumbColor: CtsPalette.orange,
          ),
          SwitchListTile(
            value: _useBrandedTheme,
            onChanged: (value) => setState(() => _useBrandedTheme = value),
            title: const Text('Use branded industrial theme'),
            subtitle: const Text(
              'Deep navy, slate, and safety orange palette.',
            ),
            activeThumbColor: CtsPalette.orange,
          ),
        ],
      ),
    );
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'App Notes',
      subtitle: 'Version and template details for the current build.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InfoRow(label: 'App version', value: '1.0.0'),
          const _InfoRow(
            label: 'Template version',
            value: AppConstants.templateVersion,
          ),
          const SizedBox(height: 12),
          const _Note(text: 'Local-only Android tablet workflow.'),
          const _Note(text: 'Template key: mining_axle_inspection.'),
          const _Note(text: 'No cloud sync, login, GPS, or direct email send.'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.fiber_manual_record,
            size: 10,
            color: CtsPalette.orange,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _SettingsChip extends StatelessWidget {
  const _SettingsChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      backgroundColor: CtsPalette.orange.withValues(alpha: 0.12),
      side: BorderSide(color: CtsPalette.orange.withValues(alpha: 0.24)),
    );
  }
}
