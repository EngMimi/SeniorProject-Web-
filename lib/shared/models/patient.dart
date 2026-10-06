/// Minimal patient profile used by the UI.
///
/// Fields match what the Patient Mobile Application actually collects at
/// sign-up (see neuroinsight_pd_app's SignUpStep1Screen / DbHelper) — there
/// is no gender field collected there, so this model doesn't invent one.
class Patient {
  const Patient({
    required this.id,
    required this.fullName,
    this.firstName = '',
    this.lastName = '',
    required this.nationalId,
    required this.dateOfBirth,
    required this.patientFileNo,
  });

  final String id;
  final String fullName;

  /// Saved separately by newer mobile sign-ups. For older accounts the
  /// repository fills these by splitting [fullName].
  final String firstName;
  final String lastName;
  final String nationalId;

  /// As entered at sign-up, e.g. "12 / 05 / 1990". Not a parsed [DateTime]
  /// since the mobile app stores it as free text.
  final String dateOfBirth;
  final String patientFileNo;
}
