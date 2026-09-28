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

typedef _PatientsData = (List<Patient> patients, List<ClinicalTest> tests);

/// Row view model combining a patient with a summary of their tests.
class _PatientRow {
  _PatientRow(this.patient, List<ClinicalTest> tests)
    : testCount = tests.length,
      lastTestOn = tests.firstOrNull?.takenOn,
      awaitingReview = tests
          .where((t) => t.status == AnalysisStatus.readyForReview)
          .length;

  final Patient patient;
  final int testCount;
  final DateTime? lastTestOn;
  final int awaitingReview;
}

class DoctorPatientsPage extends StatefulWidget {
  const DoctorPatientsPage({super.key, required this.repository});

  final ClinicalDataRepository repository;

  @override
  State<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends State<DoctorPatientsPage> {
  String _query = '';

  Future<_PatientsData> _load() =>
      (widget.repository.getPatients(), widget.repository.getTests()).wait;

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
        final (patients, tests) = data;
        final rows = [
          for (final patient in patients)
            if (_matches(patient))
              _PatientRow(patient, [
                for (final test in tests)
                  if (test.patientId == patient.id) test,
              ]),
        ];

        return PageContainer(
          children: [
            const PageHeader(
              title: 'Patients',
              subtitle:
                  'Open a patient to view their profile and test history.',
            ),
            const MockDataNotice(),
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

  Widget _reviewCell(BuildContext context, _PatientRow row) =>
      row.awaitingReview == 0
      ? const Text('—')
      : StatusBadge(
          label: '${row.awaitingReview} to review',
          tone: StatusTone.warning,
          icon: Icons.rate_review_outlined,
        );

  Widget _action(BuildContext context, _PatientRow row) => TextButton(
    onPressed: () => context.go(AppRoutes.doctorPatientProfile(row.patient.id)),
    child: const Text('Open Profile'),
  );

  String _lastTest(_PatientRow row) =>
      row.lastTestOn == null ? 'No tests' : formatDate(row.lastTestOn!);

  @override
  Widget build(BuildContext context) {
    return ResponsiveTable<_PatientRow>(
      rows: rows,
      emptyMessage: 'No patients match your search.',
      columns: [
        TableColumnDef(label: 'Patient', flex: 3, cellBuilder: _nameCell),
        TableColumnDef(
          label: 'Age',
          cellBuilder: (_, r) => Text('${r.patient.age}'),
        ),
        TableColumnDef(
          label: 'Gender',
          flex: 2,
          cellBuilder: (_, r) => Text(r.patient.gender.label),
        ),
        TableColumnDef(
          label: 'Tests',
          cellBuilder: (_, r) => Text('${r.testCount}'),
        ),
        TableColumnDef(
          label: 'Last test',
          flex: 2,
          cellBuilder: (_, r) => Text(_lastTest(r)),
        ),
        TableColumnDef(label: 'Review', flex: 2, cellBuilder: _reviewCell),
        TableColumnDef(
          label: 'Action',
          flex: 2,
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
              _reviewCell(context, row),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${row.patient.age} · ${row.patient.gender.label} · '
                  '${row.testCount} tests · Last: ${_lastTest(row)}',
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
