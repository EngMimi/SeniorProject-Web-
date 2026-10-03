/// Whether a report is still a draft or has been submitted.
enum ReportStatus {
  draft('Draft'),
  submitted('Submitted');

  const ReportStatus(this.label);

  final String label;
}

/// A doctor's diagnostic report for a test. Written by the doctor and kept
/// separate from the AI analysis result.
class DiagnosticReport {
  const DiagnosticReport({
    required this.id,
    required this.patientId,
    required this.testId,
    required this.title,
    required this.clinicalNotes,
    required this.recommendations,
    required this.status,
    required this.updatedOn,
  });

  final String id;
  final String patientId;
  final String testId;
  final String title;
  final String clinicalNotes;
  final String recommendations;
  final ReportStatus status;
  final DateTime updatedOn;
}
