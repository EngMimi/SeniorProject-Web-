// Settings page: shows the signed-in account's info, a change-password
// form, and a sign-out button.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/info_field.dart';
import '../../../../shared/widgets/page_container.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../data/auth_service.dart';

/// Account settings shared by the Doctor and Radiologist portals: the
/// signed-in account's details, a change-password form, and sign out.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;

    return PageContainer(
      children: [
        const PageHeader(
          title: 'Settings',
          subtitle: 'Your account details and sign-in.',
        ),
        SectionCard(
          title: 'Account',
          icon: Icons.badge_outlined,
          child: InfoGrid(
            fields: [
              InfoField(label: 'Full name', value: auth.displayName ?? '—'),
              InfoField(label: 'Email', value: auth.email ?? '—'),
              InfoField(label: 'Employee ID', value: auth.employeeId ?? '—'),
              InfoField(
                label: 'National ID',
                value: (auth.nationalId == null || auth.nationalId!.isEmpty)
                    ? '—'
                    : auth.nationalId!,
              ),
              InfoField(
                label: 'Phone number',
                value: (auth.phoneNumber == null || auth.phoneNumber!.isEmpty)
                    ? '—'
                    : auth.phoneNumber!,
              ),
            ],
          ),
        ),
        const _ChangePasswordCard(),
        const _SignOutCard(),
      ],
    );
  }
}

class _ChangePasswordCard extends StatefulWidget {
  const _ChangePasswordCard();

  @override
  State<_ChangePasswordCard> createState() => _ChangePasswordCardState();
}

/// Form for changing the account password, with validation and a loading
/// state while the request is in flight.
class _ChangePasswordCardState extends State<_ChangePasswordCard> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Validates the form, then calls AuthService to change the password.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() => _saving = true);
    final error = await AuthService.instance.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    _currentController.clear();
    _newController.clear();
    _confirmController.clear();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Password changed.')));
  }

  String? _requiredField(String? value, String message) =>
      (value == null || value.isEmpty) ? message : null;

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a new password.';
    if (value.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _newController.text) return 'Passwords do not match.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Change Password',
      icon: Icons.lock_outline,
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            TextFormField(
              controller: _currentController,
              decoration: const InputDecoration(labelText: 'Current password'),
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: (v) => _requiredField(v, 'Enter your current password.'),
            ),
            TextFormField(
              controller: _newController,
              decoration: const InputDecoration(labelText: 'New password'),
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: _validateNewPassword,
            ),
            TextFormField(
              controller: _confirmController,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _saving ? null : _submit(),
              validator: _validateConfirm,
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Change Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignOutCard extends StatefulWidget {
  const _SignOutCard();

  @override
  State<_SignOutCard> createState() => _SignOutCardState();
}

class _SignOutCardState extends State<_SignOutCard> {
  bool _signingOut = false;

  // Signs out, then navigates to login as a fallback in case the router's
  // own redirect (listening to AuthService) doesn't fire right away —
  // otherwise the button could look like it did nothing.
  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await AuthService.instance.signOut();
      if (mounted) context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      setState(() => _signingOut = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Could not sign out: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Sign Out',
      icon: Icons.logout,
      child: Row(
        children: [
          const Expanded(
            child: Text('Sign out of this account on this device.'),
          ),
          const SizedBox(width: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _signingOut ? null : _signOut,
            icon: _signingOut
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout, size: 18, color: AppColors.error),
            label: Text(
              _signingOut ? 'Signing out...' : 'Sign Out',
              style: const TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
