import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/data/clinical_data_repository.dart';
import '../../../../shared/data/cloudinary_upload_service.dart';
import '../../../../shared/data/voice_model_service.dart';
import '../../../../shared/models/clinical_test.dart';
import '../../../../shared/models/patient.dart';
import '../../../../shared/widgets/breadcrumbs.dart';
import '../../../../shared/widgets/clinical/status_badge.dart';
import '../../../../shared/widgets/future_content.dart';
import '../../../../shared/widgets/info_field.dart';
import '../../../../shared/widgets/message_state.dart';
import '../../../../shared/widgets/page_container.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/responsive_table.dart';
import '../../../../shared/widgets/section_card.dart';

typedef _ProfileData = (Patient? patient, List<ClinicalTest> tests);

class DoctorPatientProfilePage extends StatefulWidget {
  const DoctorPatientProfilePage({
    super.key,
    required this.patientId,
    required this.repository,
  });

  final String patientId;
  final ClinicalDataRepository repository;

  @override
  State<DoctorPatientProfilePage> createState() =>
      _DoctorPatientProfilePageState();
}

class _DoctorPatientProfilePageState extends State<DoctorPatientProfilePage> {
  /// Bumped after a test is uploaded so [FutureContent] below reloads with
  /// a fresh key instead of showing the list from before the upload.
  int _reloadToken = 0;

  Future<_ProfileData> _load() => (
    widget.repository.getPatient(widget.patientId),
    widget.repository.getTests(patientId: widget.patientId),
  ).wait;

  @override
  Widget build(BuildContext context) {
    return FutureContent<_ProfileData>(
      key: ValueKey('${widget.patientId}/$_reloadToken'),
      load: _load,
      builder: (context, data) {
        final (patient, tests) = data;
        if (patient == null) return const PatientNotFound();

        return PageContainer(
          children: [
            PageHeader(
              breadcrumbs: [
                const BreadcrumbItem(
                  'Patients',
                  location: AppRoutes.doctorPatients,
                ),
                BreadcrumbItem(patient.fullName),
              ],
              title: patient.fullName,
              subtitle: 'Patient ID ${patient.id}',
              actions: [
                _UploadActions(
                  patientId: patient.id,
                  repository: widget.repository,
                  onUploaded: () => setState(() => _reloadToken++),
                ),
                OutlinedButton.icon(
                  onPressed: tests.isEmpty
                      ? null
                      : () => context.go(
                          AppRoutes.doctorCombinedReport(patient.id),
                        ),
                  icon: const Icon(Icons.library_books_outlined, size: 18),
                  label: const Text('Write Combined Report'),
                ),
              ],
            ),
            _PatientSummary(patient: patient, tests: tests),
            _TestHistory(patientId: patient.id, tests: tests),
          ],
        );
      },
    );
  }
}

/// Shown when a patient ID in the URL does not exist.
class PatientNotFound extends StatelessWidget {
  const PatientNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return MessageState(
      icon: Icons.person_search_outlined,
      title: 'Patient not found',
      message: 'This patient does not exist or is not available to you.',
      action: OutlinedButton(
        onPressed: () => context.go(AppRoutes.doctorPatients),
        child: const Text('Back to Patients'),
      ),
    );
  }
}

/// The "Upload Voice Recording" / "Upload Spiral Drawing" header actions.
///
/// Voice: picks a CSV of pre-computed acoustic features, sends it to the
/// live voice model, and saves a real prediction. Drawing: picks an image
/// file, uploads it to Cloudinary, and creates a test pending review (no
/// drawing model exists yet).
class _UploadActions extends StatefulWidget {
  const _UploadActions({
    required this.patientId,
    required this.repository,
    required this.onUploaded,
  });

  final String patientId;
  final ClinicalDataRepository repository;
  final VoidCallback onUploaded;

  @override
  State<_UploadActions> createState() => _UploadActionsState();
}

enum _UploadKind { voice, drawing }

class _UploadActionsState extends State<_UploadActions> {
  // Which upload is in flight, if any — tracked separately from the busy
  // label so the *other* button doesn't borrow this one's status text
  // (e.g. the Drawing button showing "Analyzing voice data...").
  _UploadKind? _active;
  String _busyMessage = 'Uploading...';

  bool get _busy => _active != null;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickVoiceFile() async {
    if (_busy) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _showMessage('Could not read that file. Please try again.');
        return;
      }

      final features = _parseFeaturesFromCsv(String.fromCharCodes(bytes));
      if (features == null) return;

      setState(() {
        _active = _UploadKind.voice;
        _busyMessage = 'Analyzing voice data...';
      });

      final prediction = await VoiceModelService.instance.predict(features);
      await widget.repository.addVoiceTest(
        patientId: widget.patientId,
        title: file.name,
        prediction: prediction.prediction,
        predictionCode: prediction.predictionCode,
        probabilityPd: prediction.probabilityPd,
      );

