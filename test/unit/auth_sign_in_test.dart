import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neuroinsight_pd_web/features/auth/data/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirestore extends Mock implements FirebaseFirestore {}

class MockUsersCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockUsersQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockUserDocument extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirebaseAuth auth;
  late MockFirestore firestore;
  late MockUsersCollection users;
  late MockUsersQuery query;
  late MockQuerySnapshot snapshot;
  late MockUserDocument document;
  late AuthService service;

  setUp(() {
    auth = MockFirebaseAuth();
    firestore = MockFirestore();
    users = MockUsersCollection();
    query = MockUsersQuery();
    snapshot = MockQuerySnapshot();
    document = MockUserDocument();

    // Prevents the test from connecting to real Firebase.
    when(() => auth.authStateChanges())
        .thenAnswer((_) => const Stream<User?>.empty());

    when(() => firestore.collection('users')).thenReturn(users);

    when(() => users.where('employeeId', isEqualTo: 'EMP-100'))
        .thenReturn(query);

    when(() => query.limit(1)).thenReturn(query);
    when(() => query.get()).thenAnswer((_) async => snapshot);

    service = AuthService.forTesting(auth: auth, firestore: firestore);
  });

  group('AuthService.signIn', () {
    test('UT-A07: rejects an empty employee ID', () async {
      final result = await service.signIn('   ', 'password');

      expect(result, 'Enter your employee ID.');
      verifyNever(() => firestore.collection('users'));
    });

    test('UT-A08: rejects an unknown employee ID', () async {
      when(() => snapshot.docs).thenReturn([]);

      final result = await service.signIn('EMP-100', 'password');

      expect(result, 'No account found with that employee ID.');
      verifyNever(
        () => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    test('UT-A09: rejects an account with an unsupported role', () async {
      when(() => snapshot.docs).thenReturn([document]);
      when(() => document.data()).thenReturn({
        'employeeId': 'EMP-100',
        'role': 'patient',
        'email': 'patient@example.com',
      });

      final result = await service.signIn('EMP-100', 'password');

      expect(
        result,
        'This account is not registered as a doctor or radiologist.',
      );
      verifyNever(
        () => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    test('UT-A10: handles an incorrect password', () async {
      when(() => snapshot.docs).thenReturn([document]);
      when(() => document.data()).thenReturn({
        'employeeId': 'EMP-100',
        'role': 'doctor',
        'email': 'doctor@example.com',
      });

      when(
        () => auth.signInWithEmailAndPassword(
          email: 'doctor@example.com',
          password: 'wrong-password',
        ),
      ).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      final result = await service.signIn('EMP-100', 'wrong-password');

      expect(result, 'Incorrect employee ID or password.');
    });
  });
}
