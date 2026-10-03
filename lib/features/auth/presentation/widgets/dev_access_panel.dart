import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Temporary dev-only buttons that jump straight into a role's dashboard,
/// skipping sign-in. Styled to look obviously different from the real
/// login so it's not mistaken for production UI.
// TODO: Remove once real authentication and role-based routing exist.
class DevAccessPanel extends StatelessWidget {
  const DevAccessPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.devSurface,
        border: Border.all(color: AppColors.devBorder),
        borderRadius: AppRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.construction_outlined,
                  size: 18,
                  color: AppColors.devForeground,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'DEVELOPMENT ONLY',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.devForeground,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Temporary shortcuts that bypass sign-in. '
              'Not part of the production portal.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.devForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _DevButton(
                  label: 'Continue as Doctor (dev)',
                  route: AppRoutes.doctorDashboard,
                ),
                _DevButton(
                  label: 'Continue as Radiologist (dev)',
                  route: AppRoutes.radiologistDashboard,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One "Continue as ..." shortcut button.
class _DevButton extends StatelessWidget {
  const _DevButton({required this.label, required this.route});

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style:
          OutlinedButton.styleFrom(
            foregroundColor: AppColors.devForeground,
            minimumSize: const Size(64, 40),
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: AppColors.devForeground,
                width: states.contains(WidgetState.focused) ? 2 : 1,
              ),
            ),
          ),
      onPressed: () => context.go(route),
      child: Text(label),
    );
  }
}
