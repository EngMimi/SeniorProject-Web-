import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// A navigation entry inside a role shell.
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;
}

/// Structural scaffold shared by the role shells: a branded app bar,
/// role-specific navigation, and the routed [child] as the body.
///
/// Uses an extended [NavigationRail] on wide windows, a compact rail on
/// medium/laptop widths and a [NavigationBar] on compact widths.
class RoleShellScaffold extends StatelessWidget {
  const RoleShellScaffold({
    super.key,
    required this.title,
    required this.destinations,
    required this.child,
  });

  /// Window width from which the rail shows labels beside the icons.
  static const double _extendedRailMinWidth = 1200;

  /// Role name shown next to the product name, e.g. "Doctor".
  final String title;
  final List<ShellDestination> destinations;
  final Widget child;

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = destinations.indexWhere((d) => location.startsWith(d.path));
    return index < 0 ? 0 : index;
  }

  void _onSelected(BuildContext context, int index) {
    context.go(destinations[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final compact = context.isCompact;
    final extended = MediaQuery.sizeOf(context).width >= _extendedRailMinWidth;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: _ShellTitle(role: title),
      ),
      body: compact
          ? child
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (i) => _onSelected(context, i),
                  extended: extended,
                  minExtendedWidth: 220,
                  labelType: extended ? null : NavigationRailLabelType.all,
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
      bottomNavigationBar: compact
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => _onSelected(context, i),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(icon: Icon(d.icon), label: d.label),
              ],
            )
          : null,
    );
  }
}

class _ShellTitle extends StatelessWidget {
  const _ShellTitle({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: AppRadius.smAll,
            ),
            child: const Icon(
              Icons.psychology_outlined,
              size: 20,
              color: AppColors.onNavy,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            'NeuroInsight-PD',
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(
          height: 20,
          child: VerticalDivider(width: AppSpacing.lg),
        ),
        Text(
          role,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
