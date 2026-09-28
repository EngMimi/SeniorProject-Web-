import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/models/diagnostic_report.dart';
import '../../../../shared/widgets/clinical/status_badge.dart';
import '../../../../shared/widgets/info_field.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/ui_only_feedback.dart';

/// The doctor's diagnostic report for a test.
///
/// Shows an editable form for new or draft reports and a read-only view for
/// submitted ones. Saving and submitting are UI-only for now.
class DiagnosticReportSection extends StatelessWidget {
  const DiagnosticReportSection({super.key, required this.report});

  /// Existing report for the test, or `null` if none has been started.
  final DiagnosticReport? report;

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
          : _ReportForm(draft: report),
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
  const _ReportForm({required this.draft});

  final DiagnosticReport? draft;

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

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }

  void _saveDraft() {
    // TODO: Persist the draft once the backend structure is confirmed.
    showUiOnlyMessage(
      context,
      'Saving drafts is not available yet. This form is UI-only.',
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }
    // TODO: Submit the report once the backend structure is confirmed.
    showUiOnlyMessage(
      context,
      'Submitting reports is not available yet. This form is UI-only.',
    );
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
                onPressed: _saveDraft,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 48),
                ),
                child: const Text('Save Draft'),
              ),
              FilledButton(
                onPressed: _submit,
                child: const Text('Submit Diagnostic Report'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
