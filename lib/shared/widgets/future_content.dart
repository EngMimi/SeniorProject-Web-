import 'package:flutter/material.dart';

import 'message_state.dart';

/// Loads data once via [load] and shows loading/error states around
/// [builder].
///
/// Give it a key derived from its inputs (e.g. a route ID) so it reloads
/// when they change.
class FutureContent<T> extends StatefulWidget {
  const FutureContent({super.key, required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<FutureContent<T>> createState() => _FutureContentState<T>();
}

// Runs the future once, then shows a spinner, an error, or the built content.
class _FutureContentState<T> extends State<FutureContent<T>> {
  late final Future<T> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const MessageState(
            icon: Icons.error_outline,
            title: 'Something went wrong',
            message: 'The data could not be loaded. Please try again.',
          );
        }
        return widget.builder(context, snapshot.data as T);
      },
    );
  }
}
