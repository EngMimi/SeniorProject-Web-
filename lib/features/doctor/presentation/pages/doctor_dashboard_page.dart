import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/data/clinical_data_repository.dart';
import '../../../../shared/models/clinical_test.dart';
import '../../../../shared/models/patient.dart';
import '../../../../shared/widgets/clinical/status_badge.dart';
import '../../../../shared/widgets/future_content.dart';
import '../../../../shared/widgets/page_container.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/responsive_table.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/summary_card.dart';

typedef _DashboardData = (List<Patient> patients, List<ClinicalTest> tests);

/// The doctor's home page: quick counts of patients/tests, plus a table
/// of the most recent test activity.
class DoctorDashboardPage extends StatelessWidget {
  const DoctorDashboardPage({super.key, required this.repository});

  static const _recentActivityLimit = 8;

  final ClinicalDataRepository repository;

  // Loads patients and tests together so the dashboard can show both.
  Future<_DashboardData> _load() =>
      (repository.getPatients(), repository.getTests()).wait;

  @override
  Widget build(BuildContext context) {
    return FutureContent<_DashboardData>(
      load: _load,
      builder: (context, data) {
        final (patients, tests) = data;
        final patientsById = {for (final p in patients) p.id: p};
        final awaitingReview = tests
            .where((t) => t.status == AnalysisStatus.readyForReview)
            .length;
        final reviewed = tests
            .where((t) => t.status == AnalysisStatus.reviewed)
            .length;
        // MRI scans belong to the radiologist's own dashboard/count — this
        // card is scoped to the doctor's own test types.
        final voiceAndDrawingCount = tests
            .where((t) => t.modality != TestModality.mri)
            .length;

        return PageContainer(
          children: [
            const PageHeader(
              title: 'Doctor Dashboard',
              subtitle:
                  'Overview of recent patient tests and AI analyses awaiting '
                  'your clinical review.',
            ),
            SummaryGrid(
              cards: [
                SummaryCard(
                  label: 'Total Patients',
                  value: '${patients.length}',
                  icon: Icons.people_outline,
                  caption: 'In your patient list',
                ),
                SummaryCard(
                  label: 'Total Voice & Drawing Tests',
                  value: '$voiceAndDrawingCount',
                  icon: Icons.fact_check_outlined,
                  caption: 'Across all patients',
                ),
                SummaryCard(
                  label: 'Awaiting Review',
                  value: '$awaitingReview',
                  icon: Icons.rate_review_outlined,
                  caption: 'AI result ready',
                ),
                SummaryCard(
                  label: 'Reviewed',
                  value: '$reviewed',
                  icon: Icons.analytics_outlined,
                  caption: 'Report completed',
                ),
              ],
            ),
            SectionCard(
              title: 'Recent Test Activity',
              subtitle: 'Latest tests across your patients',
              icon: Icons.history,
              padBody: false,
              trailing: TextButton(
                onPressed: () => context.go(AppRoutes.doctorPatients),
                child: const Text('View patients'),
              ),
              child: _RecentActivityTable(
                tests: tests.take(_recentActivityLimit).toList(),
                patientsById: patientsById,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Table of the most recent tests across all of the doctor's patients.
class _RecentActivityTable extends StatelessWidget {
  const _RecentActivityTable({required this.tests, required this.patientsById});

  final List<ClinicalTest> tests;
  final Map<String, Patient> patientsById;

  // Shows the patient's name and ID for one row.
  Widget _patientCell(BuildContext context, ClinicalTest test) {
    final theme = Theme.of(context);
    final patient = patientsById[test.patientId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          patient?.fullName ?? 'Unknown patient',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          test.patientId,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // "Review" button if the AI result still needs a doctor's review,
  // otherwise just "Open".
  Widget _action(BuildContext context, ClinicalTest test) {
    final needsReview = test.status == AnalysisStatus.readyForReview;
    return TextButton(
      onPressed: () =>
          context.go(AppRoutes.doctorTestAnalysis(test.patientId, test.id)),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(needsReview ? 'Review' : 'Open'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveTable<ClinicalTest>(
      rows: tests,
      emptyMessage: 'No recent test activity.',
      columns: [
        TableColumnDef(label: 'Patient', flex: 3, cellBuilder: _patientCell),
        TableColumnDef(
          label: 'Test modality',
          flex: 2,
          cellBuilder: (_, t) => ModalityLabel(modality: t.modality),
        ),
        TableColumnDef(
          label: 'Date',
          flex: 2,
          cellBuilder: (_, t) => Text(formatDate(t.takenOn)),
        ),
        TableColumnDef(
          label: 'Analysis status',
          flex: 2,
          cellBuilder: (_, t) => AnalysisStatusBadge(status: t.status),
        ),
        TableColumnDef(
          label: 'Action',
          flex: 2,
          alignEnd: true,
          cellBuilder: _action,
        ),
      ],
      compactRowBuilder: (context, test) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _patientCell(context, test)),
              AnalysisStatusBadge(status: test.status),
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
                    ModalityLabel(modality: test.modality),
                    Text(
                      formatDate(test.takenOn),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _action(context, test),
            ],
          ),
        ],
      ),
    );
  }
}
