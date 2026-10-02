import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/models/diagnostic_report.dart';
import '../../../../shared/widgets/clinical/status_badge.dart';
import '../../../../shared/widgets/info_field.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/ui_only_feedback.dart';

/// Called to persist the report. [submit] is false for "Save Draft" and
/// true for "Submit Diagnostic Report".
typedef SaveReport =
    Future<void> Function({
      required String title,
      required String clinicalNotes,
      required String recommendations,
      required bool submit,
    });

/// The doctor's diagnostic report for a test.
///
/// Shows an editable form for new or draft reports and a read-only view for
/// submitted ones. [onSave] persists the report; once a submitted report
/// comes back from the reload it triggers, this switches to the read-only
/// view automatically.
class DiagnosticReportSection extends StatelessWidget {
  const DiagnosticReportSection({
    super.key,
    required this.report,
    required this.onSave,
  });

  /// Existing report for the test, or `null` if none has been started.
  final DiagnosticReport? report;
  final SaveReport onSave;

  @override
  Widget build(BuildContext context) {
    final report = this.report;

    return SectionCard(
      title: 'Diagnostic Report',
      subtitle:
          'Written by the doctor. The clinical assessment is the doctor’s '
          'responsibility and is separate from the AI result.',
      icon: Icons.edit_note_outlined,
      trailing: ReportStatusBadge(status: report?.status),
      child: report != null && report.status == ReportStatus.submitted
          ? _SubmittedReport(report: report)
          : _ReportForm(draft: report, onSave: onSave),
    );
  }
}

class _SubmittedReport extends StatelessWidget {
  const _SubmittedReport({required this.report});

  final DiagnosticReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        InfoGrid(
          fields: [
            InfoField(label: 'Report title', value: report.title),
            InfoField(
              label: 'Submitted on',
              value: formatDate(report.updatedOn),
            ),
          ],
        ),
        InfoField(
          label: 'Clinical notes / assessment',
          value: report.clinicalNotes,
        ),
        InfoField(
          label: 'Recommendations',
          value: report.recommendations.isEmpty ? '—' : report.recommendations,
        ),
      ],
    );
  }
}

class _ReportForm extends StatefulWidget {
  const _ReportForm({required this.draft, required this.onSave});

  final DiagnosticReport? draft;
  final SaveReport onSave;

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(
    text: widget.draft?.title,
  );
  late final _notesController = TextEditingController(
    text: widget.draft?.clinicalNotes,
  );
  late final _recommendationsController = TextEditingController(
    text: widget.draft?.recommendations,
  );
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }

  Future<void> _save({required bool submit}) async {
    if (submit && !_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }
    // A draft can be saved with an empty title/notes; only submitting
    // requires the form to be filled in.
    setState(() => _saving = true);
    try {
      await widget.onSave(
        title: _titleController.text.trim(),
        clinicalNotes: _notesController.text.trim(),
        recommendations: _recommendationsController.text.trim(),
        submit: submit,
      );
      if (!mounted) return;
      showUiOnlyMessage(
        context,
        submit
            ? 'Report submitted. It is now visible to the patient.'
            : 'Draft saved.',
      );
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
    final draft = widget.draft;

    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          if (draft != null)
            Text(
              'Draft last updated on ${formatDate(draft.updatedOn)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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
                    : const Text('Submit Diagnostic Report'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
