import 'package:flutter/material.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_spacing.dart';

/// Scrollable, width-constrained body for pages inside a role shell.
class PageContainer extends StatelessWidget {
  const PageContainer({super.key, required this.children});

  static const double maxContentWidth = 1280;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final padding = context.isCompact ? AppSpacing.md : AppSpacing.xl;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.lg,
            children: children,
          ),
        ),
      ),
    );
  }
}
