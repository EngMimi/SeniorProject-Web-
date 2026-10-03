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

typedef _PatientsData = (List<Patient> patients, List<ClinicalTest> scans);

/// Row view model: a patient with a summary of their MRI scans only.
class _PatientRow {
  _PatientRow(this.patient, List<ClinicalTest> scans)
    : scanCount = scans.length,
      latestScan = scans.firstOrNull;

  final Patient patient;
  final int scanCount;
  final ClinicalTest? latestScan;
}

// Searchable list of patients, with each one's MRI scan count and latest scan.
class RadiologistPatientsPage extends StatefulWidget {
  const RadiologistPatientsPage({super.key, required this.repository});

  final ClinicalDataRepository repository;

  @override
  State<RadiologistPatientsPage> createState() =>
      _RadiologistPatientsPageState();
}

class _RadiologistPatientsPageState extends State<RadiologistPatientsPage> {
  String _query = '';

  // Loads all patients and all MRI scans, so each patient's scan count and
  // latest scan can be worked out on this page.
  Future<_PatientsData> _load() => (
    widget.repository.getPatients(),
    widget.repository.getTests(modality: TestModality.mri),
  ).wait;

  // Checks if a patient's name or ID matches the search box text.
  bool _matches(Patient patient) {
    final query = _query.trim().toLowerCase();
    return query.isEmpty ||
        patient.fullName.toLowerCase().contains(query) ||
        patient.id.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    return FutureContent<_PatientsData>(
      load: _load,
      builder: (context, data) {
        final (patients, scans) = data;
        final rows = [
          for (final patient in patients)
            if (_matches(patient))
              _PatientRow(patient, [
                for (final scan in scans)
                  if (scan.patientId == patient.id) scan,
              ]),
        ];

        return PageContainer(
          children: [
            const PageHeader(
              title: 'Patients',
              subtitle:
                  'Find a patient to view their MRI history or upload a new '
                  'MRI scan.',
            ),
            SectionCard(
              title: 'Patient List',
              subtitle: '${rows.length} of ${patients.length} patients',
              icon: Icons.people_outline,
              padBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Search patients',
                            hintText: 'Name or patient ID',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                          ),
                          onChanged: (value) => setState(() => _query = value),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _PatientTable(rows: rows),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// Renders the patient rows as a table (or stacked cards on narrow screens).
class _PatientTable extends StatelessWidget {
  const _PatientTable({required this.rows});

  final List<_PatientRow> rows;

  Widget _nameCell(BuildContext context, _PatientRow row) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.patient.fullName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          row.patient.id,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _latestStatus(BuildContext context, _PatientRow row) =>
      switch (row.latestScan) {
        null => const Text('—'),
        final scan => AnalysisStatusBadge(status: scan.status),
      };

  Widget _action(BuildContext context, _PatientRow row) => TextButton(
    onPressed: () =>
        context.go(AppRoutes.radiologistMriHistory(row.patient.id)),
    style: TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: const Text('Open Profile'),
  );

  String _latestDate(_PatientRow row) => row.latestScan == null
      ? 'No MRI scans'
      : formatDate(row.latestScan!.takenOn);

  @override
  Widget build(BuildContext context) {
    return ResponsiveTable<_PatientRow>(
      rows: rows,
      emptyMessage: 'No patients match your search.',
      columns: [
        TableColumnDef(label: 'Patient', flex: 3, cellBuilder: _nameCell),
        TableColumnDef(
          label: 'National ID',
          flex: 2,
          cellBuilder: (_, r) => Text(r.patient.nationalId),
        ),
        TableColumnDef(
          label: 'Hospital file no.',
          flex: 2,
          cellBuilder: (_, r) => Text(r.patient.hospitalFileNo),
        ),
        TableColumnDef(
          label: 'MRI scans',
          flex: 2,
          cellBuilder: (_, r) => Text('${r.scanCount}'),
        ),
        TableColumnDef(
          label: 'Latest MRI',
          flex: 2,
          cellBuilder: (_, r) => Text(_latestDate(r)),
        ),
        TableColumnDef(
          label: 'Latest status',
          flex: 3,
          cellBuilder: _latestStatus,
        ),
        TableColumnDef(
          label: 'Action',
          flex: 3,
          alignEnd: true,
          cellBuilder: _action,
        ),
      ],
      compactRowBuilder: (context, row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _nameCell(context, row)),
              _latestStatus(context, row),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${row.patient.nationalId} · ${row.patient.hospitalFileNo} · '
                  '${row.scanCount} MRI · Latest: ${_latestDate(row)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              _action(context, row),
            ],
          ),
        ],
      ),
    );
  }
}
