import '../../models/clinical_test.dart';
import '../../models/diagnostic_report.dart';
import '../../models/patient.dart';

// Fictional demo patients, tests and reports used for UI development.
// Nothing here refers to real people.

/// Fictional demonstration data for UI development only.
abstract final class MockClinicalData {
  static final List<Patient> patients = [
    Patient(
      id: 'PT-DEMO-001',
      fullName: 'Alex Sample',
      nationalId: '1000000001',
      dateOfBirth: '02 / 03 / 1959',
      hospitalFileNo: 'KAU-2026-1001',
    ),
    Patient(
      id: 'PT-DEMO-002',
      fullName: 'Jamie Example',
      nationalId: '1000000002',
      dateOfBirth: '18 / 06 / 1954',
      hospitalFileNo: 'KAU-2026-1002',
    ),
    Patient(
      id: 'PT-DEMO-003',
      fullName: 'Morgan Testcase',
      nationalId: '1000000003',
      dateOfBirth: '07 / 09 / 1967',
      hospitalFileNo: 'KAU-2026-1003',
    ),
    Patient(
      id: 'PT-DEMO-004',
      fullName: 'Riley Placeholder',
      nationalId: '1000000004',
      dateOfBirth: '12 / 01 / 1962',
      hospitalFileNo: 'KAU-2026-1004',
    ),
    Patient(
      id: 'PT-DEMO-005',
      fullName: 'Casey Demo',
      nationalId: '1000000005',
      dateOfBirth: '03 / 11 / 1956',
      hospitalFileNo: 'KAU-2026-1005',
    ),
    Patient(
      id: 'PT-DEMO-006',
      fullName: 'Taylor Mockwell',
      nationalId: '1000000006',
      dateOfBirth: '21 / 04 / 1965',
      hospitalFileNo: 'KAU-2026-1006',
    ),
  ];

  static final List<ClinicalTest> tests = [
    _test(
      '0001',
      'PT-DEMO-001',
      TestModality.voice,
      DateTime(2026, 9, 24),
      AnalysisStatus.readyForReview,
      DateTime(2026, 9, 24),
      'PD',
      1,
      0.8671,
    ),
    _test(
      '0002',
      'PT-DEMO-001',
      TestModality.spiral,
      DateTime(2026, 9, 24),
      AnalysisStatus.processing,
    ),
    _test(
      '0003',
      'PT-DEMO-001',
      TestModality.mri,
      DateTime(2026, 9, 10),
      AnalysisStatus.reviewed,
      DateTime(2026, 9, 11),
    ),
    _test(
      '0004',
      'PT-DEMO-001',
      TestModality.voice,
      DateTime(2026, 8, 20),
      AnalysisStatus.reviewed,
      DateTime(2026, 8, 20),
      'Healthy',
      0,
      0.12,
    ),
    _test(
      '0005',
      'PT-DEMO-002',
      TestModality.spiral,
      DateTime(2026, 9, 23),
      AnalysisStatus.readyForReview,
      DateTime(2026, 9, 23),
    ),
    _test(
      '0006',
      'PT-DEMO-002',
      TestModality.voice,
      DateTime(2026, 9, 23),
      AnalysisStatus.pending,
    ),
    _test(
      '0007',
      'PT-DEMO-002',
      TestModality.mri,
      DateTime(2026, 9, 2),
      AnalysisStatus.readyForReview,
      DateTime(2026, 9, 3),
    ),
    _test(
      '0008',
      'PT-DEMO-003',
      TestModality.voice,
      DateTime(2026, 9, 21),
      AnalysisStatus.reviewed,
      DateTime(2026, 9, 21),
      'PD',
      1,
      0.7312,
    ),
    _test(
      '0009',
      'PT-DEMO-003',
      TestModality.spiral,
      DateTime(2026, 9, 21),
      AnalysisStatus.reviewed,
      DateTime(2026, 9, 21),
    ),
    _test(
      '0010',
      'PT-DEMO-004',
      TestModality.mri,
      DateTime(2026, 9, 26),
      AnalysisStatus.processing,
    ),
    _test(
      '0011',
      'PT-DEMO-004',
      TestModality.voice,
      DateTime(2026, 9, 18),
      AnalysisStatus.readyForReview,
      DateTime(2026, 9, 18),
      'Healthy',
      0,
      0.08,
    ),
    _test(
      '0012',
      'PT-DEMO-005',
      TestModality.spiral,
      DateTime(2026, 9, 15),
      AnalysisStatus.pending,
    ),
    _test(
      '0013',
      'PT-DEMO-005',
      TestModality.voice,
      DateTime(2026, 8, 28),
      AnalysisStatus.reviewed,
      DateTime(2026, 8, 28),
      'PD',
      1,
      0.9104,
    ),
    _test(
      '0014',
      'PT-DEMO-005',
      TestModality.mri,
      DateTime(2026, 9, 27),
      AnalysisStatus.pending,
    ),
    // PT-DEMO-006 intentionally has no tests (empty state).
    // PT-DEMO-003 and PT-DEMO-006 have no MRI scans (radiologist empty state).
  ];

  static final List<DiagnosticReport> reports = [
    _report(
      '01',
      'PT-DEMO-001',
      '0003',
      ReportStatus.submitted,
      DateTime(2026, 9, 12),
    ),
    _report(
      '02',
      'PT-DEMO-001',
      '0004',
      ReportStatus.submitted,
      DateTime(2026, 8, 22),
    ),
    _report(
      '03',
      'PT-DEMO-002',
      '0005',
      ReportStatus.draft,
      DateTime(2026, 9, 25),
    ),
    _report(
      '04',
      'PT-DEMO-003',
      '0008',
      ReportStatus.submitted,
      DateTime(2026, 9, 22),
    ),
    _report(
      '05',
      'PT-DEMO-003',
      '0009',
      ReportStatus.submitted,
      DateTime(2026, 9, 22),
    ),
    _report(
      '06',
      'PT-DEMO-005',
      '0013',
      ReportStatus.submitted,
      DateTime(2026, 8, 30),
    ),
  ];

  /// Shorthand for building one fake [ClinicalTest].
  static ClinicalTest _test(
    String number,
    String patientId,
    TestModality modality,
    DateTime takenOn,
    AnalysisStatus status, [
    DateTime? analysisCompletedOn,
    String? aiPrediction,
    int? aiPredictionCode,
    double? aiProbabilityPd,
  ]) => ClinicalTest(
    id: 'TS-DEMO-$number',
    patientId: patientId,
    modality: modality,
    takenOn: takenOn,
    status: status,
    analysisCompletedOn: analysisCompletedOn,
    aiPrediction: aiPrediction,
    aiPredictionCode: aiPredictionCode,
    aiProbabilityPd: aiProbabilityPd,
  );

  /// Shorthand for building one fake [DiagnosticReport].
  static DiagnosticReport _report(
    String number,
    String patientId,
    String testNumber,
    ReportStatus status,
    DateTime updatedOn,
  ) => DiagnosticReport(
    id: 'RP-DEMO-$number',
    patientId: patientId,
    testId: 'TS-DEMO-$testNumber',
    title: 'Mock diagnostic report $number',
    clinicalNotes:
        'Fictional placeholder notes for UI demonstration only. '
        'This is not a clinical assessment.',
    recommendations: status == ReportStatus.submitted
        ? 'Fictional placeholder recommendation for UI demonstration only.'
        : '',
    status: status,
    updatedOn: updatedOn,
  );
}
