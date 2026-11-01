import 'package:flutter_test/flutter_test.dart';
import 'package:neuroinsight_pd_web/shared/data/drawing_model_service.dart';

void main() {
  group('DrawingPredictionResult.fromJson', () {
    test('UT-D01: parses a valid response', () {
      // Arrange: prepare a sample API response.
      final json = <String, dynamic>{
        'prediction': 'Healthy',
        'parkinson_probability': 0.15,
        'threshold': 0.5,
      };

      // Act: convert the response into a result object.
      final result = DrawingPredictionResult.fromJson(json);

      // Assert: verify the parsed values.
      expect(result.prediction, 'Healthy');
      expect(result.parkinsonProbability, 0.15);
      expect(result.threshold, 0.5);
    });

    test('UT-D02: converts integer values to doubles', () {
      final json = <String, dynamic>{
        'prediction': 'Parkinson',
        'parkinson_probability': 1,
        'threshold': 0,
      };

      final result = DrawingPredictionResult.fromJson(json);

      expect(result.parkinsonProbability, 1.0);
      expect(result.parkinsonProbability, isA<double>());
      expect(result.threshold, 0.0);
      expect(result.threshold, isA<double>());
    });

    test('UT-D03: throws when prediction is missing', () {
      final json = <String, dynamic>{
        'parkinson_probability': 0.15,
        'threshold': 0.5,
      };

      expect(
        () => DrawingPredictionResult.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('UT-D04: throws for a non-numeric probability', () {
      final json = <String, dynamic>{
        'prediction': 'Healthy',
        'parkinson_probability': 'invalid',
        'threshold': 0.5,
      };

      expect(
        () => DrawingPredictionResult.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('UT-D05: throws when threshold is missing', () {
      final json = <String, dynamic>{
        'prediction': 'Healthy',
        'parkinson_probability': 0.15,
      };

      expect(
        () => DrawingPredictionResult.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
