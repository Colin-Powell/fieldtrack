import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/router/app_router.dart';
import 'package:fieldtrack/core/theme/app_theme.dart';

import 'package:fieldtrack/core/network/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient().init();
  
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
