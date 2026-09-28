import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
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
import '../../shared/data/mock/mock_clinical_data_repository.dart';
import 'app_routes.dart';

/// Builds the application router.
///
/// Each role has its own [ShellRoute], so Doctor and Radiologist screens are
/// wrapped by separate shells. No auth guard exists yet; one can be added
/// later via [GoRouter.redirect].
///
/// [repository] defaults to fictional mock data until the real backend is
/// integrated.
GoRouter createAppRouter({
  String initialLocation = AppRoutes.initial,
  ClinicalDataRepository repository = const MockClinicalDataRepository(),
}) {
  return GoRouter(
    initialLocation: initialLocation,
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
            builder: (context, state) =>
                DoctorDashboardPage(repository: repository),
          ),
          GoRoute(
            path: AppRoutes.doctorPatients,
            name: AppRoutes.doctorPatientsName,
            builder: (context, state) =>
                DoctorPatientsPage(repository: repository),
            routes: [
              GoRoute(
                path: ':${AppRoutes.patientIdParam}',
                name: AppRoutes.doctorPatientProfileName,
                builder: (context, state) => DoctorPatientProfilePage(
                  patientId: state.pathParameters[AppRoutes.patientIdParam]!,
                  repository: repository,
                ),
                routes: [
                  GoRoute(
                    path: 'tests/:${AppRoutes.testIdParam}',
                    name: AppRoutes.doctorTestAnalysisName,
                    builder: (context, state) => DoctorTestAnalysisPage(
                      patientId:
                          state.pathParameters[AppRoutes.patientIdParam]!,
                      testId: state.pathParameters[AppRoutes.testIdParam]!,
                      repository: repository,
                    ),
                  ),
                ],
              ),
            ],
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
                RadiologistDashboardPage(repository: repository),
          ),
          GoRoute(
            path: AppRoutes.radiologistPatients,
            name: AppRoutes.radiologistPatientsName,
            builder: (context, state) =>
                RadiologistPatientsPage(repository: repository),
            routes: [
              GoRoute(
                path: ':${AppRoutes.patientIdParam}',
                name: AppRoutes.radiologistMriHistoryName,
                builder: (context, state) => RadiologistPatientMriHistoryPage(
                  patientId: state.pathParameters[AppRoutes.patientIdParam]!,
                  repository: repository,
                ),
                routes: [
                  GoRoute(
                    path: 'mri/upload',
                    name: AppRoutes.radiologistMriUploadName,
                    builder: (context, state) => RadiologistMriUploadPage(
                      patientId:
                          state.pathParameters[AppRoutes.patientIdParam]!,
                      repository: repository,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
  );
}
