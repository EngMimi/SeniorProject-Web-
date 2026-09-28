import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/data/clinical_data_repository.dart';
import '../../../../shared/models/patient.dart';
import '../../../../shared/widgets/breadcrumbs.dart';
import '../../../../shared/widgets/future_content.dart';
import '../../../../shared/widgets/info_field.dart';
import '../../../../shared/widgets/mock_data_notice.dart';
import '../../../../shared/widgets/page_container.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/ui_only_feedback.dart';
import 'radiologist_patient_mri_history_page.dart';

/// MRI scan upload and submission for AI analysis. UI only.
///
/// File selection, accepted formats, size limits, storage and the analysis
/// pipeline are not confirmed, so none of them are implemented or assumed.
class RadiologistMriUploadPage extends StatelessWidget {
  const RadiologistMriUploadPage({
    super.key,
    required this.patientId,
    required this.repository,
  });

  /// Content width from which the upload area and guidance sit side by side.
  static const _twoColumnMinWidth = 960.0;

  final String patientId;
  final ClinicalDataRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureContent<Patient?>(
      key: ValueKey(patientId),
      load: () => repository.getPatient(patientId),
      builder: (context, patient) {
        if (patient == null) return const RadiologistPatientNotFound();

        final historyLocation = AppRoutes.radiologistMriHistory(patient.id);
        final uploadCard = _UploadCard(historyLocation: historyLocation);
        final patientCard = SectionCard(
          title: 'Patient',
          icon: Icons.person_outline,
          child: InfoGrid(
            minFieldWidth: 140,
            fields: [
              InfoField(label: 'Patient', value: patient.fullName),
              InfoField(label: 'Patient ID', value: patient.id),
            ],
          ),
        );
        const nextStepsCard = _NextStepsCard();

        return PageContainer(
          children: [
            PageHeader(
              breadcrumbs: [
                const BreadcrumbItem(
                  'Patients',
                  location: AppRoutes.radiologistPatients,
                ),
                BreadcrumbItem(patient.fullName, location: historyLocation),
                const BreadcrumbItem('Upload MRI Scan'),
              ],
              title: 'Upload MRI Scan',
              subtitle: 'For ${patient.fullName} · ${patient.id}',
            ),
            const MockDataNotice(),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < _twoColumnMinWidth) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.lg,
                    children: [patientCard, uploadCard, nextStepsCard],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.lg,
                  children: [
                    Expanded(flex: 3, child: uploadCard),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpacing.lg,
                        children: [patientCard, nextStepsCard],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.historyLocation});

  final String historyLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      title: 'MRI Scan',
      subtitle: 'Select the brain MRI scan to submit for AI analysis.',
      icon: Icons.image_search_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg,
        children: [
          Semantics(
            label: 'MRI scan file',
            container: true,
            child: CustomPaint(
              painter: const _DashedBorderPainter(
                color: AppColors.borderStrong,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  spacing: AppSpacing.sm,
                  children: [
                    const Icon(
                      Icons.upload_file,
                      size: 36,
                      color: AppColors.accentBlue,
                    ),
                    Text(
                      'No file selected',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'File selection is not connected yet. Accepted file '
                      'formats and size limits will be shown here once they '
                      'are confirmed.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // TODO: Connect file selection once upload requirements
                    // are confirmed.
                    OutlinedButton.icon(
                      onPressed: () => showUiOnlyMessage(
                        context,
                        'File selection is not connected yet.',
                      ),
                      icon: const Icon(Icons.folder_open_outlined, size: 18),
                      label: const Text('Select MRI Scan File'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton(
                onPressed: () => context.go(historyLocation),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 48),
                ),
                child: const Text('Cancel'),
              ),
              // TODO: Upload and submit once storage and the analysis
              // pipeline are confirmed.
              FilledButton.icon(
                onPressed: () => showUiOnlyMessage(
                  context,
                  'MRI upload and AI analysis are not connected yet. No file '
                  'has been uploaded or submitted.',
                ),
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('Submit for Analysis'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard();

  static const _steps = [
    'Select the patient’s brain MRI scan.',
    'Submit the scan for AI analysis.',
    'Track the analysis status in the patient’s MRI history.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      title: 'What happens next',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          for (final (index, step) in _steps.indexed)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(step, style: theme.textTheme.bodyMedium)),
              ],
            ),
          Text(
            'Uploading and analysis are not connected yet in this version. '
            'AI results are decision-support information only; diagnostic '
            'decisions remain with the treating doctor.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a dashed rounded rectangle around the upload area.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  static const _dash = 6.0;
  static const _gap = 4.0;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.md),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
