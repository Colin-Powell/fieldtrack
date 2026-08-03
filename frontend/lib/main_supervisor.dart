import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/app_setup.dart';
import 'package:fieldtrack/core/router/supervisor_router.dart';
import 'package:fieldtrack/core/theme/app_theme.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fieldtrack/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadFrontendEnv();
  try {
    await Firebase.initializeApp();
  } catch (error, stackTrace) {
    debugPrint('Firebase.initializeApp() failed: $error');
    debugPrint(stackTrace.toString());
  }
  try {
    await ApiClient().init();
  } catch (error, stackTrace) {
    debugPrint('ApiClient init failed: $error');
    debugPrint(stackTrace.toString());
  }
  try {
    await NotificationService().init();
  } catch (error, stackTrace) {
    debugPrint('NotificationService init failed: $error');
    debugPrint(stackTrace.toString());
  }
  runApp(const ProviderScope(child: SupervisorApp()));
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class SupervisorApp extends ConsumerWidget {
  const SupervisorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(supervisorRouterProvider);

    return MaterialApp.router(
      title: 'FieldTrack Supervisor',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.lightTheme(),
      routerConfig: router,
    );
  }
}
