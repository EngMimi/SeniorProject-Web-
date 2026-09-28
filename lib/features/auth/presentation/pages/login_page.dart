import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/dev_access_panel.dart';
import '../widgets/login_form.dart';

const _appName = 'NeuroInsight-PD';
const _appSubtitle =
    'Multi-Modal Parkinson’s Detection and Telemonitoring System';
const _maxContentWidth = 420.0;

/// Welcome/sign-in page of the web portal for doctors and radiologists.
///
/// Sign-in is not connected to authentication yet. The user's role will come
/// from authentication, so there is intentionally no role selection here.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          compact: (_) => const _SignInColumn(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xl,
            ),
            header: _BrandHeader(),
          ),
          expanded: (_) => const Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: _BrandPanel()),
              Expanded(
                flex: 6,
                child: _SignInColumn(padding: EdgeInsets.all(AppSpacing.xl)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scrollable, width-constrained column holding the sign-in card and the
/// development panel.
class _SignInColumn extends StatelessWidget {
  const _SignInColumn({required this.padding, this.header});

  final EdgeInsets padding;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?header,
              const _SignInCard(),
              const SizedBox(height: AppSpacing.lg),
              const DevAccessPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInCard extends StatelessWidget {
  const _SignInCard();

  void _onSubmit(BuildContext context) {
    // TODO: Replace with real authentication once the backend is confirmed.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Sign-in is not available yet. Authentication has not been '
            'connected.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sign in',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Web portal for doctors and radiologists. '
              'Your access is determined by your account.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            LoginForm(onSubmit: (_, _) => _onSubmit(context)),
          ],
        ),
      ),
    );
  }
}

/// Brand header shown above the card on compact/medium widths.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        children: [
          const _BrandMark(),
          const SizedBox(height: AppSpacing.md),
          Text(
            _appName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _appSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Navy brand panel shown beside the card on expanded widths.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  static const _padding = AppSpacing.xxl;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: AppColors.navy,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(_padding),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - _padding * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BrandMark(onDark: true),
                  const Spacer(),
                  Text(
                    _appName,
                    style: textTheme.displaySmall?.copyWith(
                      color: AppColors.onNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _appSubtitle,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.onNavyMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(color: AppColors.navyDivider),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Clinical web portal for',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.onNavyMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _AudienceItem(
                    icon: Icons.medical_services_outlined,
                    role: 'Doctors',
                    description:
                        'Review patient test history and AI results, and '
                        'write diagnostic reports.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _AudienceItem(
                    icon: Icons.image_search_outlined,
                    role: 'Radiologists',
                    description:
                        'Upload brain MRI scans and submit them for analysis.',
                  ),
                  const Spacer(),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.onNavyMuted,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'AI results are decision-support information only. '
                          'Diagnostic decisions remain with the treating '
                          'doctor.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.onNavyMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AudienceItem extends StatelessWidget {
  const _AudienceItem({
    required this.icon,
    required this.role,
    required this.description,
  });

  final IconData icon;
  final String role;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: AppColors.onNavy),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.onNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onNavyMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Simple placeholder brand mark until an official logo is provided.
class _BrandMark extends StatelessWidget {
  const _BrandMark({this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onDark ? AppColors.onNavy : AppColors.navy,
          borderRadius: AppRadius.mdAll,
        ),
        child: Icon(
          Icons.psychology_outlined,
          size: 26,
          color: onDark ? AppColors.navy : AppColors.onNavy,
        ),
      ),
    );
  }
}
