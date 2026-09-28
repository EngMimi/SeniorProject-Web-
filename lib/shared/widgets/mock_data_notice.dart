import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Small "MOCK DATA" tag for values that are placeholders.
class MockDataBadge extends StatelessWidget {
  const MockDataBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.devSurface,
        border: Border.all(color: AppColors.devBorder),
        borderRadius: AppRadius.smAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          'MOCK DATA',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.devForeground,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

/// Page-level strip stating that the page shows fictional data.
// TODO: Remove once pages are backed by real data.
class MockDataNotice extends StatelessWidget {
  const MockDataNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.devSurface,
        border: Border.all(color: AppColors.devBorder),
        borderRadius: AppRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.science_outlined,
              size: 18,
              color: AppColors.devForeground,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Mock data: all patients, tests and values shown are '
                'fictional and for demonstration only.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.devForeground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
