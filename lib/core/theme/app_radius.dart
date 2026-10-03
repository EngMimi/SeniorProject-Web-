import 'package:flutter/widgets.dart';

// Shared corner-radius values, kept small for a clean, clinical look.
abstract final class AppRadius {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
}
