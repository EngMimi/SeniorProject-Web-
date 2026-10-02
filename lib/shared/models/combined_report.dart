import 'diagnostic_report.dart';

/// A doctor's diagnostic report that covers several of a patient's tests at
/// once (e.g. a Voice test and a Spiral Drawing test reviewed together),
/// rather than the single-test [DiagnosticReport].
///
/// Stored at `users/{patientId}/reports/{reportId}` — separate from the
/// per-test `report` map still used by the single-test flow.
class CombinedReport {
  const CombinedReport({
    required this.id,
    required this.patientId,
    required this.testIds,
    required this.testTypeLabels,
    required this.title,
    required this.clinicalNotes,
    required this.recommendations,
    required this.status,
    required this.updatedOn,
  });

  final String id;
  final String patientId;

  /// IDs of every test this report covers.
  final List<String> testIds;

  /// Display label for each test's modality (e.g. "Voice", "Spiral
  /// Drawing"), same order as [testIds]. Stored alongside the report so the
  /// patient app can show what it covers without a second read per test.
  final List<String> testTypeLabels;

  final String title;
  final String clinicalNotes;
  final String recommendations;
  final ReportStatus status;
  final DateTime updatedOn;
}
