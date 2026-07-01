import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../core/workspace_providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(workspaceProvider);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CtsPalette.navy, Color(0xFF07142A), Color(0xFF0A1322)],
            stops: [0.0, 0.38, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1240;
              final railWidth = wide ? 244.0 : 116.0;
              return Row(
                children: [
                  SizedBox(
                    width: railWidth,
                    child: _SidebarRail(
                      extended: wide,
                      selectedIndex: selectedIndex,
                      onDestinationSelected: onDestinationSelected,
                      totalRecords: controller.inspections.length,
                      criticalRecords: controller.inspections
                          .where((inspection) => inspection.criticalCount > 0)
                          .length,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _TopStrip(
                          wide: wide,
                          metricValue: controller.inspections.length.toString(),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopStrip extends StatelessWidget {
  const _TopStrip({required this.wide, required this.metricValue});

  final bool wide;
  final String metricValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showSubtitle = constraints.maxWidth >= 900;
          final brand = _BrandBlock(showSubtitle: showSubtitle);
          final statusPills = _StatusPills(metricValue: metricValue);

          if (constraints.maxWidth < 700) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [brand, const SizedBox(height: 12), statusPills],
            );
          }
          return Row(
            children: [
              Expanded(child: brand),
              const SizedBox(width: 12),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: statusPills,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({required this.showSubtitle});

  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            'assets/logo/cts_logo.png',
            height: 34,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppConstants.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (showSubtitle) ...[
                const SizedBox(height: 2),
                Text(
                  'Offline mining axle inspection workflow',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPills extends StatelessWidget {
  const _StatusPills({required this.metricValue});

  final String metricValue;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        _TopStatusPill(
          icon: Icons.sync,
          label: 'Local data only',
          color: CtsPalette.orange,
        ),
        _TopStatusPill(
          icon: Icons.lock_outline,
          label: 'Offline ready',
          color: CtsPalette.success,
        ),
        _TopStatusPill(
          icon: Icons.list_alt_rounded,
          label: '$metricValue records',
          color: CtsPalette.info,
        ),
      ],
    );
  }
}

class _TopStatusPill extends StatelessWidget {
  const _TopStatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarRail extends StatelessWidget {
  const _SidebarRail({
    required this.extended,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.totalRecords,
    required this.criticalRecords,
  });

  final bool extended;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final int totalRecords;
  final int criticalRecords;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: extended
          ? const EdgeInsets.fromLTRB(16, 0, 12, 16)
          : const EdgeInsets.fromLTRB(8, 0, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(extended ? 24 : 20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          if (extended)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: CtsPalette.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Inspection Suite',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 6),
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: CtsPalette.orange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Expanded(
            child: NavigationRail(
              extended: extended,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: extended ? null : NavigationRailLabelType.all,
              minWidth: 100,
              groupAlignment: -0.85,
              leading: const SizedBox(height: 2),
              trailing: extended
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        children: [
                          _RailHint(
                            icon: Icons.today_outlined,
                            title: 'Active',
                            value: totalRecords.toString(),
                          ),
                          const SizedBox(height: 8),
                          _RailHint(
                            icon: Icons.warning_amber_rounded,
                            title: 'Critical',
                            value: criticalRecords.toString(),
                            tint: CtsPalette.danger,
                          ),
                        ],
                      ),
                    )
                  : null,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard_rounded),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search_rounded),
                  label: Text('Inspections'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.edit_document),
                  selectedIcon: Icon(Icons.edit_document),
                  label: Text('New Inspection'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assignment_turned_in_outlined),
                  selectedIcon: Icon(Icons.assignment_turned_in),
                  label: Text('Action Items'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
          ),
          if (extended)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Landscape tablet layout with large touch targets and high-contrast controls.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.66),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RailHint extends StatelessWidget {
  const _RailHint({
    required this.icon,
    required this.title,
    required this.value,
    this.tint = CtsPalette.orange,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: tint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
