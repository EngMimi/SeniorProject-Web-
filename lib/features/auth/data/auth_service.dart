// Handles sign-in, sign-out, and password changes for the web portal, and
// keeps track of who is currently signed in and their role.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum StaffRole { doctor, radiologist }

/// Tracks who is signed in and their role, read from the same Firestore
/// `users/{uid}` doc the mobile app writes. Only 'doctor' or 'radiologist'
/// accounts are let into this portal.
///
/// Sign-in uses Employee ID instead of email: we look up the account's
/// email by its `employeeId` field, then sign in with that email.
class AuthService extends ChangeNotifier {
  AuthService._({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _loading = true,
        _uid = null,
        _displayName = null,
        _email = null,
        _employeeId = null,
        _nationalId = null,
        _phoneNumber = null,
        _role = null {
    _auth!.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Test-only constructor that skips Firebase entirely and just sets the
  /// state directly (signed out if [role] is null). See [debugSetInstance].
  @visibleForTesting
  AuthService.debug({
    StaffRole? role,
    String displayName = 'Dr. Test',
    String email = 'dr.test@example.com',
    String employeeId = 'EMP-0000',
    String nationalId = '',
    String phoneNumber = '',
  })  : _auth = null,
        _db = null,
        _loading = false,
        _uid = role == null ? null : 'debug-uid',
        _displayName = role == null ? null : displayName,
        _email = role == null ? null : email,
        _employeeId = role == null ? null : employeeId,
        _nationalId = role == null ? null : nationalId,
        _phoneNumber = role == null ? null : phoneNumber,
        _role = role;

  /// The single instance the whole app reads from. Tests can swap it out
  /// with [debugSetInstance] so they never touch real Firebase.
  static AuthService instance = AuthService._();

  @visibleForTesting
  static void debugSetInstance(AuthService service) => instance = service;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _db;

  bool _loading;
  String? _uid;
  String? _displayName;
  String? _email;
  String? _employeeId;
  String? _nationalId;
  String? _phoneNumber;
  StaffRole? _role;

  bool get loading => _loading;
  bool get isSignedIn => _uid != null && _role != null;
  String? get uid => _uid;
  String? get displayName => _displayName;
  String? get email => _email;
  String? get employeeId => _employeeId;
  String? get nationalId => _nationalId;
  String? get phoneNumber => _phoneNumber;
  StaffRole? get role => _role;

  // Runs whenever Firebase's sign-in state changes. Pulls the user's
  // profile (name, role, etc.) from Firestore and updates our state.
  Future<void> _onAuthStateChanged(User? user) async {
    final db = _db;
    if (user == null || db == null) {
      _uid = null;
      _displayName = null;
      _email = null;
      _employeeId = null;
      _nationalId = null;
      _phoneNumber = null;
      _role = null;
      _loading = false;
      notifyListeners();
      return;
    }

    final doc = await db.collection('users').doc(user.uid).get();
    final data = doc.data();
    final roleString = data?['role'] as String?;

    _uid = user.uid;
    _displayName = data?['fullName'] as String? ?? user.email ?? 'User';
    _email = data?['email'] as String? ?? user.email;
    _employeeId = data?['employeeId'] as String?;
    _nationalId = data?['nationalId'] as String?;
    _phoneNumber = data?['phoneNumber'] as String?;
    _role = switch (roleString) {
      'doctor' => StaffRole.doctor,
      'radiologist' => StaffRole.radiologist,
      _ => null, // Patient accounts (or missing role) can't use this portal.
    };
    _loading = false;
    notifyListeners();
  }

  /// Signs in with an employee ID and password. Returns null on success,
  /// or a short message to show the user on failure.
  Future<String?> signIn(String employeeId, String password) async {
    final auth = _auth;
    final db = _db;
    if (auth == null || db == null) {
      // This only happens with a debug AuthService in widget tests.
      return 'Sign-in is not available in this environment.';
    }

    final id = employeeId.trim();
    if (id.isEmpty) return 'Enter your employee ID.';

    try {
      final query = await db
          .collection('users')
          .where('employeeId', isEqualTo: id)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        return 'No account found with that employee ID.';
      }

      final data = query.docs.first.data();
      final roleString = data['role'] as String?;
      if (roleString != 'doctor' && roleString != 'radiologist') {
        return 'This account is not registered as a doctor or radiologist.';
      }
      final accountEmail = data['email'] as String?;
      if (accountEmail == null || accountEmail.isEmpty) {
        return 'This account is missing an email and can\'t sign in yet. '
            'Contact an admin.';
      }

      await auth.signInWithEmailAndPassword(
        email: accountEmail,
        password: password,
      );

      // Set the state now from the profile we just looked up, instead of
      // waiting for the authStateChanges listener above (which can lag and
      // briefly show the wrong role). The listener fires soon after too,
      // but just re-applies the same data, so that's harmless.
      _uid = auth.currentUser?.uid;
      _displayName = data['fullName'] as String? ?? accountEmail;
      _email = accountEmail;
      _employeeId = data['employeeId'] as String?;
      _nationalId = data['nationalId'] as String?;
      _phoneNumber = data['phoneNumber'] as String?;
      _role = roleString == 'doctor' ? StaffRole.doctor : StaffRole.radiologist;
      _loading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'Incorrect employee ID or password.',
        'user-disabled' => 'This account has been disabled.',
        _ => 'Could not sign in. Please try again.',
      };
    }
  }

  /// Changes the signed-in user's password. Firebase requires re-entering
  /// the current password first to confirm it's really them.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final auth = _auth;
    final user = auth?.currentUser;
    final email = _email;
    if (auth == null || user == null || email == null) {
      return 'Not signed in.';
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'wrong-password' || 'invalid-credential' =>
          'Current password is incorrect.',
        'weak-password' => 'New password is too weak.',
        _ => 'Could not change the password. Please try again.',
      };
    }
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    final auth = _auth;
    if (auth == null) return;
    await auth.signOut();
    // Clear our state right away instead of waiting for the listener above
    // — otherwise the post-sign-out redirect could run while we still look
    // signed in, and send people back to the dashboard instead of login.
    _uid = null;
    _displayName = null;
    _email = null;
    _employeeId = null;
    _nationalId = null;
    _phoneNumber = null;
    _role = null;
    _loading = false;
    notifyListeners();
  }
}
