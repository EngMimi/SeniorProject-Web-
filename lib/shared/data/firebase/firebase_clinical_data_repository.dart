import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../features/auth/data/auth_service.dart';
import '../../models/clinical_test.dart';
import '../../models/combined_report.dart';
import '../../models/diagnostic_report.dart';
import '../../models/patient.dart';
import '../clinical_data_repository.dart';

// The real implementation of ClinicalDataRepository: reads and writes
// patients, tests and reports in the shared Firestore database.

/// Reads and writes patient/test/report data from the same Firebase
/// project as the Patient Mobile Application (`neuroinsight-784ee`).
///
/// Firestore layout:
/// - `users/{uid}`: a patient profile, unless `role` is 'doctor' or
///   'radiologist' (then it's a staff account, not a patient). A patient
///   doc can list `assignedDoctorIds` / `assignedRadiologistIds` — staff
///   only see patients assigned to them.
/// - `users/{uid}/tests/{testId}`: one test, with its type, status,
///   optional AI `prediction`, and optional `report` (written here).
class FirebaseClinicalDataRepository implements ClinicalDataRepository {
  FirebaseClinicalDataRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _staffRoles = {'doctor', 'radiologist'};

  /// Converts a Firestore `users` doc into a [Patient].
  Patient _patientFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final fullName = data['fullName'] as String? ?? '';
    final nameParts = fullName.trim().split(RegExp(r'\s+'));
    return Patient(
      id: doc.id,
      fullName: fullName,
      // Older accounts have no firstName/lastName, so split fullName.
      firstName: data['firstName'] as String? ?? nameParts.first,
      lastName: data['lastName'] as String? ?? nameParts.skip(1).join(' '),
      nationalId: data['nationalId'] as String? ?? '',
      dateOfBirth: data['dateOfBirth'] as String? ?? '',
      patientFileNo: data['patientFileNo'] as String? ?? '',
    );
  }

  /// Maps Firestore's `type` string to our [TestModality] enum.
  TestModality _modalityFromType(String? type) => switch (type) {
        'voice' => TestModality.voice,
        'drawing' => TestModality.spiral,
        'mri' => TestModality.mri,
        _ => TestModality.spiral,
      };

  /// Maps Firestore's `status` string to our [AnalysisStatus] enum.
  AnalysisStatus _statusFromString(String? status) => switch (status) {
        'pending_review' => AnalysisStatus.readyForReview,
        'reviewed' => AnalysisStatus.reviewed,
        'uploaded' => AnalysisStatus.pending,
        _ => AnalysisStatus.pending,
      };

  /// Converts a Firestore `tests` doc into a [ClinicalTest].
  ClinicalTest _testFromDoc(
    String patientId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final createdAt = data['createdAt'];
    final takenOn = createdAt is Timestamp ? createdAt.toDate() : DateTime.now();
    final prediction = data['prediction'] as Map<String, dynamic>?;
    final status = _statusFromString(data['status'] as String?);

    return ClinicalTest(
      id: doc.id,
      patientId: patientId,
      modality: _modalityFromType(data['type'] as String?),
      takenOn: takenOn,
      status: status,
      analysisCompletedOn: prediction != null ? takenOn : null,
      aiPrediction: prediction?['prediction'] as String?,
      aiPredictionCode: prediction?['predictionCode'] as int?,
      aiProbabilityPd: (prediction?['probabilityPd'] as num?)?.toDouble(),
      fileUrl: data['fileUrl'] as String?,
    );
  }

  /// Builds a [DiagnosticReport] from a test doc's `report` field, if it
  /// has one.
  DiagnosticReport? _reportFromDoc(
    String patientId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final report = data['report'] as Map<String, dynamic>?;
    if (report == null) return null;

    final writtenAt = report['writtenAt'];
    return DiagnosticReport(
      id: doc.id,
      patientId: patientId,
      testId: doc.id,
      title: report['title'] as String? ?? data['title'] as String? ?? 'Report',
      clinicalNotes: report['clinicalNotes'] as String? ?? '',
      recommendations: report['recommendations'] as String? ?? '',
      status: report['status'] == 'submitted'
          ? ReportStatus.submitted
          : ReportStatus.draft,
      updatedOn: writtenAt is Timestamp ? writtenAt.toDate() : DateTime.now(),
    );
  }

  /// True if the signed-in user is a doctor or radiologist, who should
  /// only see their own assigned patients (not every patient).
  bool get _restrictToAssignedPatients =>
      AuthService.instance.role == StaffRole.doctor ||
      AuthService.instance.role == StaffRole.radiologist;

  /// Which Firestore field lists patients assigned to the current role.
  String? get _assignmentFieldForCurrentRole => switch (AuthService.instance.role) {
        StaffRole.doctor => 'assignedDoctorIds',
        StaffRole.radiologist => 'assignedRadiologistIds',
        null => null,
      };

  /// True if this patient is assigned to the currently signed-in staff
  /// member.
  bool _isAssignedToCurrentUser(Map<String, dynamic> data) {
    final userId = AuthService.instance.uid;
    final field = _assignmentFieldForCurrentRole;
    if (userId == null || field == null) return false;
    final assigned = data[field];
    return assigned is List && assigned.contains(userId);
  }

  @override
  Future<List<Patient>> getPatients() async {
    final snapshot = await _db.collection('users').get();
    return [
      for (final doc in snapshot.docs)
        if (!_staffRoles.contains(doc.data()['role'] as String?) &&
            (!_restrictToAssignedPatients ||
                _isAssignedToCurrentUser(doc.data())))
          _patientFromDoc(doc),
    ];
  }

  @override
  Future<Patient?> getPatient(String patientId) async {
    final doc = await _db.collection('users').doc(patientId).get();
    if (!doc.exists) return null;
    final data = doc.data() ?? const {};
    if (_staffRoles.contains(data['role'] as String?)) return null;
    if (_restrictToAssignedPatients && !_isAssignedToCurrentUser(data)) {
      // Not this staff member's patient — treat it as "doesn't exist" so
      // a guessed URL can't be used to view someone else's patient.
      return null;
    }
    return _patientFromDoc(doc);
  }

  @override
  Future<List<ClinicalTest>> getTests({
    String? patientId,
    TestModality? modality,
  }) async {
    final tests = <ClinicalTest>[];

    if (patientId != null) {
      final snapshot = await _db
          .collection('users')
          .doc(patientId)
          .collection('tests')
          .orderBy('createdAt', descending: true)
          .get();
      tests.addAll(snapshot.docs.map((d) => _testFromDoc(patientId, d)));
    } else {
      // No single patient given: scan every patient's tests instead.
      // Fine at this project's small scale.
      final patients = await getPatients();
      for (final patient in patients) {
        final snapshot = await _db
            .collection('users')
            .doc(patient.id)
            .collection('tests')
            .orderBy('createdAt', descending: true)
            .get();
        tests.addAll(snapshot.docs.map((d) => _testFromDoc(patient.id, d)));
      }
      tests.sort((a, b) => b.takenOn.compareTo(a.takenOn));
    }

    return modality == null
        ? tests
        : [for (final t in tests) if (t.modality == modality) t];
  }

  /// Finds a test by id by checking every patient, since the interface
  /// doesn't pass in which patient owns it. Prefer [getTests] with a
  /// patientId when you have one; this is just the fallback.
  @override
  Future<ClinicalTest?> getTest(String testId) async {
    final patients = await getPatients();
    for (final patient in patients) {
      final doc = await _db
          .collection('users')
          .doc(patient.id)
          .collection('tests')
          .doc(testId)
          .get();
      if (doc.exists) return _testFromDoc(patient.id, doc);
    }
    return null;
  }

  @override
  Future<List<DiagnosticReport>> getReports() async {
    final patients = await getPatients();
    final reports = <DiagnosticReport>[];
    for (final patient in patients) {
      final snapshot = await _db
          .collection('users')
          .doc(patient.id)
          .collection('tests')
          .get();
      for (final doc in snapshot.docs) {
        final report = _reportFromDoc(patient.id, doc);
        if (report != null) reports.add(report);
      }
    }
    reports.sort((a, b) => b.updatedOn.compareTo(a.updatedOn));
    return reports;
  }

  @override
  Future<DiagnosticReport?> getReportForTest(String testId) async {
    final patients = await getPatients();
    for (final patient in patients) {
      final doc = await _db
          .collection('users')
          .doc(patient.id)
          .collection('tests')
          .doc(testId)
          .get();
      if (!doc.exists) continue;

      // This test belongs to this patient — it's the only place we need
      // to look further, so every path below returns (or falls through to
      // the final `return null`) rather than continuing the patient loop.
      final embedded = _reportFromDoc(patient.id, doc);
      if (embedded != null) return embedded;

      // No report embedded directly on the test doc. The test may still
      // be covered by a combined (multi-test) report saved only in the
      // patient's `reports` subcollection — submitCombinedReport() marks
      // the test's status as 'reviewed' but never writes back onto the
      // test doc itself, so that's the other place a report can live.
      // Filtered by `testIds` only (not also `status`) so this doesn't
      // need a composite Firestore index — the `submitted` check is done
      // in Dart just below instead.
      final reportsSnapshot = await _db
          .collection('users')
          .doc(patient.id)
          .collection('reports')
          .where('testIds', arrayContains: testId)
          .get();
      for (final reportDoc in reportsSnapshot.docs) {
        if (reportDoc.data()['status'] == 'submitted') {
          return _reportFromReportsDoc(patient.id, testId, reportDoc);
        }
      }

      return null;
    }
    return null;
  }

  /// Builds a [DiagnosticReport] from a doc in the `reports` subcollection
  /// (a combined report covering one or more tests), for a specific
  /// [testId] it covers.
  DiagnosticReport _reportFromReportsDoc(
    String patientId,
    String testId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final writtenAt = data['writtenAt'];
    return DiagnosticReport(
      id: doc.id,
      patientId: patientId,
      testId: testId,
      title: data['title'] as String? ?? 'Report',
      clinicalNotes: data['clinicalNotes'] as String? ?? '',
      recommendations: data['recommendations'] as String? ?? '',
      status: data['status'] == 'submitted'
          ? ReportStatus.submitted
          : ReportStatus.draft,
      updatedOn: writtenAt is Timestamp ? writtenAt.toDate() : DateTime.now(),
    );
  }

  /// Saves the doctor's report onto the test doc, and also mirrors it
  /// into the `reports` collection so the patient app's Reports tab sees it.
  @override
  Future<void> submitReport({
    required String patientId,
    required String testId,
    required String doctorName,
    required String title,
    required String clinicalNotes,
    required String recommendations,
    required bool submit,
  }) async {
    final testRef = _db
        .collection('users')
        .doc(patientId)
        .collection('tests')
        .doc(testId);

    await testRef.update({
      'report': {
        'title': title,
        'doctorName': doctorName,
        'clinicalNotes': clinicalNotes,
        'recommendations': recommendations,
        'status': submit ? 'submitted' : 'draft',
        'writtenAt': FieldValue.serverTimestamp(),
      },
      if (submit) 'status': 'reviewed',
      if (submit) 'reportViewed': false,
    });

    // Mirror into `reports` too, using an id keyed to the test so saving
    // this form again updates the same doc instead of duplicating it.
    await submitCombinedReport(
      reportId: 'legacy_$testId',
      patientId: patientId,
      testIds: [testId],
      doctorName: doctorName,
      title: title,
      clinicalNotes: clinicalNotes,
      recommendations: recommendations,
      submit: submit,
    );
  }

  /// Today's date as plain text, in the same format the mobile app uses,
  /// since the Reports/Tests screens display this field as a string.
  String _todayLabel() => DateFormat('MMM d, yyyy').format(DateTime.now());

  /// Saves a new voice test with its AI prediction already attached.
  @override
  Future<void> addVoiceTest({
    required String patientId,
    required String title,
    required String prediction,
    required int predictionCode,
    required double probabilityPd,
  }) async {
    await _db.collection('users').doc(patientId).collection('tests').add({
      'title': title,
      'date': _todayLabel(),
      'type': 'voice',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending_review',
      'prediction': {
        'prediction': prediction,
        'predictionCode': predictionCode,
        'probabilityPd': probabilityPd,
      },
    });
  }

  /// Saves a new spiral-drawing test with its AI prediction and uploaded
  /// image URL.
  @override
  Future<void> addDrawingTest({
    required String patientId,
    required String title,
    required String fileUrl,
    required String prediction,
    required int predictionCode,
    required double probabilityPd,
  }) async {
    await _db.collection('users').doc(patientId).collection('tests').add({
      'title': title,
      'date': _todayLabel(),
      'type': 'drawing',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending_review',
      'fileUrl': fileUrl,
      'prediction': {
        'prediction': prediction,
        'predictionCode': predictionCode,
        'probabilityPd': probabilityPd,
      },
    });
  }

  /// Saves a new MRI scan test with its AI prediction and uploaded image
  /// URL.
  @override
  Future<void> addMriTest({
    required String patientId,
    required String title,
    required String fileUrl,
    required String prediction,
    required int predictionCode,
    required double probabilityPd,
  }) async {
    await _db.collection('users').doc(patientId).collection('tests').add({
      'title': title,
      'date': _todayLabel(),
      'type': 'mri',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending_review',
      'fileUrl': fileUrl,
      'prediction': {
        'prediction': prediction,
        'predictionCode': predictionCode,
        'probabilityPd': probabilityPd,
      },
    });
  }

  /// Converts a Firestore `reports` doc into a [CombinedReport].
  CombinedReport _combinedReportFromDoc(
    String patientId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final writtenAt = data['writtenAt'];
    return CombinedReport(
      id: doc.id,
      patientId: patientId,
      testIds: List<String>.from(data['testIds'] as List? ?? const []),
      testTypeLabels: List<String>.from(
        data['testTypeLabels'] as List? ?? const [],
      ),
      title: data['title'] as String? ?? '',
      clinicalNotes: data['clinicalNotes'] as String? ?? '',
      recommendations: data['recommendations'] as String? ?? '',
      status: data['status'] == 'submitted'
          ? ReportStatus.submitted
          : ReportStatus.draft,
      updatedOn: writtenAt is Timestamp ? writtenAt.toDate() : DateTime.now(),
    );
  }

  @override
  Future<List<CombinedReport>> getCombinedReports({
    required String patientId,
  }) async {
    final snapshot = await _db
        .collection('users')
        .doc(patientId)
        .collection('reports')
        .orderBy('writtenAt', descending: true)
        .get();
    return [
      for (final doc in snapshot.docs)
        _combinedReportFromDoc(patientId, doc),
    ];
  }

  /// Creates or updates a report covering multiple tests at once, and
  /// marks those tests as reviewed when submitted.
  @override
  Future<String> submitCombinedReport({
    String? reportId,
    required String patientId,
    required List<String> testIds,
    required String doctorName,
    required String title,
    required String clinicalNotes,
    required String recommendations,
    required bool submit,
  }) async {
    final reportsRef = _db
        .collection('users')
        .doc(patientId)
        .collection('reports');

    // Look up each test's modality label so the patient app can show what
    // the report covers without re-reading the test docs itself.
    final testTypeLabels = <String>[];
    for (final testId in testIds) {
      final testDoc = await _db
          .collection('users')
          .doc(patientId)
          .collection('tests')
          .doc(testId)
          .get();
      testTypeLabels.add(
        _modalityFromType(testDoc.data()?['type'] as String?).label,
      );
    }

    final payload = {
      'title': title,
      'doctorName': doctorName,
      'clinicalNotes': clinicalNotes,
      'recommendations': recommendations,
      'testIds': testIds,
      'testTypeLabels': testTypeLabels,
      'status': submit ? 'submitted' : 'draft',
      'writtenAt': FieldValue.serverTimestamp(),
      if (submit) 'reportViewed': false,
    };

    final DocumentReference<Map<String, dynamic>> docRef;
    if (reportId != null) {
      // `set`, not `update`, so this also works the first time the doc
      // with this id is created.
      docRef = reportsRef.doc(reportId);
      await docRef.set(payload);
    } else {
      docRef = await reportsRef.add(payload);
    }

    if (submit) {
      // Mark each covered test as reviewed so dashboards/status badges
      // stay consistent with the report having been written.
      for (final testId in testIds) {
        await _db
            .collection('users')
            .doc(patientId)
            .collection('tests')
            .doc(testId)
            .update({'status': 'reviewed'});
      }
    }

    return docRef.id;
  }
}
