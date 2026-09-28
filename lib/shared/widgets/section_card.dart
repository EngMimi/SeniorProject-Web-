import 'package:flutter/material.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Titled card used to group a page section.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.padBody = true,
    this.color,
    this.borderColor,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  /// Set to false for edge-to-edge content such as tables.
  final bool padBody;
  final Color? color;
  final Color? borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = context.isCompact ? AppSpacing.md : AppSpacing.lg;

    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      shape: borderColor == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: AppRadius.lgAll,
              side: BorderSide(color: borderColor!),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              padding,
              padding,
              padding,
              AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon case final icon?) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      icon,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (subtitle case final subtitle?) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing case final trailing?) ...[
                  const SizedBox(width: AppSpacing.md),
                  trailing,
                ],
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          if (padBody)
            Padding(padding: EdgeInsets.all(padding), child: child)
          else
            child,
        ],
      ),
    );
  }
}
