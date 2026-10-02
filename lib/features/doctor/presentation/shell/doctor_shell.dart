import 'package:flutter/material.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../shared/widgets/role_shell_scaffold.dart';

/// Structural shell wrapping all Doctor routes.
class DoctorShell extends StatelessWidget {
  const DoctorShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    ShellDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      path: AppRoutes.doctorDashboard,
    ),
    ShellDestination(
      label: 'Patients',
      icon: Icons.people_outline,
      path: AppRoutes.doctorPatients,
    ),
    ShellDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      path: AppRoutes.doctorSettings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return RoleShellScaffold(
      title: 'Doctor',
      destinations: _destinations,
      child: child,
    );
  }
}
