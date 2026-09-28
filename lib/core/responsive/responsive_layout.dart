import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Picks a builder based on the available width.
///
/// [medium] falls back to [compact], and [expanded] falls back to [medium]
/// (then [compact]), so only [compact] is required.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final builder = switch (Breakpoints.fromWidth(constraints.maxWidth)) {
          ScreenSize.compact => compact,
          ScreenSize.medium => medium ?? compact,
          ScreenSize.expanded => expanded ?? medium ?? compact,
        };
        return builder(context);
      },
    );
  }
}