      if (!mounted) return;
      setState(() => _active = null);
      _showMessage('Voice test uploaded and analyzed.');
      widget.onUploaded();
    } catch (e) {
      if (!mounted) return;
      setState(() => _active = null);
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Parses the first data row of a CSV whose header row contains (at
  /// least) the columns the voice model expects. Returns null and shows an
  /// error if the file doesn't have the required columns.
  Map<String, double>? _parseFeaturesFromCsv(String content) {
    final rows = const CsvToListConverter(eol: '\n').convert(content);
    if (rows.length < 2) {
      _showMessage('That CSV file needs a header row and at least one data row.');
      return null;
    }

    final header = rows.first.map((h) => h.toString().trim()).toList();
    final dataRow = rows[1];

    final missing = <String>[];
    final features = <String, double>{};

    for (final name in voiceModelFeatureNames) {
      final colIndex = header.indexOf(name);
      if (colIndex == -1 || colIndex >= dataRow.length) {
        missing.add(name);
        continue;
      }
      final raw = dataRow[colIndex];
      final value = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
      if (value == null) {
        missing.add(name);
        continue;
      }
      features[name] = value;
    }

    if (missing.isNotEmpty) {
      _showMessage(
        'CSV is missing ${missing.length} required column(s), e.g. '
        '"${missing.first}".',
      );
      return null;
    }

    return features;
  }

  Future<void> _pickDrawingFile() async {
    if (_busy) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _showMessage('Could not read that file. Please try again.');
        return;
      }

      setState(() {
        _active = _UploadKind.drawing;
        _busyMessage = 'Uploading...';
      });

      final url = await CloudinaryUploadService.instance.uploadImage(
        bytes: bytes,
        filename: file.name,
      );
      await widget.repository.addDrawingTest(
        patientId: widget.patientId,
        title: file.name,
        fileUrl: url,
      );

      if (!mounted) return;
      setState(() => _active = null);
      _showMessage(
        'Drawing uploaded. It will be analyzed once the drawing model is '
        'ready.',
      );
      widget.onUploaded();
    } catch (e) {
      if (!mounted) return;
      setState(() => _active = null);
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _pickVoiceFile,
          icon: _active == _UploadKind.voice
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.mic_none_outlined, size: 18),
          label: Text(
            _active == _UploadKind.voice
                ? _busyMessage
                : 'Upload Voice Recording',
          ),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : _pickDrawingFile,
          icon: _active == _UploadKind.drawing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.gesture, size: 18),
          label: Text(
            _active == _UploadKind.drawing
                ? _busyMessage
                : 'Upload Spiral Drawing',
          ),
        ),
      ],
    );
  }
}

class _PatientSummary extends StatelessWidget {
  const _PatientSummary({required this.patient, required this.tests});

  final Patient patient;
  final List<ClinicalTest> tests;

  @override
  Widget build(BuildContext context) {
    final lastTest = tests.firstOrNull;

    return SectionCard(
      title: 'Patient Summary',
      icon: Icons.person_outline,
      child: InfoGrid(
        fields: [
          InfoField(label: 'Patient ID', value: patient.id),
          InfoField(label: 'National ID', value: patient.nationalId),
          InfoField(label: 'Date of birth', value: patient.dateOfBirth),
          InfoField(
            label: 'Hospital file no.',
            value: patient.hospitalFileNo,
          ),
          InfoField(label: 'Total tests', value: '${tests.length}'),
          InfoField(
            label: 'Last test',
            value: lastTest == null ? 'No tests' : formatDate(lastTest.takenOn),
          ),
        ],
      ),
    );
  }
}

class _TestHistory extends StatefulWidget {
  const _TestHistory({required this.patientId, required this.tests});

  final String patientId;
  final List<ClinicalTest> tests;

  @override
  State<_TestHistory> createState() => _TestHistoryState();
}

class _TestHistoryState extends State<_TestHistory> {
  /// `null` shows all modalities.
  TestModality? _filter;

  Widget _resultCell(BuildContext context, ClinicalTest test) =>
      ResultAvailabilityLabel(status: test.status);

  Widget _action(BuildContext context, ClinicalTest test) => TextButton(
    onPressed: () =>
        context.go(AppRoutes.doctorTestAnalysis(widget.patientId, test.id)),
    style: TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: const Text('View Analysis'),
  );

  @override
  Widget build(BuildContext context) {
    final tests = [
      for (final test in widget.tests)
        if (_filter == null || test.modality == _filter) test,
    ];

    return SectionCard(
      title: 'Test History',
      subtitle: 'Voice, spiral drawing and MRI tests, newest first',
      icon: Icons.history,
      padBody: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final option in <TestModality?>[
                  null,
                  ...TestModality.values,
                ])
                  ChoiceChip(
                    label: Text(option?.label ?? 'All'),
                    selected: _filter == option,
                    onSelected: (_) => setState(() => _filter = option),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ResponsiveTable<ClinicalTest>(
            rows: tests,
            emptyMessage: widget.tests.isEmpty
                ? 'No tests have been recorded for this patient yet.'
                : 'No tests for this modality.',
            columns: [
              TableColumnDef(
                label: 'Test modality',
                flex: 2,
                cellBuilder: (_, t) => ModalityLabel(modality: t.modality),
              ),
              TableColumnDef(
                label: 'Date',
                flex: 2,
                cellBuilder: (_, t) => Text(formatDate(t.takenOn)),
              ),
              TableColumnDef(
                label: 'Analysis status',
                flex: 2,
                cellBuilder: (_, t) => AnalysisStatusBadge(status: t.status),
              ),
              TableColumnDef(
                label: 'Result',
                flex: 2,
                cellBuilder: _resultCell,
              ),
              TableColumnDef(
                label: 'Action',
                flex: 2,
                alignEnd: true,
                cellBuilder: _action,
              ),
            ],
            compactRowBuilder: (context, test) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.sm,
              children: [
                Row(
                  children: [
                    Expanded(child: ModalityLabel(modality: test.modality)),
                    AnalysisStatusBadge(status: test.status),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            formatDate(test.takenOn),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          _resultCell(context, test),
                        ],
                      ),
                    ),
                    _action(context, test),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
