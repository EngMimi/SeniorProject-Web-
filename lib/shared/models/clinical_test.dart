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
/// The voice model is already live (see neuroinsight_pd_app's
/// VoiceModelService): its real output is carried in [aiPrediction] /
/// [aiPredictionCode] / [aiProbabilityPd], matching exactly what's stored in
/// Firestore under a test's `prediction` map. The spiral and MRI models
/// aren't built yet, so their output schemas stay unconfirmed/null.
class ClinicalTest {
  const ClinicalTest({
    required this.id,
    required this.patientId,
    required this.modality,
    required this.takenOn,
    required this.status,
    this.analysisCompletedOn,
    this.aiPrediction,
    this.aiPredictionCode,
    this.aiProbabilityPd,
  });

  final String id;
  final String patientId;
  final TestModality modality;
  final DateTime takenOn;
  final AnalysisStatus status;
  final DateTime? analysisCompletedOn;

  /// e.g. "PD" or "Healthy" — only populated for voice tests today.
  final String? aiPrediction;
  final int? aiPredictionCode;
  final double? aiProbabilityPd;

  bool get hasVoiceResult => aiPrediction != null;
}
