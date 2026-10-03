import 'package:flutter/widgets.dart';

// Screen width categories, like Material 3's size classes:
// compact = phone-sized, medium = tablet-sized, expanded = desktop-sized.
enum ScreenSize { compact, medium, expanded }

abstract final class Breakpoints {
  /// Widths below this are [ScreenSize.compact].
  static const double medium = 600;

  /// Widths at or above this are [ScreenSize.expanded].
  static const double expanded = 840;

  // Picks the right screen size category based on a given width.
  static ScreenSize fromWidth(double width) {
    if (width < medium) return ScreenSize.compact;
    if (width < expanded) return ScreenSize.medium;
    return ScreenSize.expanded;
  }
}

// Lets any widget check its own screen size via `context.screenSize`, etc.
extension ResponsiveContext on BuildContext {
  ScreenSize get screenSize =>
      Breakpoints.fromWidth(MediaQuery.sizeOf(this).width);

  bool get isCompact => screenSize == ScreenSize.compact;
  bool get isMedium => screenSize == ScreenSize.medium;
  bool get isExpanded => screenSize == ScreenSize.expanded;
}
