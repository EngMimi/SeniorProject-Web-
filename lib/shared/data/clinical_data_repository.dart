import '../models/clinical_test.dart';
import '../models/combined_report.dart';
import '../models/diagnostic_report.dart';
import '../models/patient.dart';

/// Read/write access to patients, tests and reports.
///
/// The UI depends only on this interface. It is implemented by
/// [MockClinicalDataRepository] (fictional, in-memory, for development and
/// tests) and by the real Firestore-backed implementation that talks to the
/// same Firebase project as the Patient Mobile Application.
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

  /// Writes (or overwrites) the doctor's diagnostic report for [testId]
  /// (owned by [patientId]). Matches the fields the diagnostic report form
  /// already collects. When [submit] is true the report becomes visible to
  /// the patient in their mobile app and the test's analysis status becomes
  /// "Reviewed"; when false it's saved as a draft only the doctor can see.
  Future<void> submitReport({
    required String patientId,
    required String testId,
    required String doctorName,
    required String title,
    required String clinicalNotes,
    required String recommendations,
    required bool submit,
  });

  /// Creates a new voice test for [patientId] with an immediate AI
  /// prediction — the caller has already sent the CSV to the voice model
  /// and has a result in hand. Matches what the mobile app writes when a
  /// patient uploads their own voice test.
  Future<void> addVoiceTest({
    required String patientId,
    required String title,
    required String prediction,
    required int predictionCode,
    required double probabilityPd,
  });

  /// Creates a new spiral-drawing test for [patientId]. The caller has
  /// already uploaded the file itself (to Cloudinary); [fileUrl] is where
  /// to find it. No drawing model exists yet, so the test is created with
  /// no prediction — pending review once one does.
  Future<void> addDrawingTest({
    required String patientId,
    required String title,
    required String fileUrl,
  });

  /// Creates a new MRI scan test for [patientId]. The caller has already
  /// uploaded the file itself (to Cloudinary); [fileUrl] is where to find
  /// it. No MRI model exists yet, so the test is created with no
  /// prediction — pending review once one does.
  Future<void> addMriTest({
    required String patientId,
    required String title,
    required String fileUrl,
  });

  /// Combined reports already written for [patientId], newest first.
  Future<List<CombinedReport>> getCombinedReports({
    required String patientId,
  });

  /// Creates or updates a diagnostic report that covers several of
  /// [patientId]'s tests at once. Pass [reportId] (from a prior draft save)
  /// to update that same report instead of creating a new one; returns the
  /// report's id either way, so the caller can keep editing the same draft.
  ///
  /// When [submit] is true, every test in [testIds] is also marked
  /// "reviewed" so the doctor's Test History and dashboard stay consistent
  /// with the combined report having been written.
  Future<String> submitCombinedReport({
    String? reportId,
    required String patientId,
    required List<String> testIds,
    required String doctorName,
    required String title,
    required String clinicalNotes,
    required String recommendations,
    required bool submit,
  });
}
