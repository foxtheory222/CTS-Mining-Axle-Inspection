import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../core/theme.dart';

class SignaturePad extends StatelessWidget {
  const SignaturePad({
    super.key,
    required this.controller,
    required this.isSigned,
    required this.onClear,
    this.title = 'Technician signature',
  });

  final SignatureController controller;
  final bool isSigned;
  final VoidCallback onClear;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 12),
            if (isSigned)
              const StatusChip(text: 'Captured', color: CtsPalette.success),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Signature(
              controller: controller,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final clearButton = OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
              label: const Text('Clear signature'),
            );
            final guidance = Text(
              'Draw the signature with a stylus or finger.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
            if (constraints.maxWidth < 620) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [clearButton, const SizedBox(height: 8), guidance],
              );
            }
            return Row(
              children: [
                clearButton,
                const SizedBox(width: 12),
                Expanded(child: guidance),
              ],
            );
          },
        ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.text,
    required this.color,
    this.onDarkSurface = false,
  });

  final String text;
  final Color color;
  final bool onDarkSurface;

  @override
  Widget build(BuildContext context) {
    final foreground = onDarkSurface
        ? color
        : accessibleTintForeground(context, color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
