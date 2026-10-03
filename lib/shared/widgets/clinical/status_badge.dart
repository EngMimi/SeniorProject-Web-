import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../models/clinical_test.dart';
import '../../models/diagnostic_report.dart';

/// Color pair (background + text/icon) a [StatusBadge] can be shown in.
enum StatusTone {
  neutral(AppColors.neutralSurface, AppColors.neutralForeground),
  info(AppColors.infoSurface, AppColors.infoForeground),
  warning(AppColors.warningSurface, AppColors.warningForeground),
  success(AppColors.successSurface, AppColors.successForeground);

  const StatusTone(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

/// Compact status label. Always shows text + icon, never color alone.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
    required this.icon,
  });

  final String label;
  final StatusTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: AppRadius.smAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: tone.foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: tone.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge for a test's AI analysis status (pending, processing, etc.).
class AnalysisStatusBadge extends StatelessWidget {
  const AnalysisStatusBadge({super.key, required this.status});

  final AnalysisStatus status;

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = switch (status) {
      AnalysisStatus.pending => (StatusTone.neutral, Icons.schedule),
      AnalysisStatus.processing => (StatusTone.info, Icons.autorenew),
      AnalysisStatus.readyForReview => (
        StatusTone.warning,
        Icons.rate_review_outlined,
      ),
      AnalysisStatus.reviewed => (
        StatusTone.success,
        Icons.check_circle_outline,
      ),
    };
    return StatusBadge(label: status.label, tone: tone, icon: icon);
  }
}

/// Status of the doctor's report for a test; `null` means not started.
class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({super.key, required this.status});

  final ReportStatus? status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      null => const StatusBadge(
        label: 'Not started',
        tone: StatusTone.neutral,
        icon: Icons.radio_button_unchecked,
      ),
      ReportStatus.draft => const StatusBadge(
        label: 'Draft',
        tone: StatusTone.warning,
        icon: Icons.edit_outlined,
      ),
      ReportStatus.submitted => const StatusBadge(
        label: 'Submitted',
        tone: StatusTone.success,
        icon: Icons.task_alt,
      ),
    };
  }
}

/// "Available" / "Not yet available" for a test's AI result.
class ResultAvailabilityLabel extends StatelessWidget {
  const ResultAvailabilityLabel({super.key, required this.status});

  final AnalysisStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = status.hasResult;
    final color = available
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(available ? Icons.check : Icons.remove, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            available ? 'Available' : 'Not yet available',
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Icon that represents a test modality (voice, spiral drawing, MRI).
IconData modalityIcon(TestModality modality) => switch (modality) {
  TestModality.voice => Icons.mic_none_outlined,
  TestModality.spiral => Icons.gesture,
  TestModality.mri => Icons.image_search_outlined,
};

/// Modality name with its icon.
class ModalityLabel extends StatelessWidget {
  const ModalityLabel({super.key, required this.modality});

  final TestModality modality;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          modalityIcon(modality),
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(modality.label)),
      ],
    );
  }
}
