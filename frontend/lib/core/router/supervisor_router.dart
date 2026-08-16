import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as pkg_provider;
import '../providers/auth_provider.dart';

import 'package:fieldtrack/features/supervisor/authentication/supervisor_login_screen.dart';
import 'package:fieldtrack/features/supervisor/authentication/supervisor_forgot_password_screen.dart';
import 'package:fieldtrack/features/supervisor/authentication/supervisor_otp_screen.dart';
import 'package:fieldtrack/features/supervisor/authentication/supervisor_reset_password_screen.dart';
import 'package:fieldtrack/features/supervisor/dashboard/supervisor_dashboard_screen.dart';
import 'package:fieldtrack/features/supervisor/dashboard/dashboard_state.dart';
import 'package:fieldtrack/features/supervisor/widgets/supervisor_scaffold.dart';
import 'package:fieldtrack/features/supervisor/students/supervisor_students_screen.dart';
import 'package:fieldtrack/features/supervisor/student_profile/supervisor_student_profile_screen.dart';
import 'package:fieldtrack/features/supervisor/field_logs/supervisor_daily_field_logs_screen.dart';
import 'package:fieldtrack/shared/models/student_data.dart';
import 'package:fieldtrack/features/supervisor/activity/supervisor_activity_details_screen.dart';
import 'package:fieldtrack/features/supervisor/evidence/supervisor_evidence_screen.dart';
import 'package:fieldtrack/features/supervisor/location/supervisor_location_screen.dart';
import 'package:fieldtrack/features/supervisor/map/supervisor_map_screen.dart';
import 'package:fieldtrack/features/supervisor/reports/supervisor_reports_screen.dart';
import 'package:fieldtrack/features/supervisor/settings/supervisor_settings_screen.dart';
import 'package:fieldtrack/features/supervisor/profile/supervisor_profile_screen.dart';
import 'package:fieldtrack/shared/screens/not_found_screen.dart';
import 'package:fieldtrack/core/utils/toast_service.dart';

CustomTransitionPage<T> _buildPageWithFadeTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeOutCubic).animate(animation),
        child: child,
      );
    },
  );
}


class _SupervisorRouterNotifier extends ChangeNotifier {
  _SupervisorRouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
  AuthState get _auth => _ref.read(authProvider);

  String? redirect(BuildContext context, GoRouterState state) {
    if (_auth.isLoading) return null;

    final isAuth = _auth.isAuthenticated;
    final user = _auth.user;
    final path = state.uri.path;
    final isAuthRoute = path.startsWith('/supervisor/login') || path.startsWith('/supervisor/forgot-password') || path.startsWith('/supervisor/verify-otp') || path.startsWith('/supervisor/reset-password');

    if (!isAuth && !isAuthRoute) {
      return '/supervisor/login';
    }

    if (isAuth && isAuthRoute) {
      if (user?.role == 'SUPERVISOR') {
        return '/supervisor/dashboard';
      }
    }

    if (isAuth && user?.role != 'SUPERVISOR' && path.startsWith('/supervisor') && !isAuthRoute) {
      _ref.read(authProvider.notifier).logout();
      return '/supervisor/login';
    }

    return null;
  }
}

final supervisorRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _SupervisorRouterNotifier(ref);

  return GoRouter(
    navigatorKey: ToastService.navigatorKey,
    initialLocation: '/supervisor/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    errorBuilder: (context, state) => NotFoundScreen(
      location: state.uri.toString(),
      homeRoute: '/supervisor/dashboard',
    ),
    routes: [
      GoRoute(
        path: '/supervisor/login',
        builder: (context, state) => const SupervisorLoginScreen(),
      ),
      GoRoute(
        path: '/supervisor/forgot-password',
        builder: (context, state) {
          // Import inline to avoid top-level import clutter if not needed, or better, we can add it at the top
          return const SupervisorForgotPasswordScreen();
        },
      ),
      GoRoute(
        path: '/supervisor/verify-otp',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return SupervisorOtpScreen(email: email);
        },
      ),
      GoRoute(
        path: '/supervisor/reset-password',
        builder: (context, state) {
          return const SupervisorResetPasswordScreen();
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return pkg_provider.ChangeNotifierProvider<DashboardState>(
            create: (_) => DashboardState()..loadDashboard(),
            builder: (context, _) => SupervisorScaffold(
              currentLocation: state.uri.path,
              child: child,
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/supervisor/dashboard',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const SupervisorDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/supervisor/students',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const SupervisorStudentsScreen(),
            ),
          ),
          GoRoute(
            path: '/supervisor/student/:id',
            pageBuilder: (context, state) {
              final studentId = state.pathParameters['id'] ?? '';
              return _buildPageWithFadeTransition<void>(
                context: context,
                state: state,
                child: SupervisorStudentProfileScreen(
                  studentId: studentId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/supervisor/student/:id/logs',
            pageBuilder: (context, state) {
              final studentId = state.pathParameters['id'] ?? '';
              final studentName = state.extra is String
                  ? (state.extra as String)
                  : '';
              return _buildPageWithFadeTransition<void>(
                context: context,
                state: state,
                child: SupervisorDailyFieldLogsScreen(
                  studentId: studentId,
                  studentName: studentName,
                ),
              );
            },
          ),
          GoRoute(
            path: '/supervisor/student/:id/location',
            pageBuilder: (context, state) {
              final studentId = state.pathParameters['id'] ?? '';
              return _buildPageWithFadeTransition<void>(
                context: context,
                state: state,
                child: SupervisorLocationScreen(studentId: studentId),
              );
            },
          ),
          GoRoute(
            path: '/supervisor/student/:id/activity/:activityId',
            pageBuilder: (context, state) {
              final studentId = state.pathParameters['id'] ?? '';
              final activityId = state.pathParameters['activityId'] ?? '';
              final extraMap = state.extra is Map<String, String>
                  ? (state.extra as Map<String, String>)
                  : <String, String>{};
              final studentName = extraMap['studentName'] ?? '';
              final activityTitle = extraMap['activityTitle'] ?? 'Activity Details';
              return _buildPageWithFadeTransition<void>(
                context: context,
                state: state,
                child: SupervisorActivityDetailsScreen(
                  studentId: studentId,
                  activityId: activityId,
                  studentName: studentName,
                  activityTitle: activityTitle,
                ),
              );
            },
          ),
          GoRoute(
            path: '/supervisor/student/:id/activity/:activityId/evidence',
            pageBuilder: (context, state) {
              final studentId = state.pathParameters['id'] ?? '';
              final activityId = state.pathParameters['activityId'] ?? '';
              return _buildPageWithFadeTransition<void>(
                context: context,
                state: state,
                child: SupervisorEvidenceScreen(
                  studentId: studentId,
                  activityId: activityId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/supervisor/reports',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const SupervisorReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/supervisor/map',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const SupervisorMapScreen(),
            ),
          ),
          GoRoute(
            path: '/supervisor/settings',
            pageBuilder: (context, state) {
              final initialTab = state.extra is String
                  ? (state.extra as String)
                  : 'Notifications';
              return _buildPageWithFadeTransition<void>(
                context: context,
                state: state,
                child: SupervisorSettingsScreen(initialTab: initialTab),
              );
            },
          ),
          GoRoute(
            path: '/supervisor/profile',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const SupervisorProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
