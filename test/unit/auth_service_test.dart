import 'package:flutter_test/flutter_test.dart';
import 'package:neuroinsight_pd_web/features/auth/data/auth_service.dart';

void main() {
  group('AuthService debug state', () {
    test('UT-A01: no role creates a signed-out state', () {
      final service = AuthService.debug();

      expect(service.loading, isFalse);
      expect(service.isSignedIn, isFalse);
      expect(service.uid, isNull);
      expect(service.role, isNull);
      expect(service.displayName, isNull);
      expect(service.email, isNull);
    });

    test('UT-A02: doctor role creates a signed-in state', () {
      final service = AuthService.debug(
        role: StaffRole.doctor,
        displayName: 'Dr. Test',
        email: 'doctor@example.com',
        employeeId: 'EMP-100',
      );

      expect(service.isSignedIn, isTrue);
      expect(service.role, StaffRole.doctor);
      expect(service.uid, 'debug-uid');
      expect(service.displayName, 'Dr. Test');
      expect(service.email, 'doctor@example.com');
      expect(service.employeeId, 'EMP-100');
    });

    test('UT-A03: radiologist role creates a signed-in state', () {
      final service = AuthService.debug(role: StaffRole.radiologist);

      expect(service.isSignedIn, isTrue);
      expect(service.role, StaffRole.radiologist);
      expect(service.uid, 'debug-uid');
    });

    test('UT-A04: sign-in is unavailable in debug mode', () async {
      final service = AuthService.debug();

      final result = await service.signIn('EMP-100', 'password');

      expect(result, 'Sign-in is not available in this environment.');
      expect(service.isSignedIn, isFalse);
    });

    test('UT-A05: password reset is unavailable in debug mode', () async {
      final service = AuthService.debug();

      final result = await service.sendPasswordReset('doctor@example.com');

      expect(result, 'Password reset is not available in this environment.');
    });

    test('UT-A06: changing password is unavailable without Firebase', () async {
      final service = AuthService.debug(role: StaffRole.doctor);

      final result = await service.changePassword(
        currentPassword: 'old-password',
        newPassword: 'new-password',
      );

      expect(result, 'Not signed in.');
    });
  });
}
