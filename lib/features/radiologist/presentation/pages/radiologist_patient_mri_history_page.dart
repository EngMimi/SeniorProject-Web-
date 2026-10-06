import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/data/clinical_data_repository.dart';
import '../../../../shared/models/clinical_test.dart';
import '../../../../shared/models/patient.dart';
import '../../../../shared/widgets/breadcrumbs.dart';
import '../../../../shared/widgets/clinical/ai_analysis_result_card.dart';
import '../../../../shared/widgets/clinical/status_badge.dart';
import '../../../../shared/widgets/future_content.dart';
import '../../../../shared/widgets/info_field.dart';
import '../../../../shared/widgets/message_state.dart';
import '../../../../shared/widgets/page_container.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/responsive_table.dart';
import '../../../../shared/widgets/section_card.dart';

typedef _HistoryData = (Patient? patient, List<ClinicalTest> scans);

// Shows one patient's MRI scans and their AI analysis status.
class RadiologistPatientMriHistoryPage extends StatelessWidget {
  const RadiologistPatientMriHistoryPage({
    super.key,
    required this.patientId,
    required this.repository,
  });

  final String patientId;
  final ClinicalDataRepository repository;

  // Loads the patient plus their MRI scans together.
  Future<_HistoryData> _load() => (
    repository.getPatient(patientId),
    repository.getTests(patientId: patientId, modality: TestModality.mri),
  ).wait;

  @override
  Widget build(BuildContext context) {
    return FutureContent<_HistoryData>(
      key: ValueKey(patientId),
      load: _load,
      builder: (context, data) {
        final (patient, scans) = data;
        if (patient == null) return const RadiologistPatientNotFound();

        final uploadButton = OutlinedButton.icon(
          onPressed: () =>
              context.go(AppRoutes.radiologistMriUpload(patient.id)),
          icon: const Icon(Icons.upload_file, size: 18),
          label: const Text('Upload MRI Scan'),
        );

        return PageContainer(
          children: [
            PageHeader(
              breadcrumbs: [
                const BreadcrumbItem(
                  'Patients',
                  location: AppRoutes.radiologistPatients,
                ),
                BreadcrumbItem(patient.fullName),
              ],
              title: patient.fullName,
              subtitle: 'Patient ID ${patient.id} · MRI history',
              actions: [uploadButton],
            ),
            SectionCard(
              title: 'Patient',
              icon: Icons.person_outline,
              child: InfoGrid(
                fields: [
                  InfoField(label: 'First name', value: patient.firstName),
                  InfoField(label: 'Last name', value: patient.lastName),
                  InfoField(label: 'Patient ID', value: patient.id),
                  InfoField(label: 'National ID', value: patient.nationalId),
                  InfoField(
                    label: 'Patient file no.',
                    value: patient.patientFileNo,
                  ),
                  InfoField(label: 'MRI scans', value: '${scans.length}'),
                  InfoField(
                    label: 'Latest MRI',
                    value: scans.isEmpty
                        ? 'No MRI scans'
                        : formatDate(scans.first.takenOn),
                  ),
                ],
              ),
            ),
            SectionCard(
              title: 'MRI History',
              subtitle: 'Brain MRI scans for this patient, newest first',
              icon: Icons.image_search_outlined,
              padBody: false,
              child: scans.isEmpty
                  ? MessageState(
                      icon: Icons.image_search_outlined,
                      title: 'No MRI scans yet',
                      message:
                          'Upload this patient’s first MRI scan to submit '
                          'it for AI analysis.',
                      action: OutlinedButton.icon(
                        onPressed: () =>
                            context.go(AppRoutes.radiologistMriUpload(
                          patient.id,
                        )),
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Upload MRI Scan'),
                      ),
                    )
                  : _MriTable(scans: scans),
            ),
          ],
        );
      },
    );
  }
}

// Shown when a patient ID in a radiologist URL does not exist.
class RadiologistPatientNotFound extends StatelessWidget {
  const RadiologistPatientNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return MessageState(
      icon: Icons.person_search_outlined,
      title: 'Patient not found',
      message: 'This patient does not exist or is not available to you.',
      action: OutlinedButton(
        onPressed: () => context.go(AppRoutes.radiologistPatients),
        child: const Text('Back to Patients'),
      ),
    );
  }
}

// Table of this patient's MRI scans, with a button to view each one's result.
class _MriTable extends StatelessWidget {
  const _MriTable({required this.scans});

  final List<ClinicalTest> scans;

  Widget _action(BuildContext context, ClinicalTest scan) => TextButton(
    onPressed: () => _showAnalysis(context, scan),
    style: TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: const Text('View Analysis'),
  );

  @override
  Widget build(BuildContext context) {
    return ResponsiveTable<ClinicalTest>(
      rows: scans,
      columns: [
        TableColumnDef(
          label: 'MRI scan ID',
          flex: 2,
          cellBuilder: (_, s) => Text(s.id),
        ),
        TableColumnDef(
          label: 'Scan date',
          flex: 2,
          cellBuilder: (_, s) => Text(formatDate(s.takenOn)),
        ),
        TableColumnDef(
          label: 'Analysis status',
          flex: 2,
          cellBuilder: (_, s) => AnalysisStatusBadge(status: s.status),
        ),
        TableColumnDef(
          label: 'Result',
          flex: 2,
          cellBuilder: (_, s) => ResultAvailabilityLabel(status: s.status),
        ),
        TableColumnDef(
          label: 'Action',
          flex: 2,
          alignEnd: true,
          cellBuilder: _action,
        ),
      ],
      compactRowBuilder: (context, scan) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  scan.id,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              AnalysisStatusBadge(status: scan.status),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      formatDate(scan.takenOn),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    ResultAvailabilityLabel(status: scan.status),
                  ],
                ),
              ),
              _action(context, scan),
            ],
          ),
        ],
      ),
    );
  }
}

// Opens a popup showing the AI analysis result for one MRI scan.
void _showAnalysis(BuildContext context, ClinicalTest scan) {
  showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MRI scan ${scan.id}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Scan date ${formatDate(scan.takenOn)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                AiAnalysisResultCard(test: scan),
              ],
            ),
          ),
        ),
      );
    },
  );
}
