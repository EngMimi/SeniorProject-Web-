import 'package:flutter_test/flutter_test.dart';
import 'package:neuroinsight_pd_web/core/utils/date_format.dart';

void main() {
  group('formatDate', () {
    test('UT-DT01: formats a regular date', () {
      expect(formatDate(DateTime(2026, 9, 24)), '24 Sep 2026');
    });

    test('UT-DT02: formats January and a single-digit day', () {
      expect(formatDate(DateTime(2026, 1, 5)), '5 Jan 2026');
    });

    test('UT-DT03: formats the last day of December', () {
      expect(formatDate(DateTime(2026, 12, 31)), '31 Dec 2026');
    });

    test('UT-DT04: formats a leap-year date', () {
      expect(formatDate(DateTime(2024, 2, 29)), '29 Feb 2024');
    });

    test('UT-DT05: excludes the time from the output', () {
      expect(formatDate(DateTime(2026, 9, 24, 15, 30, 45)), '24 Sep 2026');
    });
  });
}
