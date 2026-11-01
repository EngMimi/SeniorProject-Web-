import 'package:flutter_test/flutter_test.dart';
import 'package:neuroinsight_pd_web/shared/models/clinical_test.dart';

void main() {
  ClinicalTest createTest({
    String? prediction,
    int? predictionCode,
    double? probability,
  }) {
    return ClinicalTest(
      id: 'test-001',
      patientId: 'synthetic-patient-001',
      modality: TestModality.voice,
      takenOn: DateTime(2026, 10, 27),
      status: AnalysisStatus.readyForReview,
      aiPrediction: prediction,
      aiPredictionCode: predictionCode,
      aiProbabilityPd: probability,
    );
  }

  group('ClinicalTest.hasAiResult', () {
    test('UT-C05: null prediction returns false', () {
      final clinicalTest = createTest();

      expect(clinicalTest.hasAiResult, isFalse);
    });

    test('UT-C06: Parkinson prediction returns true', () {
      final clinicalTest = createTest(
        prediction: 'Parkinson',
        predictionCode: 1,
        probability: 0.85,
      );

      expect(clinicalTest.hasAiResult, isTrue);
    });

    test('UT-C07: Healthy prediction returns true', () {
      final clinicalTest = createTest(
        prediction: 'Healthy',
        predictionCode: 0,
        probability: 0.15,
      );

      expect(clinicalTest.hasAiResult, isTrue);
    });

    test('UT-C08: empty prediction currently returns true', () {
      final clinicalTest = createTest(prediction: '');

      expect(clinicalTest.hasAiResult, isTrue);
    });

    test('UT-C09: prediction alone returns true', () {
      final clinicalTest = createTest(prediction: 'Parkinson');

      expect(clinicalTest.hasAiResult, isTrue);
    });

    test('UT-C10: code and probability without prediction return false', () {
      final clinicalTest = createTest(predictionCode: 1, probability: 0.85);

      expect(clinicalTest.hasAiResult, isFalse);
    });
  });
}
