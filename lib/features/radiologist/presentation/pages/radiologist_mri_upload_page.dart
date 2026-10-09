import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/data/clinical_data_repository.dart';
import '../../../../shared/data/cloudinary_upload_service.dart';
import '../../../../shared/data/mri_model_service.dart';
import '../../../../shared/models/patient.dart';
import '../../../../shared/widgets/breadcrumbs.dart';
import '../../../../shared/widgets/future_content.dart';
import '../../../../shared/widgets/info_field.dart';
import '../../../../shared/widgets/page_container.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/ui_only_feedback.dart';
import 'radiologist_patient_mri_history_page.dart';

// Lets the radiologist pick an MRI image and submit it for AI analysis.
// The scan is sent to the MRI model for a prediction, then uploaded to
// Cloudinary so it stays viewable (same pattern as the doctor's spiral
// drawing upload).
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
        final uploadCard = _UploadCard(
          patientId: patient.id,
          repository: repository,
          historyLocation: historyLocation,
        );
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

// The card with the file picker and the submit/cancel buttons.
class _UploadCard extends StatefulWidget {
  const _UploadCard({
    required this.patientId,
    required this.repository,
    required this.historyLocation,
  });

  final String patientId;
  final ClinicalDataRepository repository;
  final String historyLocation;

  @override
  State<_UploadCard> createState() => _UploadCardState();
}

class _UploadCardState extends State<_UploadCard> {
  PlatformFile? _picked;
  bool _submitting = false;
  String _submittingMessage = 'Uploading...';

  // Opens the file picker and stores the chosen MRI image.
  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) {
      if (!mounted) return;
      showUiOnlyMessage(context, 'Could not read that file. Please try again.');
      return;
    }
    setState(() => _picked = file);
  }

  // Sends the picked file to the MRI model for a prediction, uploads it to
  // Cloudinary, then saves the new MRI test record and goes back to the
  // patient's MRI history.
  Future<void> _submit() async {
    final file = _picked;
    if (file == null) {
      showUiOnlyMessage(context, 'Select an MRI scan file first.');
      return;
    }
    setState(() {
      _submitting = true;
      _submittingMessage = 'Analyzing MRI scan...';
    });
    try {
      final prediction = await MriModelService.instance.predict(
        bytes: file.bytes!,
        filename: file.name,
      );

      if (!mounted) return;
      setState(() => _submittingMessage = 'Uploading...');

      final url = await CloudinaryUploadService.instance.uploadImage(
        bytes: file.bytes!,
        filename: file.name,
      );
      await widget.repository.addMriTest(
        patientId: widget.patientId,
        title: file.name,
        fileUrl: url,
        prediction: prediction.prediction,
        predictionCode: prediction.predictionCode,
        probabilityPd: prediction.probabilityPd,
      );
      if (!mounted) return;
      showUiOnlyMessage(context, 'MRI scan uploaded and analyzed.');
      context.go(widget.historyLocation);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showUiOnlyMessage(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picked = _picked;

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
                    Icon(
                      picked == null ? Icons.upload_file : Icons.image_outlined,
                      size: 36,
                      color: AppColors.accentBlue,
                    ),
                    Text(
                      picked?.name ?? 'No file selected',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (picked == null)
                      Text(
                        'Accepted formats: PNG, JPG, JPEG.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _selectFile,
                      icon: const Icon(Icons.folder_open_outlined, size: 18),
                      label: Text(
                        picked == null ? 'Select MRI Scan File' : 'Choose a different file',
                      ),
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
                onPressed: _submitting
                    ? null
                    : () => context.go(widget.historyLocation),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 48),
                ),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined, size: 18),
                label: Text(_submitting ? _submittingMessage : 'Submit for Analysis'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Side card explaining what happens after the scan is submitted.
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
            'The scan is uploaded and sent to the MRI model for analysis. '
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

// Draws the dashed border around the file-drop area.
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
