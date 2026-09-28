import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class TableColumnDef<T> {
  const TableColumnDef({
    required this.label,
    required this.cellBuilder,
    this.flex = 1,
    this.alignEnd = false,
  });

  final String label;
  final Widget Function(BuildContext context, T row) cellBuilder;
  final int flex;
  final bool alignEnd;
}

/// A table that switches to a stacked list on narrow widths, so it never
/// breaks the layout or needs horizontal scrolling.
class ResponsiveTable<T> extends StatelessWidget {
  const ResponsiveTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.compactRowBuilder,
    this.emptyMessage = 'No records to show.',
    this.compactBreakpoint = 720,
  });

  final List<TableColumnDef<T>> columns;
  final List<T> rows;

  /// Builds one row for the stacked (narrow) layout.
  final Widget Function(BuildContext context, T row) compactRowBuilder;
  final String emptyMessage;
  final double compactBreakpoint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < compactBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, row) in rows.indexed) ...[
                if (index > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: compactRowBuilder(context, row),
                ),
              ],
            ],
          );
        }

        final headerStyle = theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: AppColors.background,
              child: _TableRow(
                columns: columns,
                minHeight: 44,
                cellBuilder: (column) => Text(column.label, style: headerStyle),
              ),
            ),
            for (final row in rows) ...[
              const Divider(height: 1),
              _TableRow(
                columns: columns,
                minHeight: 60,
                cellBuilder: (column) => column.cellBuilder(context, row),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TableRow<T> extends StatelessWidget {
  const _TableRow({
    required this.columns,
    required this.minHeight,
    required this.cellBuilder,
  });

  final List<TableColumnDef<T>> columns;
  final double minHeight;
  final Widget Function(TableColumnDef<T> column) cellBuilder;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            for (final column in columns)
              Expanded(
                flex: column.flex,
                child: Align(
                  alignment: column.alignEnd
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: cellBuilder(column),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
