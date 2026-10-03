# INFO.md

Permanent project context and development rules for Claude Code sessions.
Read this file before making any changes.

## Project

**NeuroInsight-PD** — Multi-Modal Parkinson's Detection and Telemonitoring System.

## Scope of this repository

This repository is **only the Flutter Web application**.

- The **Patient Mobile Application** already exists as a separate Flutter
  project (`neuroinsight_pd_app`), developed by another team member. It is
  not part of this repo, but it shares the same Firebase project and the
  same Firestore data model.
- **Web users:** Doctor, Radiologist.
- **Patients** use the mobile application.

## System modalities and AI model owners

| Modality | AI model owner |
|---|---|
| Voice recordings | Refaa |
| Hand-drawn spiral images | Ruba |
| Brain MRI scans | Amani |

AI models are separate services from Flutter — each one is a small backend
hosted on its own (currently Render), reached over HTTP. They must **never**
be recreated, reimplemented, or trained inside the web frontend. The web app
only sends a file to the model's API and displays the result it returns.

Live model endpoints:

| Modality | Base URL | Predict endpoint |
|---|---|---|
| Voice | `https://neuroinsight-voicemodel.onrender.com` | `POST /predict` (JSON: `{"features": {...}}`) |
| Spiral drawing | `https://drawing-backend-iz1o.onrender.com` | `POST /predict` (multipart, field `file`) |
| Brain MRI | `https://mri-backend-1.onrender.com` | `POST /predict/mri` (multipart, field `file`) |

These are free-tier services and can take up to ~60 seconds to respond after
being idle (cold start), so client timeouts are set to 60s. Each model's
request/response shape is implemented in its own service class under
`lib/shared/data/` (`voice_model_service.dart`, `drawing_model_service.dart`,
`mri_model_service.dart`) — do not guess or change these shapes without
confirming them against the model's own API.

## Role responsibilities

### Doctor
- Login
- Dashboard
- Patient list
- Patient profile
- Test history
- View Voice AI results
- View Spiral AI results
- View MRI AI results
- Upload voice/spiral when required during a visit
- Write and view diagnostic reports (single-test and combined/multi-test)
- Monitor patient history

### Radiologist
- Login
- Dashboard
- Relevant patient access
- MRI history
- Upload MRI scans
- Submit MRI scans for analysis
- View MRI analysis status/results where appropriate

## Medical rule

AI results are **decision-support information only**.

- Never present an AI prediction as a final medical diagnosis, in UI text,
  labels, or code naming.
- The **doctor** is responsible for the diagnostic report.

## Firebase / backend

The web app uses the **same Firebase project** (`neuroinsight-784ee`) as the
Patient Mobile Application: Firebase Auth, Cloud Firestore, and Cloudinary
(not Firebase Storage) for uploaded images.

- Staff accounts (doctor/radiologist) live in the `users` Firestore
  collection, with a `role` field (`"doctor"` or `"radiologist"`) and an
  `employeeId` field. Sign-in looks up the account's email by `employeeId`,
  then signs in with Firebase Auth using that email and the entered
  password. Patient-only accounts (no matching role) cannot sign in here.
- Clinical tests, predictions and diagnostic reports are read and written
  through `ClinicalDataRepository`
  (`lib/shared/data/clinical_data_repository.dart`), implemented for
  production by `FirebaseClinicalDataRepository`
  (`lib/shared/data/firebase/`). `MockClinicalDataRepository`
  (`lib/shared/data/mock/`) is a fictional, read-only, in-memory
  implementation kept only for widget tests — it is not used when the app
  runs for real.

**Do NOT:**
- create another Firebase project
- invent Firestore collections or fields without checking how the mobile
  app (or the existing repository code) already uses them
- invent Storage paths — uploaded images go to Cloudinary, not Firebase
  Storage
- invent AI model API endpoints or response shapes — confirm against the
  model's own API (ask for its `/docs` page if unsure)
- invent authentication/role structures
- hardcode secrets or credentials

## Current state of development

- Flutter Web, Dart
- Tools: VS Code, Chrome, Git
- Routing: `go_router`
- Real Firebase integration: Firebase Auth + Cloud Firestore, shared with
  the mobile app's project
- No Riverpod (state management kept simple: `ChangeNotifier` for auth,
  `FutureBuilder`/local state elsewhere)
- Doctor UI (dashboard, patients, patient profile, test analysis,
  single-test and combined diagnostic reports) is backed by real Firestore
  data via `FirebaseClinicalDataRepository`
- Radiologist UI (dashboard, patients, patient MRI history, MRI upload) is
  backed by the same real repository. Radiologist pages load only MRI tests
  (`getTests(modality: TestModality.mri)`) and expose no Doctor-only actions
- Voice, spiral-drawing and MRI uploads all go through a real file/image
  picker, are sent to their live AI model for a prediction, are then
  uploaded to Cloudinary, and the test + real prediction are saved to
  Firestore via the repository
- Diagnostic reports (single-test via `DiagnosticReportSection`, and
  multi-test via `DoctorCombinedReportPage`) are real: "Save Draft" and
  "Submit Diagnostic Report" both persist to Firestore through the
  repository; submitting makes the report visible to the patient in the
  mobile app
