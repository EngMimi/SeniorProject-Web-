import 'package:flutter/material.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../shared/widgets/role_shell_scaffold.dart';

/// Structural shell wrapping all Radiologist routes.
class RadiologistShell extends StatelessWidget {
  const RadiologistShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    ShellDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      path: AppRoutes.radiologistDashboard,
    ),
    ShellDestination(
      label: 'Patients',
      icon: Icons.people_outline,
      path: AppRoutes.radiologistPatients,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return RoleShellScaffold(
      title: 'Radiologist',
      destinations: _destinations,
      child: child,
    );
  }
}
