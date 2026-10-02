import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../features/auth/data/auth_service.dart';
import '../../models/clinical_test.dart';
import '../../models/combined_report.dart';
import '../../models/diagnostic_report.dart';
import '../../models/patient.dart';
import '../clinical_data_repository.dart';

/// Real [ClinicalDataRepository] backed by the same Firebase project as the
/// Patient Mobile Application (`neuroinsight-784ee`).
///
/// Schema (matches what neuroinsight_pd_app's DbHelper already writes):
/// - `users/{uid}`: patient profile. Docs with `role` == 'doctor' or
///   'radiologist' are clinical-staff accounts, not patients. A patient doc
///   may carry `assignedDoctorIds` and/or `assignedRadiologistIds` (each an
///   array of staff UIDs) — a doctor only sees patients whose
///   `assignedDoctorIds` contains their own uid, and a radiologist only
///   sees patients whose `assignedRadiologistIds` contains theirs.
/// - `users/{uid}/tests/{testId}`: one test. Fields: title, date, type
///   ('voice' | 'drawing'), createdAt, status ('uploaded' | 'pending_review'
///   | 'reviewed'), optional `prediction` map (voice only, from the live
///   model) and optional `report` map (written from here).
class FirebaseClinicalDataRepository implements ClinicalDataRepository {
  FirebaseClinicalDataRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _staffRoles = {'doctor', 'radiologist'};

  Patient _patientFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Patient(
      id: doc.id,
      fullName: data['fullName'] as String? ?? '',
      nationalId: data['nationalId'] as String? ?? '',
      dateOfBirth: data['dateOfBirth'] as String? ?? '',
      hospitalFileNo: data['hospitalFileNo'] as String? ?? '',
    );
  }

  TestModality _modalityFromType(String? type) => switch (type) {
        'voice' => TestModality.voice,
        'drawing' => TestModality.spiral,
        'mri' => TestModality.mri,
        _ => TestModality.spiral,
      };

  AnalysisStatus _statusFromString(String? status) => switch (status) {
        'pending_review' => AnalysisStatus.readyForReview,
        'reviewed' => AnalysisStatus.reviewed,
        'uploaded' => AnalysisStatus.pending,
        _ => AnalysisStatus.pending,
      };

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
    );
  }

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

  /// A signed-in doctor or radiologist only ever sees their own assigned
  /// patients. Doctors and radiologists are assigned separately (a patient
  /// can have different people in each role), via `assignedDoctorIds` and
  /// `assignedRadiologistIds` respectively.
  bool get _restrictToAssignedPatients =>
      AuthService.instance.role == StaffRole.doctor ||
      AuthService.instance.role == StaffRole.radiologist;

  String? get _assignmentFieldForCurrentRole => switch (AuthService.instance.role) {
        StaffRole.doctor => 'assignedDoctorIds',
        StaffRole.radiologist => 'assignedRadiologistIds',
        null => null,
      };

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
      // Not this doctor's/radiologist's patient — treat the same as
      // "doesn't exist" so a
      // guessed or stale URL can't be used to view someone else's patient.
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
      // No single patient given (dashboard / patients list): scan every
      // patient's tests. Fine at this project's scale; a collectionGroup
      // query would need a composite index for the equivalent ordering.
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

  /// Finds a test by id without knowing its owning patient up front (the
  /// [ClinicalDataRepository] interface doesn't carry one). Routes in this
  /// app always have the patientId alongside the testId in the URL, so
  /// prefer [getTests] with a patientId when it's available; this is the
  /// fallback the interface requires.
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
      if (doc.exists) {
        final report = _reportFromDoc(patient.id, doc);
        if (report != null) return report;
      }
    }
    return null;
  }

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

    // Also write to the same `reports` collection the combined-report flow
    // uses — that's what the patient mobile app's Reports tab actually
    // reads, so a single-test report written from this (older) form shows
    // up there too, not just in the web app's own per-test view. A
    // deterministic id keyed to the test means saving this form again
    // (draft -> submit, or re-editing) updates the same report doc instead
    // of creating a new one each time.
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

  /// Matches the plain-text date label neuroinsight_pd_app's DbHelper
  /// writes (`DateFormat('MMM d, yyyy')`), since the mobile Reports/Tests
  /// screens read this field directly as a string.
  String _todayLabel() => DateFormat('MMM d, yyyy').format(DateTime.now());

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

  @override
  Future<void> addDrawingTest({
    required String patientId,
    required String title,
    required String fileUrl,
  }) async {
    await _db.collection('users').doc(patientId).collection('tests').add({
      'title': title,
      'date': _todayLabel(),
      'type': 'drawing',
      'createdAt': FieldValue.serverTimestamp(),
      // No drawing model yet, so there's no prediction — this just records
      // the upload until Ruba's model is ready to analyze it.
      'status': 'uploaded',
      'fileUrl': fileUrl,
    });
  }

  @override
  Future<void> addMriTest({
    required String patientId,
    required String title,
    required String fileUrl,
  }) async {
    await _db.collection('users').doc(patientId).collection('tests').add({
      'title': title,
      'date': _todayLabel(),
      'type': 'mri',
      'createdAt': FieldValue.serverTimestamp(),
      // No MRI model yet, so there's no prediction — this just records the
      // upload until Amani's model is ready to analyze it.
      'status': 'uploaded',
      'fileUrl': fileUrl,
    });
  }

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
    // the report covers without reading every test doc again.
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
      // `set` (not `update`) so this also works the first time, when the
      // doc with this id doesn't exist yet — e.g. the deterministic id
      // `submitReport` passes for a single-test report, which may not have
      // been created yet on its first draft save.
      docRef = reportsRef.doc(reportId);
      await docRef.set(payload);
    } else {
      docRef = await reportsRef.add(payload);
    }

    if (submit) {
      // Keep the Test History / dashboard status badges consistent with a
      // combined report having been written for these tests.
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
