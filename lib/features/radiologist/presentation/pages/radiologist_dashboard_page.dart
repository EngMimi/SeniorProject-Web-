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
import '../../../../shared/widgets/mock_data_notice.dart';
import '../../../../shared/widgets/page_container.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/responsive_table.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/summary_card.dart';

typedef _DashboardData = (List<Patient> patients, List<ClinicalTest> scans);

/// MRI-focused overview for radiologists. Only MRI tests are loaded.
class RadiologistDashboardPage extends StatelessWidget {
  const RadiologistDashboardPage({super.key, required this.repository});

  static const _recentActivityLimit = 8;

  final ClinicalDataRepository repository;

  Future<_DashboardData> _load() => (
    repository.getPatients(),
    repository.getTests(modality: TestModality.mri),
  ).wait;

  @override
  Widget build(BuildContext context) {
    return FutureContent<_DashboardData>(
      load: _load,
      builder: (context, data) {
        final (patients, scans) = data;
        final patientsById = {for (final p in patients) p.id: p};
        final patientsWithScans = scans.map((s) => s.patientId).toSet().length;
        final awaitingAnalysis = scans
            .where(
              (s) =>
                  s.status == AnalysisStatus.pending ||
                  s.status == AnalysisStatus.processing,
            )
            .length;
        final completed = scans.where((s) => s.status.hasResult).length;

        return PageContainer(
          children: [
            const PageHeader(
              title: 'Radiologist Dashboard',
              subtitle:
                  'Overview of MRI scans and their AI analysis status. Upload '
                  'new scans from a patient’s MRI history.',
            ),
            const MockDataNotice(),
            SummaryGrid(
              cards: [
                SummaryCard(
                  label: 'Relevant Patients',
                  value: '${patients.length}',
                  icon: Icons.people_outline,
                  caption: '$patientsWithScans with MRI scans',
                ),
                SummaryCard(
                  label: 'MRI Scans',
                  value: '${scans.length}',
                  icon: Icons.image_search_outlined,
                  caption: 'Across all patients',
                ),
                SummaryCard(
                  label: 'Awaiting Analysis',
                  value: '$awaitingAnalysis',
                  icon: Icons.hourglass_empty,
                  caption: 'Pending or processing',
                ),
                SummaryCard(
                  label: 'Completed Analyses',
                  value: '$completed',
                  icon: Icons.analytics_outlined,
                  caption: 'AI result available',
                ),
              ],
            ),
            SectionCard(
              title: 'Recent MRI Activity',
              subtitle: 'Latest MRI scans across patients',
              icon: Icons.history,
              padBody: false,
              trailing: TextButton(
                onPressed: () => context.go(AppRoutes.radiologistPatients),
                child: const Text('View patients'),
              ),
              child: _RecentMriTable(
                scans: scans.take(_recentActivityLimit).toList(),
                patientsById: patientsById,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentMriTable extends StatelessWidget {
  const _RecentMriTable({required this.scans, required this.patientsById});

  final List<ClinicalTest> scans;
  final Map<String, Patient> patientsById;

  Widget _patientCell(BuildContext context, ClinicalTest scan) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          patientsById[scan.patientId]?.fullName ?? 'Unknown patient',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          scan.patientId,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _action(BuildContext context, ClinicalTest scan) => TextButton(
    onPressed: () =>
        context.go(AppRoutes.radiologistMriHistory(scan.patientId)),
    child: const Text('View MRI History'),
  );

  @override
  Widget build(BuildContext context) {
    return ResponsiveTable<ClinicalTest>(
      rows: scans,
      emptyMessage: 'No MRI scans yet.',
      columns: [
        TableColumnDef(label: 'Patient', flex: 3, cellBuilder: _patientCell),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _patientCell(context, scan)),
              AnalysisStatusBadge(status: scan.status),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${scan.id} · ${formatDate(scan.takenOn)}',
                  style: Theme.of(context).textTheme.bodySmall,
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
