import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Employee ID/password sign-in form.
///
/// Only validates input; [onSubmit] decides what happens with valid
/// credentials, so real authentication can be plugged in later.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.onSubmit});

  final void Function(String employeeId, String password) onSubmit;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _employeeIdController.text.trim(),
        _passwordController.text,
      );
    } else {
      // Re-validate as the user corrects fields after a failed attempt.
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    }
  }

  String? _validateEmployeeId(String? value) {
    final id = value?.trim() ?? '';
    if (id.isEmpty) return 'Enter your employee ID.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _employeeIdController,
              decoration: const InputDecoration(labelText: 'Employee ID'),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              autocorrect: false,
              validator: _validateEmployeeId,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                  child: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              obscureText: _obscurePassword,
              enableSuggestions: false,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              validator: _validatePassword,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: _submit, child: const Text('Sign In')),
          ],
        ),
      ),
    );
  }
}
