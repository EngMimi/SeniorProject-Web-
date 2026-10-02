import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroinsight_pd_web/app/app.dart';
import 'package:neuroinsight_pd_web/app/router/app_router.dart';
import 'package:neuroinsight_pd_web/app/router/app_routes.dart';
import 'package:neuroinsight_pd_web/features/auth/data/auth_service.dart';
import 'package:neuroinsight_pd_web/shared/data/mock/mock_clinical_data_repository.dart';
import 'package:neuroinsight_pd_web/shared/widgets/clinical/clinical_notice.dart';

// Fictional IDs from MockClinicalData.
const _alexId = 'PT-DEMO-001';
const _alexVoiceReadyTest = 'TS-DEMO-0001';
const _alexMriReviewedTest = 'TS-DEMO-0003';

Future<void> _pumpAt(
  WidgetTester tester,
  String location, {
  Size size = const Size(1440, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // Fake, already-signed-in doctor account — the real AuthService only
  // runs against Firebase, which these widget tests never touch.
  AuthService.debugSetInstance(AuthService.debug(role: StaffRole.doctor));

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

void main() {
  group('Doctor Dashboard', () {
    testWidgets('renders header, summary cards and recent activity', (
      tester,
    ) async {
      await _pumpAt(tester, AppRoutes.doctorDashboard);

      expect(find.text('Doctor Dashboard'), findsOneWidget);
      for (final label in [
        'Total Patients',
        'Total Voice & Drawing Tests',
        'Awaiting Review',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      // "Reviewed" is also a status-badge label, so several mock tests show
      // it in the activity table below the summary card.
      expect(find.text('Reviewed'), findsWidgets);
      expect(find.text('Recent Test Activity'), findsOneWidget);
      // Table header is shown on wide layouts.
      expect(find.text('Analysis status'), findsOneWidget);
      expect(find.text('Review'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Review action opens the test analysis page', (tester) async {
      await _pumpAt(tester, AppRoutes.doctorDashboard);

      await _tapVisible(tester, find.text('Review').first);

      expect(find.text('AI Analysis Result'), findsOneWidget);
      expect(find.text('Diagnostic Report'), findsOneWidget);
    });

    testWidgets('renders on a narrow window without layout errors', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        AppRoutes.doctorDashboard,
        size: const Size(390, 844),
      );

      expect(find.text('Doctor Dashboard'), findsOneWidget);
      // Compact list replaces the table header.
      expect(find.text('Analysis status'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Patients and profile', () {
    testWidgets('search filters the list and Open Profile navigates', (
      tester,
    ) async {
      await _pumpAt(tester, AppRoutes.doctorPatients);

      expect(find.text('Patient List'), findsOneWidget);
      expect(find.text('Open Profile'), findsNWidgets(6));

      await tester.enterText(find.byType(TextField), 'alex');
      await tester.pumpAndSettle();
      expect(find.text('Open Profile'), findsOneWidget);

      await _tapVisible(tester, find.text('Open Profile'));

      expect(find.text('Patient Summary'), findsOneWidget);
      expect(find.text('Alex Sample'), findsWidgets);
      expect(find.text('Test History'), findsOneWidget);
    });

    testWidgets('profile shows test history and doctor upload actions', (
      tester,
    ) async {
      await _pumpAt(tester, AppRoutes.doctorPatientProfile(_alexId));

      expect(find.text('View Analysis'), findsNWidgets(4));
      expect(find.text('Upload Voice Recording'), findsOneWidget);
      expect(find.text('Upload Spiral Drawing'), findsOneWidget);
      expect(find.textContaining('Upload MRI'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'MRI'));
      await tester.pumpAndSettle();
      expect(find.text('View Analysis'), findsOneWidget);

      await tester.tap(find.text('Upload Voice Recording'));
      await tester.pump();
      expect(find.textContaining('not available'), findsOneWidget);
    });

    testWidgets('patient without tests shows an empty state', (tester) async {
      await _pumpAt(tester, AppRoutes.doctorPatientProfile('PT-DEMO-006'));

      expect(
        find.text('No tests have been recorded for this patient yet.'),
        findsOneWidget,
      );
    });

    testWidgets('unknown patient shows not found', (tester) async {
      await _pumpAt(tester, AppRoutes.doctorPatientProfile('PT-UNKNOWN'));

      expect(find.text('Patient not found'), findsOneWidget);
      await tester.tap(find.text('Back to Patients'));
      await tester.pumpAndSettle();
      expect(find.text('Patient List'), findsOneWidget);
    });
  });

  group('Analysis and diagnostic report', () {
    testWidgets('View Analysis opens the selected test', (tester) async {
      await _pumpAt(tester, AppRoutes.doctorPatientProfile(_alexId));

      await tester.tap(find.widgetWithText(ChoiceChip, 'MRI'));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('View Analysis'));

      expect(find.text('MRI Analysis'), findsOneWidget);
      expect(find.textContaining('Test $_alexMriReviewedTest'), findsOneWidget);
      expect(find.text(aiDecisionSupportNotice), findsOneWidget);
    });

    testWidgets('voice test shows the real model output, not a placeholder', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        AppRoutes.doctorTestAnalysis(_alexId, _alexVoiceReadyTest),
      );

      expect(find.text('Voice Analysis'), findsOneWidget);
      expect(find.text(aiDecisionSupportNotice), findsOneWidget);
      // The voice model is live, so this test's AI card shows a real
      // prediction rather than the "MOCK DATA" placeholder.
      expect(find.text('Voice model output'), findsOneWidget);
      expect(find.text('MOCK DATA'), findsNothing);
    });

    testWidgets('report form renders and validates required fields', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        AppRoutes.doctorTestAnalysis(_alexId, _alexVoiceReadyTest),
      );

      expect(find.text('Report title'), findsOneWidget);
      expect(find.text('Clinical notes / assessment'), findsOneWidget);
      expect(find.text('Recommendations (optional)'), findsOneWidget);
      expect(find.text('Save Draft'), findsOneWidget);

      await _tapVisible(tester, find.text('Submit Diagnostic Report'));
      expect(find.text('Enter a report title.'), findsOneWidget);
      expect(
        find.text('Enter your clinical notes or assessment.'),
        findsOneWidget,
      );
    });

    testWidgets('submitted report is shown read-only', (tester) async {
      await _pumpAt(
        tester,
        AppRoutes.doctorTestAnalysis(_alexId, _alexMriReviewedTest),
      );

      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Submitted on'), findsOneWidget);
      expect(find.text('Submit Diagnostic Report'), findsNothing);
    });

    testWidgets('test belonging to another patient shows not found', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        AppRoutes.doctorTestAnalysis('PT-DEMO-002', _alexVoiceReadyTest),
      );

      expect(find.text('Test not found'), findsOneWidget);
    });

    testWidgets('renders stacked on a tablet-width window', (tester) async {
      await _pumpAt(
        tester,
        AppRoutes.doctorTestAnalysis(_alexId, _alexVoiceReadyTest),
        size: const Size(800, 1000),
      );

      expect(find.text('AI Analysis Result'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Narrow windows', () {
    final pages = {
      'patients': AppRoutes.doctorPatients,
      'profile': AppRoutes.doctorPatientProfile(_alexId),
      'analysis': AppRoutes.doctorTestAnalysis(_alexId, _alexVoiceReadyTest),
    };
    for (final MapEntry(key: name, value: location) in pages.entries) {
      testWidgets('$name page renders at 390px without layout errors', (
        tester,
      ) async {
        await _pumpAt(tester, location, size: const Size(390, 844));
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Doctor navigation', () {
    testWidgets('breadcrumbs and sidebar navigate between pages', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        AppRoutes.doctorTestAnalysis(_alexId, _alexVoiceReadyTest),
      );

      // Breadcrumb back to the patient profile.
      await tester.tap(find.widgetWithText(TextButton, 'Alex Sample'));
      await tester.pumpAndSettle();
      expect(find.text('Patient Summary'), findsOneWidget);

      // Breadcrumb back to the patient list.
      await tester.tap(find.widgetWithText(TextButton, 'Patients'));
      await tester.pumpAndSettle();
      expect(find.text('Patient List'), findsOneWidget);

      // Sidebar back to the dashboard.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('Dashboard'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Doctor Dashboard'), findsOneWidget);
    });

    testWidgets('sidebar highlights Patients on nested pages', (tester) async {
      await _pumpAt(tester, AppRoutes.doctorPatientProfile(_alexId));

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 1);
    });
  });
}
