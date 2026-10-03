import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';

/// One entry in a breadcrumb trail (a label and the route it links to).
class BreadcrumbItem {
  const BreadcrumbItem(this.label, {this.location});

  final String label;

  /// Route to navigate to. The last item (current page) has none.
  final String? location;
}

/// Breadcrumb trail for nested pages, e.g. Patients › Alex Sample › MRI test.
class Breadcrumbs extends StatelessWidget {
  const Breadcrumbs({super.key, required this.items});

  final List<BreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Semantics(
      container: true,
      label: 'Breadcrumb',
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (index, item) in items.indexed) ...[
            if (index > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (item.location case final location?
                when index < items.length - 1)
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: theme.colorScheme.secondary,
                  textStyle: theme.textTheme.bodyMedium,
                ),
                onPressed: () => context.go(location),
                child: Text(item.label),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(item.label, style: mutedStyle),
              ),
          ],
        ],
      ),
    );
  }
}
