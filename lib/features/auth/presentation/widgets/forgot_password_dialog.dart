import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../data/auth_service.dart';

/// Opens the "Forgot password" dialog: the user enters their email and
/// Firebase sends a password-reset link to it (same as the mobile app).
Future<void> showForgotPasswordDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _ForgotPasswordDialog(),
  );
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog();

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  String? _errorText;
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _isValidEmail => RegExp(
    r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
  ).hasMatch(_emailController.text.trim());

  // Checks the email, asks Firebase to send the reset link, and switches
  // the dialog to its "Email sent" view on success.
  Future<void> _send() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorText = 'Please enter your email address.');
      return;
    }
    if (!_isValidEmail) {
      setState(() => _errorText = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _errorText = null;
      _loading = true;
    });
    final error = await AuthService.instance.sendPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _errorText = error;
      _sent = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_sent ? 'Email sent' : 'Reset your password'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: _sent
            ? Text(
                'A password reset link has been sent to '
                '${_emailController.text.trim()}. Open it to set a new '
                'password, then sign in again.',
                style: theme.textTheme.bodyMedium,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter the email address linked to your account and '
                    'we’ll send you a link to reset your password.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    onChanged: (_) => setState(() => _errorText = null),
                    onSubmitted: (_) => _loading ? null : _send(),
                    decoration: InputDecoration(
                      labelText: 'Email address',
                      errorText: _errorText,
                    ),
                  ),
                ],
              ),
      ),
      actions: _sent
          ? [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Sign In'),
              ),
            ]
          : [
              TextButton(
                onPressed: _loading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: _loading ? null : _send,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Reset Link'),
              ),
            ],
    );
  }
}
