import '../models/clinical_test.dart';
import '../models/combined_report.dart';
import '../models/diagnostic_report.dart';
import '../models/patient.dart';

// Defines how the app talks to patient/test/report data, without caring
// whether that data is mock data or real Firestore data.

/// The contract for reading and writing patients, tests and reports.
///
/// The UI only depends on this interface, not on where the data actually
/// comes from. [MockClinicalDataRepository] implements it with fake
/// in-memory data for development, and the Firestore-backed class
/// implements it with the real database shared with the Patient Mobile App.
abstract interface class ClinicalDataRepository {
  Future<List<Patient>> getPatients();

  Future<Patient?> getPatient(String patientId);

  /// Gets tests, newest first. Can filter to one patient and/or one modality.
  Future<List<ClinicalTest>> getTests({
    String? patientId,
    TestModality? modality,
  });

  Future<ClinicalTest?> getTest(String testId);

  Future<List<DiagnosticReport>> getReports();

  Future<DiagnosticReport?> getReportForTest(String testId);

  /// Saves the doctor's report for one test. If [submit] is true, it
  /// becomes visible to the patient and the test is marked "Reviewed";
  /// otherwise it's saved as a draft only the doctor can see.
  Future<void> submitReport({
    required String patientId,
    required String testId,
    required String doctorName,
    required String title,
    required String clinicalNotes,
    required String recommendations,
    required bool submit,
  });

  /// Saves a new voice test for [patientId]. The caller has already sent
  /// the CSV to the voice model and is passing in the prediction result.
  Future<void> addVoiceTest({
    required String patientId,
    required String title,
    required String prediction,
    required int predictionCode,
    required double probabilityPd,
  });

  /// Saves a new spiral-drawing test for [patientId]. The image was already
  /// uploaded to Cloudinary ([fileUrl]) and sent to the drawing model.
  Future<void> addDrawingTest({
    required String patientId,
    required String title,
    required String fileUrl,
    required String prediction,
    required int predictionCode,
    required double probabilityPd,
  });

  /// Saves a new MRI scan test for [patientId]. The image was already
  /// uploaded to Cloudinary ([fileUrl]) and sent to the MRI model.
  Future<void> addMriTest({
    required String patientId,
    required String title,
    required String fileUrl,
    required String prediction,
    required int predictionCode,
    required double probabilityPd,
  });

  /// Gets combined reports already written for [patientId], newest first.
  Future<List<CombinedReport>> getCombinedReports({
    required String patientId,
  });

  /// Creates or updates a report covering several of [patientId]'s tests
  /// at once. Pass [reportId] to update an existing draft instead of
  /// creating a new one. If [submit] is true, every test in [testIds] is
  /// also marked "reviewed".
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
