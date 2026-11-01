import 'package:flutter_test/flutter_test.dart';
import 'package:neuroinsight_pd_web/shared/data/drawing_model_service.dart';

void main() {
  group('DrawingPredictionResult.predictionCode', () {
    test('UT-D06: returns 1 for Parkinson', () {
      const result = DrawingPredictionResult(
        prediction: 'Parkinson',
        parkinsonProbability: 0.85,
        threshold: 0.5,
      );

      expect(result.predictionCode, 1);
    });

    test('UT-D07: returns 0 for Healthy', () {
      const result = DrawingPredictionResult(
        prediction: 'Healthy',
        parkinsonProbability: 0.15,
        threshold: 0.5,
      );

      expect(result.predictionCode, 0);
    });

    test('UT-D08: handles uppercase PARKINSON', () {
      const result = DrawingPredictionResult(
        prediction: 'PARKINSON',
        parkinsonProbability: 0.85,
        threshold: 0.5,
      );

      expect(result.predictionCode, 1);
    });

    test('UT-D09: handles lowercase healthy', () {
      const result = DrawingPredictionResult(
        prediction: 'healthy',
        parkinsonProbability: 0.15,
        threshold: 0.5,
      );

      expect(result.predictionCode, 0);
    });
  });
}
