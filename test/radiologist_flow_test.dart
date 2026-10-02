import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroinsight_pd_web/app/app.dart';
import 'package:neuroinsight_pd_web/app/router/app_router.dart';
import 'package:neuroinsight_pd_web/app/router/app_routes.dart';
import 'package:neuroinsight_pd_web/features/auth/data/auth_service.dart';
import 'package:neuroinsight_pd_web/shared/data/mock/mock_clinical_data_repository.dart';
import 'package:neuroinsight_pd_web/shared/widgets/clinical/clinical_notice.dart';

// Fictional IDs from MockClinicalData.
const _alexId = 'PT-DEMO-001'; // 1 MRI + voice/spiral tests
const _alexMriScan = 'TS-DEMO-0003';
const _alexNonMriTests = ['TS-DEMO-0001', 'TS-DEMO-0002', 'TS-DEMO-0004'];
const _morganId = 'PT-DEMO-003'; // no MRI scans

/// Labels that belong only to the Doctor workflow.
const _doctorOnlyLabels = [
  'Upload Voice Recording',
  'Upload Spiral Drawing',
  'Diagnostic Report',
  'Submit Diagnostic Report',
  'Save Draft',
  'Report title',
];

Future<void> _pumpAt(
  WidgetTester tester,
  String location, {
  Size size = const Size(1440, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // Fake, already-signed-in radiologist account — the real AuthService
  // only runs against Firebase, which these widget tests never touch.
  AuthService.debugSetInstance(
    AuthService.debug(role: StaffRole.radiologist),
  );

  final router = createAppRouter(
    initialLocation: location,
    repository: const MockClinicalDataRepository(),
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(NeuroInsightApp(router: router));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _expectNoDoctorOnlyActions() {
  for (final label in _doctorOnlyLabels) {
    expect(find.text(label), findsNothing, reason: '"$label" is Doctor-only');
  }
}

void main() {
  group('Radiologist Dashboard', () {
    testWidgets('renders MRI-only summary and recent activity', (tester) async {
      await _pumpAt(tester, AppRoutes.radiologistDashboard);

      expect(find.text('Radiologist Dashboard'), findsOneWidget);
      for (final label in [
        'Total Patients',
        'Total MRI Scans',
        'Waiting for Analysis',
        'Analysis Ready',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Recent MRI Activity'), findsOneWidget);
      expect(find.text('View MRI History'), findsNWidgets(4));
      expect(find.text('Voice'), findsNothing);
      expect(find.text('Spiral Drawing'), findsNothing);
      for (final id in _alexNonMriTests) {
        expect(find.text(id), findsNothing);
      }
      _expectNoDoctorOnlyActions();
    });

    testWidgets('View MRI History opens the patient MRI history', (
      tester,
    ) async {
      await _pumpAt(tester, AppRoutes.radiologistDashboard);

      await _tapVisible(tester, find.text('View MRI History').first);

      expect(find.text('MRI History'), findsOneWidget);
      expect(find.text('Upload MRI Scan'), findsOneWidget);
    });
  });

  group('Radiologist Patients', () {
    testWidgets('lists patients, search filters, and opens MRI history', (
      tester,
    ) async {
      await _pumpAt(tester, AppRoutes.radiologistPatients);

      expect(find.text('Patient List'), findsOneWidget);
      expect(find.text('Open Profile'), findsNWidgets(6));

      await tester.enterText(find.byType(TextField), 'PT-DEMO-002');
      await tester.pumpAndSettle();
      expect(find.text('Open Profile'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'nobody');
      await tester.pumpAndSettle();
      expect(find.text('No patients match your search.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'jamie');
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Open Profile'));

      expect(find.text('MRI History'), findsOneWidget);
      expect(find.text('Jamie Example'), findsWidgets);
    });
  });

  group('Patient MRI History', () {
    testWidgets('shows only MRI scans and no Doctor-only actions', (
      tester,
    ) async {
      await _pumpAt(tester, AppRoutes.radiologistMriHistory(_alexId));

      expect(find.text('Alex Sample'), findsWidgets);
      expect(find.text(_alexMriScan), findsOneWidget);
      for (final id in _alexNonMriTests) {
        expect(find.text(id), findsNothing);
      }
      expect(find.text('View Analysis'), findsOneWidget);
      _expectNoDoctorOnlyActions();
    });

    testWidgets('View Analysis shows the generic AI result with the notice', (
      tester,
    ) async {
      await _pumpAt(tester, AppRoutes.radiologistMriHistory(_alexId));

      await _tapVisible(tester, find.text('View Analysis'));

      expect(find.text('AI Analysis Result'), findsOneWidget);
      expect(find.text(aiDecisionSupportNotice), findsOneWidget);
      _expectNoDoctorOnlyActions();

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('AI Analysis Result'), findsNothing);
    });

    testWidgets('Upload MRI Scan opens the upload page', (tester) async {
      await _pumpAt(tester, AppRoutes.radiologistMriHistory(_alexId));

      await _tapVisible(tester, find.text('Upload MRI Scan'));

      expect(find.text('Submit for Analysis'), findsOneWidget);
    });

    testWidgets('patient without MRI scans shows empty state with upload', (
      tester,
    ) async {
      await _pumpAt(tester, AppRoutes.radiologistMriHistory(_morganId));

      expect(find.text('No MRI scans yet'), findsOneWidget);
      // Header action + empty-state action.
      expect(find.text('Upload MRI Scan'), findsNWidgets(2));

      await _tapVisible(tester, find.text('Upload MRI Scan').last);
      expect(find.text('Submit for Analysis'), findsOneWidget);
    });

    testWidgets('invalid patient ID shows a safe not-found state', (
      tester,
    ) async {
      await _pumpAt(tester, AppRoutes.radiologistMriHistory('PT-UNKNOWN'));

      expect(find.text('Patient not found'), findsOneWidget);
      await tester.tap(find.text('Back to Patients'));
      await tester.pumpAndSettle();
      expect(find.text('Patient List'), findsOneWidget);
    });
  });

  group('MRI Upload', () {
    testWidgets('renders patient context, upload area and actions', (
      tester,
    ) async {
      await _pumpAt(tester, AppRoutes.radiologistMriUpload(_alexId));

      expect(find.text('Upload MRI Scan'), findsWidgets);
      expect(find.text('Alex Sample'), findsWidgets);
      expect(find.text(_alexId), findsOneWidget);
      expect(find.text('No file selected'), findsOneWidget);
      expect(find.text('Select MRI Scan File'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Submit for Analysis'), findsOneWidget);
      _expectNoDoctorOnlyActions();
    });

    testWidgets('Submit for Analysis with no file picked shows a prompt', (
      tester,
    ) async {
      await _pumpAt(tester, AppRoutes.radiologistMriUpload(_alexId));

      await _tapVisible(tester, find.text('Submit for Analysis'));

      final snackBar = find.byType(SnackBar);
      expect(snackBar, findsOneWidget);
      expect(
        find.descendant(
          of: snackBar,
          matching: find.text('Select an MRI scan file first.'),
        ),
        findsOneWidget,
      );
    });

    // "Select MRI Scan File" now opens a real file picker (uploads to
    // Cloudinary on submit), which isn't exercised here — same as the
    // doctor's voice/drawing upload buttons in doctor_flow_test.dart.

    testWidgets('Cancel and breadcrumbs return to the MRI history', (
      tester,
    ) async {
      await _pumpAt(tester, AppRoutes.radiologistMriUpload(_alexId));

      await _tapVisible(tester, find.text('Cancel'));
      expect(find.text('MRI History'), findsOneWidget);

      await _tapVisible(tester, find.text('Upload MRI Scan'));
      await tester.tap(find.widgetWithText(TextButton, 'Alex Sample'));
      await tester.pumpAndSettle();
      expect(find.text('MRI History'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Patients'));
      await tester.pumpAndSettle();
      expect(find.text('Patient List'), findsOneWidget);
    });

    testWidgets('invalid patient ID shows a safe not-found state', (
      tester,
    ) async {
      await _pumpAt(tester, AppRoutes.radiologistMriUpload('PT-UNKNOWN'));

      expect(find.text('Patient not found'), findsOneWidget);
      expect(find.text('Submit for Analysis'), findsNothing);
    });
  });

  group('Radiologist navigation', () {
    testWidgets('sidebar has Dashboard, Patients and Settings', (
      tester,
    ) async {
      await _pumpAt(tester, AppRoutes.radiologistMriUpload(_alexId));

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations, hasLength(3));
      // Nested pages keep Patients highlighted.
      expect(rail.selectedIndex, 1);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('Dashboard'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Radiologist Dashboard'), findsOneWidget);
    });
  });

  group('Responsive layouts', () {
    final pages = {
      'dashboard': AppRoutes.radiologistDashboard,
      'patients': AppRoutes.radiologistPatients,
      'MRI history': AppRoutes.radiologistMriHistory(_alexId),
      'empty MRI history': AppRoutes.radiologistMriHistory(_morganId),
      'MRI upload': AppRoutes.radiologistMriUpload(_alexId),
    };
    const sizes = [Size(1024, 800), Size(390, 844)];

    for (final MapEntry(key: name, value: location) in pages.entries) {
      for (final size in sizes) {
        testWidgets(
          '$name renders at ${size.width.toInt()}px without layout errors',
          (tester) async {
            await _pumpAt(tester, location, size: size);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
