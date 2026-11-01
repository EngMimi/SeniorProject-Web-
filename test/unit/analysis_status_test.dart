import 'package:flutter_test/flutter_test.dart';
import 'package:neuroinsight_pd_web/shared/models/clinical_test.dart';

void main() {
  group('AnalysisStatus.hasResult', () {
    test('UT-C01: pending has no result', () {
      expect(AnalysisStatus.pending.hasResult, isFalse);
    });

    test('UT-C02: processing has no result', () {
      expect(AnalysisStatus.processing.hasResult, isFalse);
    });

    test('UT-C03: readyForReview has a result', () {
      expect(AnalysisStatus.readyForReview.hasResult, isTrue);
    });

    test('UT-C04: reviewed has a result', () {
      expect(AnalysisStatus.reviewed.hasResult, isTrue);
    });
  });
}
