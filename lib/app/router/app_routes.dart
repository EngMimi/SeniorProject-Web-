/// Central route path and name constants.
///
/// Doctor and Radiologist routes live under separate path prefixes so each
/// role can have its own shell and, later, its own access guard.
abstract final class AppRoutes {
  // Auth
  static const String login = '/login';
  static const String loginName = 'login';

  // Doctor
  static const String doctorRoot = '/doctor';
  static const String doctorDashboard = '$doctorRoot/dashboard';
  static const String doctorDashboardName = 'doctor-dashboard';
  static const String doctorPatients = '$doctorRoot/patients';
  static const String doctorPatientsName = 'doctor-patients';
  static const String doctorPatientProfileName = 'doctor-patient-profile';
  static const String doctorTestAnalysisName = 'doctor-test-analysis';
  static const String doctorCombinedReportName = 'doctor-combined-report';
  static const String doctorSettings = '$doctorRoot/settings';
  static const String doctorSettingsName = 'doctor-settings';

  // Helpers below build the actual URL for a given patient/test, since
  // those routes need a real ID filled in (not just the path pattern).
  static String doctorPatientProfile(String patientId) =>
      '$doctorPatients/$patientId';

  static String doctorTestAnalysis(String patientId, String testId) =>
      '${doctorPatientProfile(patientId)}/tests/$testId';

  static String doctorCombinedReport(String patientId) =>
      '${doctorPatientProfile(patientId)}/combined-report';

  // Radiologist
  static const String radiologistRoot = '/radiologist';
  static const String radiologistDashboard = '$radiologistRoot/dashboard';
  static const String radiologistDashboardName = 'radiologist-dashboard';
  static const String radiologistPatients = '$radiologistRoot/patients';
  static const String radiologistPatientsName = 'radiologist-patients';
  static const String radiologistMriHistoryName = 'radiologist-mri-history';
  static const String radiologistMriUploadName = 'radiologist-mri-upload';
  static const String radiologistSettings = '$radiologistRoot/settings';
  static const String radiologistSettingsName = 'radiologist-settings';

  static String radiologistMriHistory(String patientId) =>
      '$radiologistPatients/$patientId';

  static String radiologistMriUpload(String patientId) =>
      '${radiologistMriHistory(patientId)}/mri/upload';

  // Path parameters
  static const String patientIdParam = 'patientId';
  static const String testIdParam = 'testId';

  static const String initial = login;
}
