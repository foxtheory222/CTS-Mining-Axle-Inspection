import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/inspection_enums.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.tight = false,
    this.onDarkSurface = false,
  });

  factory StatusBadge.forInspection(
    InspectionStatus status, {
    bool onDarkSurface = false,
  }) {
    switch (status) {
      case InspectionStatus.draft:
        return StatusBadge(
          label: 'Draft',
          color: CtsPalette.slate,
          icon: Icons.description_outlined,
          onDarkSurface: onDarkSurface,
        );
      case InspectionStatus.inProgress:
        return StatusBadge(
          label: 'In Progress',
          color: CtsPalette.orange,
          icon: Icons.play_circle_outline,
          onDarkSurface: onDarkSurface,
        );
      case InspectionStatus.complete:
        return StatusBadge(
          label: 'Complete',
          color: CtsPalette.success,
          icon: Icons.verified_outlined,
          onDarkSurface: onDarkSurface,
        );
      case InspectionStatus.emailed:
        return StatusBadge(
          label: 'Emailed',
          color: CtsPalette.info,
          icon: Icons.mark_email_read_outlined,
          onDarkSurface: onDarkSurface,
        );
    }
  }

  factory StatusBadge.forCondition(ConditionRating rating) {
    switch (rating) {
      case ConditionRating.satisfactory:
        return const StatusBadge(
          label: 'Satisfactory',
          color: CtsPalette.success,
          icon: Icons.check_circle_outline,
        );
      case ConditionRating.monitorAtRisk:
        return const StatusBadge(
          label: 'At Risk',
          color: CtsPalette.warning,
          icon: Icons.visibility_outlined,
        );
      case ConditionRating.unsatisfactory:
        return const StatusBadge(
          label: 'Unsatisfactory',
          color: CtsPalette.orange,
          icon: Icons.error_outline,
        );
      case ConditionRating.criticalOutOfService:
        return const StatusBadge(
          label: 'Critical',
          color: CtsPalette.danger,
          icon: Icons.warning_amber_rounded,
        );
    }
  }

  final String label;
  final Color color;
  final IconData? icon;
  final bool tight;
  final bool onDarkSurface;

  @override
  Widget build(BuildContext context) {
    final foreground = onDarkSurface
        ? color
        : accessibleTintForeground(context, color);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tight ? 10 : 12,
        vertical: tight ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
