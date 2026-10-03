import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../../../shared/data/clinical_data_repository.dart';
import '../../../../shared/models/clinical_test.dart';
import '../../../../shared/models/diagnostic_report.dart';
import '../../../../shared/models/patient.dart';
import '../../../../shared/widgets/breadcrumbs.dart';
import '../../../../shared/widgets/clinical/status_badge.dart';
import '../../../../shared/widgets/future_content.dart';
import '../../../../shared/widgets/message_state.dart';
import '../../../../shared/widgets/page_container.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/ui_only_feedback.dart';
import 'doctor_patient_profile_page.dart';

typedef _CombinedReportData = (Patient? patient, List<ClinicalTest> tests);

/// Lets a doctor pick several of a patient's tests and write one diagnostic
/// report covering all of them, instead of one report per test.
class DoctorCombinedReportPage extends StatefulWidget {
  const DoctorCombinedReportPage({
    super.key,
    required this.patientId,
    required this.repository,
  });

  final String patientId;
  final ClinicalDataRepository repository;

  @override
  State<DoctorCombinedReportPage> createState() =>
      _DoctorCombinedReportPageState();
}

class _DoctorCombinedReportPageState extends State<DoctorCombinedReportPage> {
  Future<_CombinedReportData> _load() => (
    widget.repository.getPatient(widget.patientId),
    widget.repository.getTests(patientId: widget.patientId),
  ).wait;

  @override
  Widget build(BuildContext context) {
    return FutureContent<_CombinedReportData>(
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
                BreadcrumbItem(
                  patient.fullName,
                  location: AppRoutes.doctorPatientProfile(patient.id),
                ),
                const BreadcrumbItem('Combined Report'),
              ],
              title: 'Write Combined Report',
              subtitle:
                  'Select the tests this report covers, then write one '
                  'assessment for all of them.',
            ),
            if (tests.isEmpty)
              const MessageState(
                icon: Icons.history_toggle_off,
                title: 'No tests yet',
                message:
                    'This patient has no tests to combine into a report '
                    'yet.',
              )
            else
              _CombinedReportForm(
                patientId: patient.id,
                tests: tests,
                repository: widget.repository,
              ),
          ],
        );
      },
    );
  }
}

class _CombinedReportForm extends StatefulWidget {
  const _CombinedReportForm({
    required this.patientId,
    required this.tests,
    required this.repository,
  });

  final String patientId;
  final List<ClinicalTest> tests;
  final ClinicalDataRepository repository;

  @override
  State<_CombinedReportForm> createState() => _CombinedReportFormState();
}

/// The checkbox list of tests plus the report form underneath it.
class _CombinedReportFormState extends State<_CombinedReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _recommendationsController = TextEditingController();
  final Set<String> _selectedTestIds = {};
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _saving = false;
  String? _selectionError;

  /// Set once a draft or submitted report has been saved, so a further save
  /// updates that same report instead of creating a duplicate.
  String? _reportId;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }

  // Validates the form (and the test selection, if submitting) then saves
  // the combined report as a draft or a final submission.
  Future<void> _save({required bool submit}) async {
    final formOk = _formKey.currentState!.validate();
    final hasSelection = _selectedTestIds.isNotEmpty;
    if (submit && (!formOk || !hasSelection)) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
        _selectionError = hasSelection
            ? null
            : 'Select at least one test to include.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _selectionError = null;
    });
    try {
      final doctorName = AuthService.instance.displayName ?? 'Doctor';
      final id = await widget.repository.submitCombinedReport(
        reportId: _reportId,
        patientId: widget.patientId,
        testIds: _selectedTestIds.toList(),
        doctorName: doctorName,
        title: _titleController.text.trim(),
        clinicalNotes: _notesController.text.trim(),
        recommendations: _recommendationsController.text.trim(),
        submit: submit,
      );
      if (!mounted) return;
      setState(() => _reportId = id);
      showUiOnlyMessage(
        context,
        submit
            ? 'Combined report submitted. It is now visible to the patient '
                  'as one report.'
            : 'Draft saved.',
      );
      if (submit) context.go(AppRoutes.doctorPatientProfile(widget.patientId));
    } catch (_) {
      if (!mounted) return;
      showUiOnlyMessage(
        context,
        'Could not save the report. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        SectionCard(
          title: 'Tests to include',
          subtitle: 'Pick every test this report should cover.',
          icon: Icons.checklist_outlined,
          padBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final test in widget.tests)
                CheckboxListTile(
                  value: _selectedTestIds.contains(test.id),
                  onChanged: (checked) => setState(() {
                    if (checked ?? false) {
                      _selectedTestIds.add(test.id);
                    } else {
                      _selectedTestIds.remove(test.id);
                    }
                    if (_selectedTestIds.isNotEmpty) _selectionError = null;
                  }),
                  title: Row(
                    children: [
                      ModalityLabel(modality: test.modality),
                      const SizedBox(width: AppSpacing.md),
                      Text(formatDate(test.takenOn)),
                    ],
                  ),
                  secondary: AnalysisStatusBadge(status: test.status),
                ),
              if (_selectionError case final error?)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Text(
                    error,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SectionCard(
          title: 'Diagnostic Report',
          subtitle:
              'Written by the doctor. One assessment covering every test '
              'selected above.',
          icon: Icons.edit_note_outlined,
          trailing: ReportStatusBadge(
            status: _reportId == null ? null : ReportStatus.draft,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Report title'),
                  textInputAction: TextInputAction.next,
                  validator: (v) => _required(v, 'Enter a report title.'),
                ),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Clinical notes / assessment',
                    alignLabelWithHint: true,
                  ),
                  keyboardType: TextInputType.multiline,
                  minLines: 6,
                  maxLines: 12,
                  validator: (v) =>
                      _required(v, 'Enter your clinical notes or assessment.'),
                ),
                TextFormField(
                  controller: _recommendationsController,
                  decoration: const InputDecoration(
                    labelText: 'Recommendations (optional)',
                    alignLabelWithHint: true,
                  ),
                  keyboardType: TextInputType.multiline,
                  minLines: 3,
                  maxLines: 8,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton(
                      onPressed: _saving ? null : () => _save(submit: false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(64, 48),
                      ),
                      child: const Text('Save Draft'),
                    ),
                    FilledButton(
                      onPressed: _saving ? null : () => _save(submit: true),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit Combined Report'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
