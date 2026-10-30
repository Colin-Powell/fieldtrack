import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/router/app_router.dart';
import 'package:fieldtrack/core/theme/app_theme.dart';
import 'package:fieldtrack/core/constants/app_constants.dart';
import 'package:fieldtrack/core/app_setup.dart';

import 'package:fieldtrack/core/network/api_client.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fieldtrack/core/services/notification_service.dart';
import 'package:fieldtrack/core/services/analytics_service.dart';
import 'package:fieldtrack/core/widgets/offline_banner.dart';
import 'package:fieldtrack/core/providers/location_provider.dart';
import 'package:fieldtrack/firebase_options.dart';
import 'package:fieldtrack/core/theme/theme_provider.dart';
import 'package:fieldtrack/core/network/offline_queue_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await loadFrontendEnv();

  final apiBaseUrl = AppConstants.apiUrl;
  if (apiBaseUrl.isEmpty) {
    debugPrint('API_URL is not configured in the frontend env file.');
  }
  debugPrint('Frontend API URL: $apiBaseUrl');

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (error, stackTrace) {
    debugPrint('Firebase.initializeApp() failed: $error');
    debugPrint(stackTrace.toString());
  }

  try {
    await AnalyticsService.initialize(appArea: 'student');
  } catch (error, stackTrace) {
    debugPrint('Firebase Analytics initialization failed: $error');
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

  runApp(const ProviderScope(child: FieldTrackApp()));
}

class FieldTrackApp extends ConsumerStatefulWidget {
  const FieldTrackApp({super.key});

  @override
  ConsumerState<FieldTrackApp> createState() => _FieldTrackAppState();
}

class _FieldTrackAppState extends ConsumerState<FieldTrackApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial sync of pending offline actions on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OfflineQueueService().syncQueue(ApiClient().dio);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Sync pending offline operations whenever app comes to foreground
      OfflineQueueService().syncQueue(ApiClient().dio);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.read(locationProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'FieldTrack',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
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
