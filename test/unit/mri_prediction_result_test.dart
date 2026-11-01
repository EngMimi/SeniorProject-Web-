import 'package:flutter_test/flutter_test.dart';
import 'package:neuroinsight_pd_web/shared/data/mri_model_service.dart';

void main() {
  group('MriPredictionResult.fromJson', () {
    test('UT-M01: parses a complete Parkinson response', () {
      final json = <String, dynamic>{
        'result': <String, dynamic>{
          'predicted_class': 1,
          'probabilities': <String, dynamic>{'parkinson': 0.85},
          'threshold': 0.6,
          'disclaimer': 'For decision support only.',
        },
      };

      final result = MriPredictionResult.fromJson(json);

      expect(result.prediction, 'Parkinson');
      expect(result.predictionCode, 1);
      expect(result.probabilityPd, 0.85);
      expect(result.threshold, 0.6);
      expect(result.disclaimer, 'For decision support only.');
    });

    test('UT-M02: prefers PD probability over confidence', () {
      final json = <String, dynamic>{
        'result': <String, dynamic>{
          'predicted_class': 0,
          'probabilities': <String, dynamic>{'parkinson': 0.15},
          'confidence': 0.85,
        },
      };

      final result = MriPredictionResult.fromJson(json);

      expect(result.prediction, 'Healthy');
      expect(result.predictionCode, 0);
      expect(result.probabilityPd, 0.15);
    });

    test('UT-M03: uses confidence when probabilities are absent', () {
      final json = <String, dynamic>{
        'result': <String, dynamic>{'predicted_class': 1, 'confidence': 0.85},
      };

      final result = MriPredictionResult.fromJson(json);

      // Documents the current fallback behavior.
      expect(result.probabilityPd, 0.85);
    });

    test('UT-M04: uses confidence when parkinson key is absent', () {
      final json = <String, dynamic>{
        'result': <String, dynamic>{
          'predicted_class': 1,
          'probabilities': <String, dynamic>{},
          'confidence': 0.75,
        },
      };

      final result = MriPredictionResult.fromJson(json);

      expect(result.probabilityPd, 0.75);
    });

    test('UT-M05: applies defaults for optional fields', () {
      final json = <String, dynamic>{
        'result': <String, dynamic>{
          'predicted_class': 0,
          'probabilities': <String, dynamic>{'parkinson': 0.15},
        },
      };

      final result = MriPredictionResult.fromJson(json);

      expect(result.threshold, 0.5);
      expect(result.disclaimer, '');
    });

    test('UT-M06: converts integer numeric values to doubles', () {
      final json = <String, dynamic>{
        'result': <String, dynamic>{
          'predicted_class': 1,
          'probabilities': <String, dynamic>{'parkinson': 1},
          'threshold': 0,
        },
      };

      final result = MriPredictionResult.fromJson(json);

      expect(result.probabilityPd, 1.0);
      expect(result.probabilityPd, isA<double>());
      expect(result.threshold, 0.0);
      expect(result.threshold, isA<double>());
    });

    test('UT-M07: throws when result is missing', () {
      final json = <String, dynamic>{};

      expect(
        () => MriPredictionResult.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('UT-M08: throws when predicted class is missing', () {
      final json = <String, dynamic>{
        'result': <String, dynamic>{
          'probabilities': <String, dynamic>{'parkinson': 0.85},
        },
      };

      expect(
        () => MriPredictionResult.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('UT-M09: throws for a string predicted class', () {
      final json = <String, dynamic>{
        'result': <String, dynamic>{
          'predicted_class': '1',
          'probabilities': <String, dynamic>{'parkinson': 0.85},
        },
      };

      expect(
        () => MriPredictionResult.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('UT-M10: throws when both probability sources are missing', () {
      final json = <String, dynamic>{
        'result': <String, dynamic>{'predicted_class': 1},
      };

      expect(
        () => MriPredictionResult.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('UT-M11: throws for a non-numeric PD probability', () {
      final json = <String, dynamic>{
        'result': <String, dynamic>{
          'predicted_class': 1,
          'probabilities': <String, dynamic>{'parkinson': 'invalid'},
          'confidence': 0.85,
        },
      };

      expect(
        () => MriPredictionResult.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