- Light theme only; colors are centralized in `core/theme/app_colors.dart`
- `flutter analyze` currently passes
- `flutter test` currently passes (tests run against `MockClinicalDataRepository`
  and a debug `AuthService`, not real Firebase)

### Temporary development login

`lib/features/auth/presentation/widgets/dev_access_panel.dart` (shown on the
login page in a "DEVELOPMENT ONLY" panel) contains two buttons,
"Continue as Doctor (dev)" and "Continue as Radiologist (dev)", that jump
straight into a role's dashboard, skipping sign-in entirely. They exist
alongside the real sign-in form (which does a real Firebase Auth sign-in —
see "Firebase / backend" above) and are **temporary**: remove them once
real authentication is the only way in. There is currently **no route
guard**; role authorization will be added via `GoRouter.redirect` once
needed.

### Test-only mock data

- `MockClinicalDataRepository`
  (`lib/shared/data/mock/mock_clinical_data_repository.dart`), backed by the
  fictional dataset in `lib/shared/data/mock/mock_clinical_data.dart`, is
  used only by the widget tests under `test/`. It is read-only (writes are
  no-ops) and is never wired into the app's real router/repository.
- Models (`lib/shared/models/`) match the real Firestore structure used by
  both apps — keep them in sync if that structure changes.

## Architecture

Feature-based structure — maintain it:

```
lib/
  main.dart                      Entry point
  app/
    app.dart                     NeuroInsightApp (MaterialApp.router)
    router/
      app_routes.dart            Route path/name constants
      app_router.dart            createAppRouter(): one ShellRoute per role
  core/
    theme/                       AppTheme, AppColors, AppSpacing, AppRadius
    responsive/                  Breakpoints, ResponsiveLayout
    utils/                       formatDate
  shared/
    models/                      Patient, ClinicalTest, DiagnosticReport,
                                 CombinedReport
    data/                        ClinicalDataRepository (interface),
                                 CloudinaryUploadService,
                                 VoiceModelService, DrawingModelService,
                                 MriModelService
      firebase/                  FirebaseClinicalDataRepository (real backend)
      mock/                      MockClinicalDataRepository (tests only)
    widgets/                     RoleShellScaffold, PageContainer, PageHeader,
                                 SummaryCard,
                                 Breadcrumbs, SectionCard, ResponsiveTable,
                                 InfoField, FutureContent, MessageState,
                                 PlaceholderPage
      clinical/                  StatusBadge, ResultAvailabilityLabel,
                                 ClinicalNotice,
                                 AiAnalysisResultCard
  features/
    auth/
      data/                      AuthService (Firebase Auth + Firestore role lookup)
      presentation/
        pages/                   LoginPage, SettingsPage
        widgets/                 LoginForm, DevAccessPanel (temporary)
    doctor/presentation/
      shell/                     DoctorShell
      pages/                     DoctorDashboardPage, DoctorPatientsPage,
                                 DoctorPatientProfilePage,
                                 DoctorTestAnalysisPage,
                                 DoctorCombinedReportPage
      widgets/                   DiagnosticReportSection
    radiologist/presentation/
      shell/                     RadiologistShell
      pages/                     RadiologistDashboardPage, RadiologistPatientsPage,
                                 RadiologistPatientMriHistoryPage,
                                 RadiologistMriUploadPage
test/
  widget_test.dart               Login page and routing tests
  doctor_flow_test.dart          Doctor UI flow tests
  radiologist_flow_test.dart     Radiologist UI flow tests
```

Routes: `/login`, `/doctor/dashboard`, `/doctor/patients`,
`/doctor/patients/:patientId`, `/doctor/patients/:patientId/tests/:testId`,
`/radiologist/dashboard`, `/radiologist/patients`,
`/radiologist/patients/:patientId` (MRI history),
`/radiologist/patients/:patientId/mri/upload`. Build nested paths with the
`AppRoutes.doctorPatientProfile(...)`, `AppRoutes.doctorTestAnalysis(...)`,
`AppRoutes.radiologistMriHistory(...)` and `AppRoutes.radiologistMriUpload(...)`
helpers. `/doctor` and
`/radiologist` redirect to their dashboards.

Keep:
- app configuration/routing separate
- core/shared utilities reusable
- Doctor and Radiologist role separation
- UI independent from the Firebase implementation (always go through
  `ClinicalDataRepository`, never call Firestore directly from a page/widget)
- repositories/services abstracted behind interfaces (real
  `FirebaseClinicalDataRepository` for the app, fictional
  `MockClinicalDataRepository` for tests)

Do not create unnecessary abstractions before they are needed.

## Development rules

1. Read this file (INFO.md) before making changes.
2. Inspect existing code before modifying it.
3. Do not make major architecture changes without approval.
4. Do not add dependencies without explaining why first.
5. Do not change the Firestore schema, Cloudinary usage, or an AI model's
   request/response shape without confirming it — the mobile app and the
   live models depend on these staying consistent.
6. Never use real patient information as mock/test data.
7. Use clearly fictional data in tests.
8. Never expose medical information unnecessarily.
9. Keep Doctor and Radiologist authorization separated.
10. Do not implement requirements that have not been confirmed.
11. Ask when an important requirement is unknown.
12. Keep code maintainable for a university team project.
13. After meaningful changes, run `flutter analyze` and relevant tests.
14. Do not continue into another major development phase without approval.

## Commands

```
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```
