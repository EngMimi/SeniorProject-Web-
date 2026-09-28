/// The three NeuroInsight-PD test modalities.
enum TestModality {
  voice('Voice'),
  spiral('Spiral Drawing'),
  mri('MRI');

  const TestModality(this.label);

  final String label;

  String get analysisTitle => '$label Analysis';
}

/// Workflow status of a test's AI analysis.
enum AnalysisStatus {
  pending('Pending'),
  processing('Processing'),
  readyForReview('Ready for Review'),
  reviewed('Reviewed');

  const AnalysisStatus(this.label);

  final String label;

  /// Whether an AI result exists for this test.
  bool get hasResult => this == readyForReview || this == reviewed;
}

/// A single test (voice recording, spiral drawing or MRI scan) for a patient.
///
/// Deliberately contains no AI output fields: the real model output schemas
/// are not confirmed yet.
class ClinicalTest {
  const ClinicalTest({
    required this.id,
    required this.patientId,
    required this.modality,
    required this.takenOn,
    required this.status,
    this.analysisCompletedOn,
  });

  final String id;
  final String patientId;
  final TestModality modality;
  final DateTime takenOn;
  final AnalysisStatus status;
  final DateTime? analysisCompletedOn;
}
