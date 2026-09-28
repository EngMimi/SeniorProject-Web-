import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

class NeuroInsightApp extends StatefulWidget {
  const NeuroInsightApp({super.key, this.router});

  /// Optional router override, mainly for tests.
  final GoRouter? router;

  @override
  State<NeuroInsightApp> createState() => _NeuroInsightAppState();
}

class _NeuroInsightAppState extends State<NeuroInsightApp> {
  late final GoRouter _router = widget.router ?? createAppRouter();

  @override
  void dispose() {
    if (widget.router == null) _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NeuroInsight PD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
