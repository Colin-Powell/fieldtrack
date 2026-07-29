import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/router/supervisor_router.dart';
import 'package:fieldtrack/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: SupervisorApp()));
}

class SupervisorApp extends ConsumerWidget {
  const SupervisorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(supervisorRouterProvider);

    return MaterialApp.router(
      title: 'FieldTrack Supervisor',
      theme: AppTheme.lightTheme(),
      routerConfig: router,
    );
  }
}
