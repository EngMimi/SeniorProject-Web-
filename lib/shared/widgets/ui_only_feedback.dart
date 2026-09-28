import 'package:flutter/material.dart';

/// Tells the user that an action exists in the UI but is not connected yet.
// TODO: Remove usages as each action is connected to the real backend.
void showUiOnlyMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
