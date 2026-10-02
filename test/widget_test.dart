import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroinsight_pd_web/app/app.dart';
import 'package:neuroinsight_pd_web/app/router/app_router.dart';
import 'package:neuroinsight_pd_web/app/router/app_routes.dart';
import 'package:neuroinsight_pd_web/features/auth/data/auth_service.dart';
import 'package:neuroinsight_pd_web/shared/data/mock/mock_clinical_data_repository.dart';

void main() {
  void setWindowSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  setUp(() {
    // Every test runs against a fake AuthService so none of them touch
    // real Firebase. Signed out by default; tests that need to land past
    // the sign-in guard override this with a role before pumping.
    AuthService.debugSetInstance(AuthService.debug());
  });

  group('Login page', () {
    testWidgets('App starts on the login page', (tester) async {
      await tester.pumpWidget(const NeuroInsightApp());
      await tester.pumpAndSettle();

      expect(find.text('NeuroInsight-PD'), findsOneWidget);
      expect(find.text('Employee ID'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
    });

    testWidgets('Wide layout shows the brand panel with portal audience', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1440, 900));
      await tester.pumpWidget(const NeuroInsightApp());
      await tester.pumpAndSettle();

      expect(find.text('NeuroInsight-PD'), findsOneWidget);
      expect(find.text('Doctors'), findsOneWidget);
      expect(find.text('Radiologists'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Narrow layout renders without the brand panel', (
      tester,
    ) async {
      setWindowSize(tester, const Size(390, 844));
      await tester.pumpWidget(const NeuroInsightApp());
      await tester.pumpAndSettle();

      expect(find.text('NeuroInsight-PD'), findsOneWidget);
      expect(find.text('Radiologists'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Submitting empty form shows validation errors', (
      tester,
    ) async {
      await tester.pumpWidget(const NeuroInsightApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your employee ID.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
    });

    testWidgets(
      'Valid input against the fake AuthService reports a graceful error',
      (tester) async {
        await tester.pumpWidget(const NeuroInsightApp());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Employee ID'),
          'EMP-1024',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'fictional-password',
        );
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('not available in this environment'),
          findsOneWidget,
        );
        expect(find.text('Sign in'), findsOneWidget); // still on login
      },
    );

    testWidgets('Password visibility can be toggled', (tester) async {
      await tester.pumpWidget(const NeuroInsightApp());
      await tester.pumpAndSettle();

      EditableText passwordField() => tester.widget<EditableText>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Password'),
          matching: find.byType(EditableText),
        ),
      );

      expect(passwordField().obscureText, isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(passwordField().obscureText, isFalse);
      expect(find.byTooltip('Hide password'), findsOneWidget);
    });
  });

  group('Routing', () {
    const doctorRoutes = {
      AppRoutes.doctorDashboard: 'Doctor Dashboard',
      AppRoutes.doctorPatients: 'Patient List',
      AppRoutes.doctorRoot: 'Doctor Dashboard',
    };
    const radiologistRoutes = {
      AppRoutes.radiologistDashboard: 'Radiologist Dashboard',
      AppRoutes.radiologistPatients: 'Patient List',
      AppRoutes.radiologistRoot: 'Radiologist Dashboard',
    };

    for (final MapEntry(key: path, value: title) in doctorRoutes.entries) {
      testWidgets('Route $path renders "$title" for a signed-in doctor', (
        tester,
      ) async {
        AuthService.debugSetInstance(
          AuthService.debug(role: StaffRole.doctor),
        );
        final router = createAppRouter(
          initialLocation: path,
          repository: const MockClinicalDataRepository(),
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(NeuroInsightApp(router: router));
        await tester.pumpAndSettle();

        expect(find.text(title), findsOneWidget);
      });
    }

    for (final MapEntry(key: path, value: title)
        in radiologistRoutes.entries) {
      testWidgets('Route $path renders "$title" for a signed-in radiologist', (
        tester,
      ) async {
        AuthService.debugSetInstance(
          AuthService.debug(role: StaffRole.radiologist),
        );
        final router = createAppRouter(
          initialLocation: path,
          repository: const MockClinicalDataRepository(),
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(NeuroInsightApp(router: router));
        await tester.pumpAndSettle();

        expect(find.text(title), findsOneWidget);
      });
    }

    testWidgets('A signed-out visitor is redirected to the login page', (
      tester,
    ) async {
      final router = createAppRouter(
        initialLocation: AppRoutes.doctorDashboard,
        repository: const MockClinicalDataRepository(),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(NeuroInsightApp(router: router));
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('A radiologist cannot open doctor routes', (tester) async {
      AuthService.debugSetInstance(
        AuthService.debug(role: StaffRole.radiologist),
      );
      final router = createAppRouter(
        initialLocation: AppRoutes.doctorDashboard,
        repository: const MockClinicalDataRepository(),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(NeuroInsightApp(router: router));
      await tester.pumpAndSettle();

      expect(find.text('Radiologist Dashboard'), findsOneWidget);
    });

    testWidgets('Shell navigation switches between role pages', (tester) async {
      AuthService.debugSetInstance(AuthService.debug(role: StaffRole.doctor));
      final router = createAppRouter(
        initialLocation: AppRoutes.doctorDashboard,
        repository: const MockClinicalDataRepository(),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(NeuroInsightApp(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();
      expect(find.text('Patient List'), findsOneWidget);
    });
  });
}
