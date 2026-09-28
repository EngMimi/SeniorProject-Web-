import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'breadcrumbs.dart';

/// Page title block with optional breadcrumbs, subtitle and actions.
///
/// Actions sit to the right of the title on wide layouts and wrap below it
/// on narrow ones.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<BreadcrumbItem>? breadcrumbs;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    final actionsBlock = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: actions,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (breadcrumbs case final items?) ...[
          Breadcrumbs(items: items),
          const SizedBox(height: AppSpacing.sm),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            if (actions.isEmpty) return titleBlock;
            if (constraints.maxWidth < 720) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.md,
                children: [titleBlock, actionsBlock],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: AppSpacing.lg),
                actionsBlock,
              ],
            );
          },
        ),
      ],
    );
  }
}
