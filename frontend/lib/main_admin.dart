import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fieldtrack/core/shortcuts/app_intents.dart';
import 'package:fieldtrack/shared/widgets/command_palette.dart';
import 'package:fieldtrack/core/app_setup.dart';
import 'package:fieldtrack/core/router/admin_router.dart';
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
  runApp(const ProviderScope(child: AdminApp()));
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: 'FieldTrack Admin',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.lightTheme(),
      routerConfig: router,
      builder: (context, child) {
        return Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            const SingleActivator(LogicalKeyboardKey.keyK, control: true): const SearchIntent(),
            const SingleActivator(LogicalKeyboardKey.keyK, meta: true): const SearchIntent(),
            const SingleActivator(LogicalKeyboardKey.digit1, alt: true): const NavigateDashboardIntent(),
            const SingleActivator(LogicalKeyboardKey.digit2, alt: true): const NavigateUsersIntent(),
            const SingleActivator(LogicalKeyboardKey.digit3, alt: true): const NavigateProjectsIntent(),
            const SingleActivator(LogicalKeyboardKey.digit4, alt: true): const NavigateReportsIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              SearchIntent: CallbackAction<SearchIntent>(
                onInvoke: (intent) {
                  CommandPalette.show(context, commands: [
                    CommandItem(
                      title: 'Go to Dashboard',
                      icon: PhosphorIconsRegular.squaresFour,
                      onSelect: () => context.go('/admin/dashboard'),
                    ),
                    CommandItem(
                      title: 'Manage Users',
                      subtitle: 'View and edit students and supervisors',
                      icon: PhosphorIconsRegular.users,
                      onSelect: () => context.go('/admin/users'),
                    ),
                    CommandItem(
                      title: 'Manage Departments',
                      icon: PhosphorIconsRegular.buildings,
                      onSelect: () => context.go('/admin/departments'),
                    ),
                    CommandItem(
                      title: 'Manage Projects',
                      icon: PhosphorIconsRegular.folder,
                      onSelect: () => context.go('/admin/projects'),
                    ),
                    CommandItem(
                      title: 'Reports & Analytics',
                      icon: PhosphorIconsRegular.chartLineUp,
                      onSelect: () => context.go('/admin/reports'),
                    ),
                  ]);
                  return null;
                },
              ),
              NavigateDashboardIntent: CallbackAction<NavigateDashboardIntent>(onInvoke: (_) { context.go('/admin/dashboard'); return null; }),
              NavigateUsersIntent: CallbackAction<NavigateUsersIntent>(onInvoke: (_) { context.go('/admin/users'); return null; }),
              NavigateProjectsIntent: CallbackAction<NavigateProjectsIntent>(onInvoke: (_) { context.go('/admin/projects'); return null; }),
              NavigateReportsIntent: CallbackAction<NavigateReportsIntent>(onInvoke: (_) { context.go('/admin/reports'); return null; }),
            },
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
