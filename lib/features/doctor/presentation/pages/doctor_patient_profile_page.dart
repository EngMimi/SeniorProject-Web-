import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/data/clinical_data_repository.dart';
import '../../../../shared/models/clinical_test.dart';
import '../../../../shared/models/patient.dart';
import '../../../../shared/widgets/breadcrumbs.dart';
import '../../../../shared/widgets/clinical/status_badge.dart';
import '../../../../shared/widgets/future_content.dart';
import '../../../../shared/widgets/info_field.dart';
import '../../../../shared/widgets/message_state.dart';
import '../../../../shared/widgets/mock_data_notice.dart';
import '../../../../shared/widgets/page_container.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/responsive_table.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/ui_only_feedback.dart';

typedef _ProfileData = (Patient? patient, List<ClinicalTest> tests);

class DoctorPatientProfilePage extends StatelessWidget {
  const DoctorPatientProfilePage({
    super.key,
    required this.patientId,
    required this.repository,
  });

  final String patientId;
  final ClinicalDataRepository repository;

  Future<_ProfileData> _load() => (
    repository.getPatient(patientId),
    repository.getTests(patientId: patientId),
  ).wait;

  @override
  Widget build(BuildContext context) {
    return FutureContent<_ProfileData>(
      key: ValueKey(patientId),
      load: _load,
      builder: (context, data) {
        final (patient, tests) = data;
        if (patient == null) return const PatientNotFound();

        return PageContainer(
          children: [
            PageHeader(
              breadcrumbs: [
                const BreadcrumbItem(
                  'Patients',
                  location: AppRoutes.doctorPatients,
                ),
                BreadcrumbItem(patient.fullName),
              ],
              title: patient.fullName,
              subtitle: 'Patient ID ${patient.id}',
              actions: [
                // TODO: Implement uploads once the backend is confirmed.
                OutlinedButton.icon(
                  onPressed: () => showUiOnlyMessage(
                    context,
                    'Voice recording upload is not available yet.',
                  ),
                  icon: const Icon(Icons.mic_none_outlined, size: 18),
                  label: const Text('Upload Voice Recording'),
                ),
                OutlinedButton.icon(
                  onPressed: () => showUiOnlyMessage(
                    context,
                    'Spiral drawing upload is not available yet.',
                  ),
                  icon: const Icon(Icons.gesture, size: 18),
                  label: const Text('Upload Spiral Drawing'),
                ),
              ],
            ),
            const MockDataNotice(),
            _PatientSummary(patient: patient, tests: tests),
            _TestHistory(patientId: patient.id, tests: tests),
          ],
        );
      },
    );
  }
}

/// Shown when a patient ID in the URL does not exist.
class PatientNotFound extends StatelessWidget {
  const PatientNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return MessageState(
      icon: Icons.person_search_outlined,
      title: 'Patient not found',
      message: 'This patient does not exist or is not available to you.',
      action: OutlinedButton(
        onPressed: () => context.go(AppRoutes.doctorPatients),
        child: const Text('Back to Patients'),
      ),
    );
  }
}

class _PatientSummary extends StatelessWidget {
  const _PatientSummary({required this.patient, required this.tests});

  final Patient patient;
  final List<ClinicalTest> tests;

  @override
  Widget build(BuildContext context) {
    final lastTest = tests.firstOrNull;

    return SectionCard(
      title: 'Patient Summary',
      icon: Icons.person_outline,
      child: InfoGrid(
        fields: [
          InfoField(label: 'Patient ID', value: patient.id),
          InfoField(label: 'Age', value: '${patient.age}'),
          InfoField(label: 'Gender', value: patient.gender.label),
          InfoField(
            label: 'Registered',
            value: formatDate(patient.registeredOn),
          ),
          InfoField(label: 'Total tests', value: '${tests.length}'),
          InfoField(
            label: 'Last test',
            value: lastTest == null ? 'No tests' : formatDate(lastTest.takenOn),
          ),
        ],
      ),
    );
  }
}

class _TestHistory extends StatefulWidget {
  const _TestHistory({required this.patientId, required this.tests});

  final String patientId;
  final List<ClinicalTest> tests;

  @override
  State<_TestHistory> createState() => _TestHistoryState();
}

class _TestHistoryState extends State<_TestHistory> {
  /// `null` shows all modalities.
  TestModality? _filter;

  Widget _resultCell(BuildContext context, ClinicalTest test) =>
      ResultAvailabilityLabel(status: test.status);

  Widget _action(BuildContext context, ClinicalTest test) => TextButton(
    onPressed: () =>
        context.go(AppRoutes.doctorTestAnalysis(widget.patientId, test.id)),
    child: const Text('View Analysis'),
  );

  @override
  Widget build(BuildContext context) {
    final tests = [
      for (final test in widget.tests)
        if (_filter == null || test.modality == _filter) test,
    ];

    return SectionCard(
      title: 'Test History',
      subtitle: 'Voice, spiral drawing and MRI tests, newest first',
      icon: Icons.history,
      padBody: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final option in <TestModality?>[
                  null,
                  ...TestModality.values,
                ])
                  ChoiceChip(
                    label: Text(option?.label ?? 'All'),
                    selected: _filter == option,
                    onSelected: (_) => setState(() => _filter = option),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ResponsiveTable<ClinicalTest>(
            rows: tests,
            emptyMessage: widget.tests.isEmpty
                ? 'No tests have been recorded for this patient yet.'
                : 'No tests for this modality.',
            columns: [
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
                label: 'Result',
                flex: 2,
                cellBuilder: _resultCell,
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
                  children: [
                    Expanded(child: ModalityLabel(modality: test.modality)),
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
                          Text(
                            formatDate(test.takenOn),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          _resultCell(context, test),
                        ],
                      ),
                    ),
                    _action(context, test),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
