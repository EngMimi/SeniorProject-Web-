enum Gender {
  female('Female'),
  male('Male');

  const Gender(this.label);

  final String label;
}

/// Minimal patient profile used by the UI.
///
/// Fields are UI-driven placeholders and must be aligned with the real
/// backend structure once it is confirmed.
class Patient {
  const Patient({
    required this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.registeredOn,
  });

  final String id;
  final String fullName;
  final int age;
  final Gender gender;
  final DateTime registeredOn;
}
