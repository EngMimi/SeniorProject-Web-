import '../../models/clinical_test.dart';
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
}
