import '../../models/clinical_test.dart';
import '../../models/diagnostic_report.dart';
import '../../models/patient.dart';

/// FICTIONAL demonstration data for UI development only.
///
/// All names and identifiers are invented and do not refer to real people.
/// Do not add real patient information here.
abstract final class MockClinicalData {
  static final List<Patient> patients = [
    Patient(
      id: 'PT-DEMO-001',
      fullName: 'Alex Sample',
      age: 67,
      gender: Gender.male,
      registeredOn: DateTime(2026, 3, 2),
    ),
    Patient(
      id: 'PT-DEMO-002',
      fullName: 'Jamie Example',
      age: 72,
      gender: Gender.female,
      registeredOn: DateTime(2026, 3, 18),
    ),
    Patient(
      id: 'PT-DEMO-003',
      fullName: 'Morgan Testcase',
      age: 59,
      gender: Gender.female,
      registeredOn: DateTime(2026, 4, 7),
    ),
    Patient(
      id: 'PT-DEMO-004',
      fullName: 'Riley Placeholder',
      age: 64,
      gender: Gender.male,
      registeredOn: DateTime(2026, 5, 12),
    ),
    Patient(
      id: 'PT-DEMO-005',
      fullName: 'Casey Demo',
      age: 70,
      gender: Gender.female,
      registeredOn: DateTime(2026, 6, 3),
    ),
    Patient(
      id: 'PT-DEMO-006',
      fullName: 'Taylor Mockwell',
      age: 61,
      gender: Gender.male,
      registeredOn: DateTime(2026, 7, 21),
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

  static ClinicalTest _test(
    String number,
    String patientId,
    TestModality modality,
    DateTime takenOn,
    AnalysisStatus status, [
    DateTime? analysisCompletedOn,
  ]) => ClinicalTest(
    id: 'TS-DEMO-$number',
    patientId: patientId,
    modality: modality,
    takenOn: takenOn,
    status: status,
    analysisCompletedOn: analysisCompletedOn,
  );

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
