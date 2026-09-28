import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroinsight_pd_web/app/app.dart';
import 'package:neuroinsight_pd_web/app/router/app_router.dart';
import 'package:neuroinsight_pd_web/app/router/app_routes.dart';

void main() {
  void setWindowSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('Login page', () {
    testWidgets('App starts on the login page', (tester) async {
      await tester.pumpWidget(const NeuroInsightApp());
      await tester.pumpAndSettle();

      expect(find.text('NeuroInsight-PD'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
      expect(find.text('DEVELOPMENT ONLY'), findsOneWidget);
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

      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
    });

    testWidgets('Valid input reports that sign-in is not connected yet', (
      tester,
    ) async {
      await tester.pumpWidget(const NeuroInsightApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test.user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'fictional-password',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Sign-in is not available yet'),
        findsOneWidget,
      );
      expect(find.text('Sign in'), findsOneWidget); // still on login
    });

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

    testWidgets('Development buttons open each role shell', (tester) async {
      await tester.pumpWidget(const NeuroInsightApp());
      await tester.pumpAndSettle();

      final doctorButton = find.text('Continue as Doctor (dev)');
      await tester.ensureVisible(doctorButton);
      await tester.tap(doctorButton);
      await tester.pumpAndSettle();
      expect(find.text('Doctor Dashboard'), findsOneWidget);
    });
  });

  group('Routing', () {
    const routes = {
      AppRoutes.doctorDashboard: 'Doctor Dashboard',
      AppRoutes.doctorPatients: 'Patient List',
      AppRoutes.radiologistDashboard: 'Radiologist Dashboard',
      AppRoutes.radiologistPatients: 'Patient List',
      AppRoutes.doctorRoot: 'Doctor Dashboard',
      AppRoutes.radiologistRoot: 'Radiologist Dashboard',
    };

    for (final MapEntry(key: path, value: title) in routes.entries) {
      testWidgets('Route $path renders "$title"', (tester) async {
        final router = createAppRouter(initialLocation: path);
        addTearDown(router.dispose);

        await tester.pumpWidget(NeuroInsightApp(router: router));
        await tester.pumpAndSettle();

        expect(find.text(title), findsOneWidget);
      });
    }

    testWidgets('Shell navigation switches between role pages', (tester) async {
      final router = createAppRouter(
        initialLocation: AppRoutes.doctorDashboard,
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
