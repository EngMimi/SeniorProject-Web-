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
import '../../../../shared/widgets/clinical/ai_analysis_result_card.dart';
import '../../../../shared/widgets/clinical/status_badge.dart';
import '../../../../shared/widgets/future_content.dart';
import '../../../../shared/widgets/info_field.dart';
import '../../../../shared/widgets/message_state.dart';
import '../../../../shared/widgets/page_container.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../widgets/diagnostic_report_section.dart';
import 'doctor_patient_profile_page.dart';

typedef _AnalysisData = (
  Patient? patient,
  ClinicalTest? test,
  DiagnosticReport? report,
);

/// AI analysis result and diagnostic report for one test.
class DoctorTestAnalysisPage extends StatefulWidget {
  const DoctorTestAnalysisPage({
    super.key,
    required this.patientId,
    required this.testId,
    required this.repository,
  });

  /// Content width from which context/AI result and report sit side by side.
  static const _twoColumnMinWidth = 1100.0;

  final String patientId;
  final String testId;
  final ClinicalDataRepository repository;

  @override
  State<DoctorTestAnalysisPage> createState() =>
      _DoctorTestAnalysisPageState();
}

class _DoctorTestAnalysisPageState extends State<DoctorTestAnalysisPage> {
  /// Bumped after a report is saved so [FutureContent] below reloads with a
  /// fresh key instead of showing the data from before the save.
  int _reloadToken = 0;

  Future<_AnalysisData> _load() => (
    widget.repository.getPatient(widget.patientId),
    widget.repository.getTest(widget.testId),
    widget.repository.getReportForTest(widget.testId),
  ).wait;

  Future<void> _saveReport({
    required String title,
    required String clinicalNotes,
    required String recommendations,
    required bool submit,
  }) async {
    final doctorName = AuthService.instance.displayName ?? 'Doctor';
    await widget.repository.submitReport(
      patientId: widget.patientId,
      testId: widget.testId,
      doctorName: doctorName,
      title: title,
      clinicalNotes: clinicalNotes,
      recommendations: recommendations,
      submit: submit,
    );
    if (!mounted) return;
    setState(() => _reloadToken++);
  }

  @override
  Widget build(BuildContext context) {
    return FutureContent<_AnalysisData>(
      key: ValueKey('${widget.patientId}/${widget.testId}/$_reloadToken'),
      load: _load,
      builder: (context, data) {
        final (patient, test, report) = data;
        if (patient == null) return const PatientNotFound();
        if (test == null || test.patientId != patient.id) {
          return _TestNotFound(patientId: patient.id);
        }

        final contextCard = _TestContextCard(patient: patient, test: test);
        final resultCard = AiAnalysisResultCard(test: test);
        final reportSection = DiagnosticReportSection(
          key: ValueKey(test.id),
          report: report,
          onSave: _saveReport,
        );

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
                BreadcrumbItem('${test.modality.label} test'),
              ],
              title: test.modality.analysisTitle,
              subtitle: 'Test ${test.id} · ${formatDate(test.takenOn)}',
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth <
                    DoctorTestAnalysisPage._twoColumnMinWidth) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.lg,
                    children: [contextCard, resultCard, reportSection],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.lg,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpacing.lg,
                        children: [contextCard, resultCard],
                      ),
                    ),
                    Expanded(flex: 6, child: reportSection),
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

class _TestContextCard extends StatelessWidget {
  const _TestContextCard({required this.patient, required this.test});

  final Patient patient;
  final ClinicalTest test;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Patient & Test',
      icon: Icons.assignment_ind_outlined,
      child: InfoGrid(
        minFieldWidth: 160,
        fields: [
          InfoField(label: 'Patient', value: patient.fullName),
          InfoField(label: 'Patient ID', value: patient.id),
          InfoField(
            label: 'Test modality',
            child: ModalityLabel(modality: test.modality),
          ),
          InfoField(label: 'Test date', value: formatDate(test.takenOn)),
          InfoField(
            label: 'Analysis status',
            child: AnalysisStatusBadge(status: test.status),
          ),
        ],
      ),
    );
  }
}

class _TestNotFound extends StatelessWidget {
  const _TestNotFound({required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context) {
    return MessageState(
      icon: Icons.search_off,
      title: 'Test not found',
      message: 'This test does not exist for this patient.',
      action: OutlinedButton(
        onPressed: () => context.go(AppRoutes.doctorPatientProfile(patientId)),
        child: const Text('Back to Patient Profile'),
      ),
    );
  }
}
