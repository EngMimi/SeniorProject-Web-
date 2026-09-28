# CLAUDE.md

Permanent project context and development rules for Claude Code sessions.
Read this file before making any changes.

## Project

**NeuroInsight-PD** — Multi-Modal Parkinson's Detection and Telemonitoring System.

## Scope of this repository

This repository is **only the Flutter Web application**.

- The **Patient Mobile Application** already exists as a separate Flutter
  project, developed by another team member. It is not part of this repo.
- **Web users:** Doctor, Radiologist.
- **Patients** primarily use the existing mobile application.

## System modalities and AI model owners

| Modality | AI model owner |
|---|---|
| Voice recordings | Refaa |
| Hand-drawn spiral images | Ruba |
| Brain MRI scans | Amani |

AI models are separate from Flutter. They must **never** be recreated,
reimplemented, or trained inside the web frontend. The web app only displays
results produced by those models.

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
- Write and view diagnostic reports
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

An existing Firebase project named **"neuroinsight"** is already used by the
Patient Mobile Application. The web app must eventually integrate with the
**same** backend/cloud system as the mobile app.

**Do NOT:**
- create another Firebase project
- configure Firebase until the existing architecture is confirmed
- invent Firestore collections or fields
- invent Storage paths
- invent API endpoints
- invent authentication/role structures
- hardcode secrets or credentials

## Current state of development

- Flutter Web, Dart
- Tools: VS Code, Chrome, Git
- Routing: `go_router` (the only added dependency)
- No Firebase integration yet
- No Riverpod (state management kept simple for now)
- Login page and Doctor UI (dashboard, patients, patient profile, test
  analysis + diagnostic report) are implemented as UI only, on mock data
- Radiologist UI (dashboard, patients, patient MRI history, MRI upload) is
  implemented as UI only, on mock data. Radiologist pages load only MRI tests
  (`getTests(modality: TestModality.mri)`) and expose no Doctor-only actions
- MRI file selection/upload is a UI-only placeholder: no file-picker package,
  and no accepted formats, size limits or storage are assumed
- Light theme only; colors are centralized in `core/theme/app_colors.dart`
- `flutter analyze` currently passes
- `flutter test` currently passes

### Temporary development login

`lib/features/auth/presentation/widgets/dev_access_panel.dart` (shown on the
login page in a "DEVELOPMENT ONLY" panel) contains two buttons,
"Continue as Doctor (dev)" and "Continue as Radiologist (dev)", that navigate
directly into each role's shell. They are **temporary** and must eventually be
replaced by real authentication. The Sign In button only validates input and
shows a "not available yet" message. There is currently **no route guard**; role
authorization will be added via `GoRouter.redirect` once the real
authentication/role structure is confirmed.

### Mock data (temporary)

- All Doctor and Radiologist data comes from `ClinicalDataRepository`
  (`lib/shared/data/clinical_data_repository.dart`), currently implemented by
  `MockClinicalDataRepository`, which reads the fictional dataset in
  `lib/shared/data/mock/mock_clinical_data.dart`. Replace the implementation
  (not the UI) when the real backend structure is confirmed. The repository is
  passed to pages via `createAppRouter(repository: ...)`.
- Models (`lib/shared/models/`) are UI-driven placeholders and must be aligned
  with the real backend once it is confirmed.
- AI results show only generic information; the model output area is an
  explicit placeholder because the real output schemas are not confirmed.
- Upload, Save Draft and Submit actions are UI-only (they show a
  "not available yet" message).
- Pages showing mock data display a "Mock data" notice.

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
    models/                      Patient, ClinicalTest, DiagnosticReport
    data/                        ClinicalDataRepository (+ mock/ implementation)
    widgets/                     RoleShellScaffold, PageContainer, PageHeader,
                                 SummaryCard,
                                 Breadcrumbs, SectionCard, ResponsiveTable,
                                 InfoField, FutureContent, MessageState,
                                 MockDataNotice, PlaceholderPage
      clinical/                  StatusBadge, ResultAvailabilityLabel,
                                 ClinicalNotice,
                                 AiAnalysisResultCard
  features/
    auth/presentation/
      pages/                     LoginPage
      widgets/                   LoginForm, DevAccessPanel (temporary)
    doctor/presentation/
      shell/                     DoctorShell
      pages/                     DoctorDashboardPage, DoctorPatientsPage,
                                 DoctorPatientProfilePage,
                                 DoctorTestAnalysisPage
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
- UI independent from the Firebase implementation
- repositories/services abstracted when data features are introduced
  (mock implementations with clearly fictional data first, replaceable later
  by the real backend implementations)

Do not create unnecessary abstractions before they are needed.

## Development rules

1. Read CLAUDE.md before making changes.
2. Inspect existing code before modifying it.
3. Do not make major architecture changes without approval.
4. Do not add dependencies without explaining why first.
5. Do not integrate Firebase until its real structure is provided.
6. Never use real patient information as mock data.
7. Use clearly fictional data for development.
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
