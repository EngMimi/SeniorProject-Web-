import 'package:flutter/widgets.dart';

/// Window size classes, following Material 3 width breakpoints.
enum ScreenSize { compact, medium, expanded }

abstract final class Breakpoints {
  /// Widths below this are [ScreenSize.compact].
  static const double medium = 600;

  /// Widths at or above this are [ScreenSize.expanded].
  static const double expanded = 840;

  static ScreenSize fromWidth(double width) {
    if (width < medium) return ScreenSize.compact;
    if (width < expanded) return ScreenSize.medium;
    return ScreenSize.expanded;
  }
}

extension ResponsiveContext on BuildContext {
  ScreenSize get screenSize =>
      Breakpoints.fromWidth(MediaQuery.sizeOf(this).width);

  bool get isCompact => screenSize == ScreenSize.compact;
  bool get isMedium => screenSize == ScreenSize.medium;
  bool get isExpanded => screenSize == ScreenSize.expanded;
}
