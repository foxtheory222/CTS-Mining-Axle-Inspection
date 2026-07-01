import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../widgets/section_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      children: const [
                        Expanded(child: _SettingsPanel()),
                        SizedBox(width: 18),
                        SizedBox(width: 360, child: _AboutPanel()),
                      ],
                    )
                  : const Column(
                      children: [
                        _SettingsPanel(),
                        SizedBox(height: 18),
                        _AboutPanel(),
                      ],
                    );
            },
          ),
        ],
      ),
    );
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
