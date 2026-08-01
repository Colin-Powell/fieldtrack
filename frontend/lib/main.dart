import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/router/app_router.dart';
import 'package:fieldtrack/core/theme/app_theme.dart';

import 'package:fieldtrack/core/network/api_client.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fieldtrack/core/services/notification_service.dart';
import 'package:fieldtrack/core/utils/toast_service.dart';
import 'package:fieldtrack/core/widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await ApiClient().init();
  await NotificationService().init();

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
      builder: (context, child) {
        return Column(
          children: [
            const OfflineBanner(),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}
