import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

// A widget that picks which layout to build (compact/medium/expanded)
// based on how much width is available. Only `compact` is required;
// `medium` and `expanded` fall back to the smaller ones if not given.
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
    // LayoutBuilder gives us the actual available width so we can
    // choose the matching builder below.
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
