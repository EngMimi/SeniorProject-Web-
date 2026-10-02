import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_service.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/settings_page.dart';
import '../../features/doctor/presentation/pages/doctor_combined_report_page.dart';
import '../../features/doctor/presentation/pages/doctor_dashboard_page.dart';
import '../../features/doctor/presentation/pages/doctor_patient_profile_page.dart';
import '../../features/doctor/presentation/pages/doctor_patients_page.dart';
import '../../features/doctor/presentation/pages/doctor_test_analysis_page.dart';
import '../../features/doctor/presentation/shell/doctor_shell.dart';
import '../../features/radiologist/presentation/pages/radiologist_dashboard_page.dart';
import '../../features/radiologist/presentation/pages/radiologist_mri_upload_page.dart';
import '../../features/radiologist/presentation/pages/radiologist_patient_mri_history_page.dart';
import '../../features/radiologist/presentation/pages/radiologist_patients_page.dart';
import '../../features/radiologist/presentation/shell/radiologist_shell.dart';
import '../../shared/data/clinical_data_repository.dart';
import '../../shared/data/firebase/firebase_clinical_data_repository.dart';
import 'app_routes.dart';

/// Builds the application router.
///
/// Each role has its own [ShellRoute], so Doctor and Radiologist screens are
/// wrapped by separate shells. [AuthService.instance] gates every Doctor and
/// Radiologist route: signed-out visitors are sent to [AppRoutes.login], and
/// a signed-in account is kept inside its own role's section.
///
/// [repository] defaults to the real Firestore-backed repository (same
/// Firebase project as the Patient Mobile Application). Pass a
/// [MockClinicalDataRepository] instead for widget tests.
GoRouter createAppRouter({
  String initialLocation = AppRoutes.initial,
  ClinicalDataRepository? repository,
}) {
  final repo = repository ?? FirebaseClinicalDataRepository();

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: AuthService.instance,
    redirect: (context, state) {
      final auth = AuthService.instance;
      // Auth state hasn't resolved yet (first frame); don't redirect until
      // we actually know whether someone is signed in.
      if (auth.loading) return null;

      final atLogin = state.matchedLocation == AppRoutes.login;

      if (!auth.isSignedIn) {
        return atLogin ? null : AppRoutes.login;
      }

      if (atLogin) {
        return auth.role == StaffRole.doctor
            ? AppRoutes.doctorDashboard
            : AppRoutes.radiologistDashboard;
      }

      final inDoctorArea = state.matchedLocation.startsWith(
        AppRoutes.doctorRoot,
      );
      final inRadiologistArea = state.matchedLocation.startsWith(
        AppRoutes.radiologistRoot,
      );

      if (inDoctorArea && auth.role != StaffRole.doctor) {
        return AppRoutes.radiologistDashboard;
      }
      if (inRadiologistArea && auth.role != StaffRole.radiologist) {
        return AppRoutes.doctorDashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginPage(),
      ),

      // Doctor
      GoRoute(
        path: AppRoutes.doctorRoot,
        redirect: (context, state) => AppRoutes.doctorDashboard,
      ),
      ShellRoute(
        builder: (context, state, child) => DoctorShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.doctorDashboard,
            name: AppRoutes.doctorDashboardName,
            builder: (context, state) => DoctorDashboardPage(repository: repo),
          ),
          GoRoute(
            path: AppRoutes.doctorPatients,
            name: AppRoutes.doctorPatientsName,
            builder: (context, state) => DoctorPatientsPage(repository: repo),
            routes: [
              GoRoute(
                path: ':${AppRoutes.patientIdParam}',
                name: AppRoutes.doctorPatientProfileName,
                builder: (context, state) => DoctorPatientProfilePage(
                  patientId: state.pathParameters[AppRoutes.patientIdParam]!,
                  repository: repo,
                ),
                routes: [
                  GoRoute(
                    path: 'tests/:${AppRoutes.testIdParam}',
                    name: AppRoutes.doctorTestAnalysisName,
                    builder: (context, state) => DoctorTestAnalysisPage(
                      patientId:
                          state.pathParameters[AppRoutes.patientIdParam]!,
                      testId: state.pathParameters[AppRoutes.testIdParam]!,
                      repository: repo,
                    ),
                  ),
                  GoRoute(
                    path: 'combined-report',
                    name: AppRoutes.doctorCombinedReportName,
                    builder: (context, state) => DoctorCombinedReportPage(
                      patientId:
                          state.pathParameters[AppRoutes.patientIdParam]!,
                      repository: repo,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.doctorSettings,
            name: AppRoutes.doctorSettingsName,
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),

      // Radiologist
      GoRoute(
        path: AppRoutes.radiologistRoot,
        redirect: (context, state) => AppRoutes.radiologistDashboard,
      ),
      ShellRoute(
        builder: (context, state, child) => RadiologistShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.radiologistDashboard,
            name: AppRoutes.radiologistDashboardName,
            builder: (context, state) =>
                RadiologistDashboardPage(repository: repo),
          ),
          GoRoute(
            path: AppRoutes.radiologistPatients,
            name: AppRoutes.radiologistPatientsName,
            builder: (context, state) =>
                RadiologistPatientsPage(repository: repo),
            routes: [
              GoRoute(
                path: ':${AppRoutes.patientIdParam}',
                name: AppRoutes.radiologistMriHistoryName,
                builder: (context, state) => RadiologistPatientMriHistoryPage(
                  patientId: state.pathParameters[AppRoutes.patientIdParam]!,
                  repository: repo,
                ),
                routes: [
                  GoRoute(
                    path: 'mri/upload',
                    name: AppRoutes.radiologistMriUploadName,
                    builder: (context, state) => RadiologistMriUploadPage(
                      patientId:
                          state.pathParameters[AppRoutes.patientIdParam]!,
                      repository: repo,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.radiologistSettings,
            name: AppRoutes.radiologistSettingsName,
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
  );
}
