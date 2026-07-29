import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/router/app_router.dart';
import 'package:fieldtrack/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: FieldTrackApp()));
}

class FieldTrackApp extends ConsumerWidget {
  const FieldTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'FieldTrack',
      theme: AppTheme.lightTheme(),
      routerConfig: router,
    );
  }
}
