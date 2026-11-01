import 'package:flutter_test/flutter_test.dart';
import 'package:neuroinsight_pd_web/shared/data/voice_model_service.dart';

void main() {
  group('VoicePredictionResult.fromJson', () {
    test('UT-V01: parses a valid Parkinson response', () {
      final json = <String, dynamic>{
        'prediction': 'Parkinson',
        'prediction_code': 1,
        'probability_pd': 0.85,
      };

      final result = VoicePredictionResult.fromJson(json);

      expect(result.prediction, 'Parkinson');
      expect(result.predictionCode, 1);
      expect(result.probabilityPd, 0.85);
    });

    test('UT-V02: parses a valid Healthy response', () {
      final json = <String, dynamic>{
        'prediction': 'Healthy',
        'prediction_code': 0,
        'probability_pd': 0.15,
      };

      final result = VoicePredictionResult.fromJson(json);

      expect(result.prediction, 'Healthy');
      expect(result.predictionCode, 0);
      expect(result.probabilityPd, 0.15);
    });

    test('UT-V03: converts integer probability to double', () {
      final json = <String, dynamic>{
        'prediction': 'Parkinson',
        'prediction_code': 1,
        'probability_pd': 1,
      };

      final result = VoicePredictionResult.fromJson(json);

      expect(result.probabilityPd, 1.0);
      expect(result.probabilityPd, isA<double>());
    });

    test('UT-V04: throws when prediction is missing', () {
      final json = <String, dynamic>{
        'prediction_code': 1,
        'probability_pd': 0.85,
      };

      expect(
        () => VoicePredictionResult.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('UT-V05: throws when prediction code is missing', () {
      final json = <String, dynamic>{
        'prediction': 'Parkinson',
        'probability_pd': 0.85,
      };

      expect(
        () => VoicePredictionResult.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('UT-V06: throws for a string prediction code', () {
      final json = <String, dynamic>{
        'prediction': 'Parkinson',
        'prediction_code': '1',
        'probability_pd': 0.85,
      };

      expect(
        () => VoicePredictionResult.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('UT-V07: throws when probability is missing', () {
      final json = <String, dynamic>{
        'prediction': 'Healthy',
        'prediction_code': 0,
      };

      expect(
        () => VoicePredictionResult.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('UT-V08: throws for a non-numeric probability', () {
      final json = <String, dynamic>{
        'prediction': 'Healthy',
        'prediction_code': 0,
        'probability_pd': 'invalid',
      };

      expect(
        () => VoicePredictionResult.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
