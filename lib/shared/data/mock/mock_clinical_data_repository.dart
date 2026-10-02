import '../../models/clinical_test.dart';
import '../../models/combined_report.dart';
import '../../models/diagnostic_report.dart';
import '../../models/patient.dart';
import '../clinical_data_repository.dart';
import 'mock_clinical_data.dart';

/// In-memory [ClinicalDataRepository] backed by [MockClinicalData].
class MockClinicalDataRepository implements ClinicalDataRepository {
  const MockClinicalDataRepository();

  @override
  Future<List<Patient>> getPatients() async =>
      List.unmodifiable(MockClinicalData.patients);

  @override
  Future<Patient?> getPatient(String patientId) async =>
      MockClinicalData.patients.where((p) => p.id == patientId).firstOrNull;

  @override
  Future<List<ClinicalTest>> getTests({
    String? patientId,
    TestModality? modality,
  }) async {
    final tests = [
      for (final test in MockClinicalData.tests)
        if ((patientId == null || test.patientId == patientId) &&
            (modality == null || test.modality == modality))
          test,
    ];
    tests.sort((a, b) {
      final byDate = b.takenOn.compareTo(a.takenOn);
      return byDate != 0 ? byDate : b.id.compareTo(a.id);
    });
    return List.unmodifiable(tests);
  }

  @override
  Future<ClinicalTest?> getTest(String testId) async =>
      MockClinicalData.tests.where((t) => t.id == testId).firstOrNull;

  @override
  Future<List<DiagnosticReport>> getReports() async =>
      List.unmodifiable(MockClinicalData.reports);

  @override
  Future<DiagnosticReport?> getReportForTest(String testId) async =>
      MockClinicalData.reports.where((r) => r.testId == testId).firstOrNull;

  @override
  Future<void> submitReport({
    required String patientId,
    required String testId,
    required String doctorName,
    required String title,
    required String clinicalNotes,
    required String recommendations,
    required bool submit,
  }) async {
    // Mock data is fictional and read-only for UI development; writes here
    // are intentionally not persisted. The real Firestore-backed repository
    // is what actually saves a doctor's report.
  }

  @override
  Future<void> addVoiceTest({
    required String patientId,
    required String title,
    required String prediction,
    required int predictionCode,
    required double probabilityPd,
  }) async {
    // Mock data is read-only; see submitReport above.
  }

  @override
  Future<void> addDrawingTest({
    required String patientId,
    required String title,
    required String fileUrl,
  }) async {
    // Mock data is read-only; see submitReport above.
  }

  @override
  Future<void> addMriTest({
    required String patientId,
    required String title,
    required String fileUrl,
  }) async {
    // Mock data is read-only; see submitReport above.
  }

  @override
  Future<List<CombinedReport>> getCombinedReports({
    required String patientId,
  }) async => const [];

  @override
  Future<String> submitCombinedReport({
    String? reportId,
    required String patientId,
    required List<String> testIds,
    required String doctorName,
    required String title,
    required String clinicalNotes,
    required String recommendations,
    required bool submit,
  }) async {
    // Mock data is read-only; see submitReport above.
    return reportId ?? 'mock-combined-report';
  }
}
