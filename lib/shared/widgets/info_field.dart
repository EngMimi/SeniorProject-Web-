import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// A label/value pair, e.g. "Age" / "67".
class InfoField extends StatelessWidget {
  const InfoField({super.key, required this.label, this.value, this.child})
    : assert((value == null) != (child == null), 'Provide value or child');

  final String label;
  final String? value;

  /// Custom value widget (e.g. a status badge) instead of [value].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        child ??
            Text(
              value!,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
      ],
    );
  }
}

/// Lays out [InfoField]s in a wrapping grid of equal-width cells.
class InfoGrid extends StatelessWidget {
  const InfoGrid({super.key, required this.fields, this.minFieldWidth = 150});

  final List<Widget> fields;
  final double minFieldWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.lg;
        final perRow =
            ((constraints.maxWidth + spacing) / (minFieldWidth + spacing))
                .floor()
                .clamp(1, fields.length);
        final width = (constraints.maxWidth - spacing * (perRow - 1)) / perRow;

        return Wrap(
          spacing: spacing,
          runSpacing: AppSpacing.md,
          children: [
            for (final field in fields) SizedBox(width: width, child: field),
          ],
        );
      },
    );
  }
}
