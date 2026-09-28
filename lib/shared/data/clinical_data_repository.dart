import '../models/clinical_test.dart';
import '../models/diagnostic_report.dart';
import '../models/patient.dart';

/// Read access to patients, tests and reports.
///
/// The UI depends only on this interface. It is currently implemented by
/// [MockClinicalDataRepository] and will later be implemented against the
/// real backend once its structure is confirmed.
abstract interface class ClinicalDataRepository {
  Future<List<Patient>> getPatients();

  Future<Patient?> getPatient(String patientId);

  /// Tests, newest first. Limited to one patient when [patientId] is given
  /// and to one modality when [modality] is given.
  Future<List<ClinicalTest>> getTests({
    String? patientId,
    TestModality? modality,
  });

  Future<ClinicalTest?> getTest(String testId);

  Future<List<DiagnosticReport>> getReports();

  Future<DiagnosticReport?> getReportForTest(String testId);
}
