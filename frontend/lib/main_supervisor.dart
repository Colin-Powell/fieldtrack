import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'core/shortcuts/app_intents.dart';
import 'shared/widgets/command_palette.dart';
import 'package:fieldtrack/core/app_setup.dart';
import 'package:fieldtrack/core/router/supervisor_router.dart';
import 'package:fieldtrack/core/theme/app_theme.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:fieldtrack/firebase_options.dart';
import 'package:fieldtrack/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadFrontendEnv();
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
      builder: (context, child) {
        return Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            const SingleActivator(LogicalKeyboardKey.keyK, control: true): const SearchIntent(),
            const SingleActivator(LogicalKeyboardKey.keyK, meta: true): const SearchIntent(),
            const SingleActivator(LogicalKeyboardKey.keyD, alt: true): const NavigateDashboardIntent(),
            const SingleActivator(LogicalKeyboardKey.keyS, alt: true): const NavigateStudentsIntent(),
            const SingleActivator(LogicalKeyboardKey.keyM, alt: true): const NavigateMapIntent(),
            const SingleActivator(LogicalKeyboardKey.keyF, alt: true): const NavigateFeedIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              SearchIntent: CallbackAction<SearchIntent>(
                onInvoke: (intent) {
                  CommandPalette.show(context, commands: [
                    CommandItem(
                      title: 'Go to Dashboard',
                      icon: PhosphorIconsRegular.squaresFour,
                      onSelect: () => context.go('/supervisor/dashboard'),
                    ),
                    CommandItem(
                      title: 'View Students',
                      subtitle: 'List of all assigned students',
                      icon: PhosphorIconsRegular.users,
                      onSelect: () => context.go('/supervisor/students'),
                    ),
                    CommandItem(
                      title: 'Live Map',
                      subtitle: 'Real-time locations of students in the field',
                      icon: PhosphorIconsRegular.mapTrifold,
                      onSelect: () => context.go('/supervisor/map'),
                    ),
                    CommandItem(
                      title: 'Activity Feed',
                      subtitle: 'Recent field logs and submissions',
                      icon: PhosphorIconsRegular.listDashes,
                      onSelect: () => context.go('/supervisor/feed'),
                    ),
                  ]);
                  return null;
                },
              ),
              NavigateDashboardIntent: CallbackAction<NavigateDashboardIntent>(onInvoke: (_) { context.go('/supervisor/dashboard'); return null; }),
              NavigateStudentsIntent: CallbackAction<NavigateStudentsIntent>(onInvoke: (_) { context.go('/supervisor/students'); return null; }),
              NavigateMapIntent: CallbackAction<NavigateMapIntent>(onInvoke: (_) { context.go('/supervisor/map'); return null; }),
              NavigateFeedIntent: CallbackAction<NavigateFeedIntent>(onInvoke: (_) { context.go('/supervisor/feed'); return null; }),
            },
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
