import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

import 'package:fieldtrack/features/admin/auth/admin_login_screen.dart';
import 'package:fieldtrack/features/admin/auth/admin_forgot_password_screen.dart';
import 'package:fieldtrack/features/admin/auth/admin_otp_screen.dart';
import 'package:fieldtrack/features/admin/auth/admin_reset_password_screen.dart';
import 'package:fieldtrack/features/admin/widgets/admin_scaffold.dart';
import 'package:fieldtrack/features/admin/dashboard/admin_dashboard_screen.dart';
import 'package:fieldtrack/features/admin/users/admin_users_screen.dart';
import 'package:fieldtrack/features/admin/departments/admin_departments_screen.dart';
import 'package:fieldtrack/features/admin/departments/admin_add_department_screen.dart';
import 'package:fieldtrack/features/admin/departments/admin_department_detail_screen.dart';
import 'package:fieldtrack/features/admin/projects/admin_projects_screen.dart';
import 'package:fieldtrack/features/admin/reports/admin_reports_screen.dart';
import 'package:fieldtrack/features/admin/map/admin_map_screen.dart';
import 'package:fieldtrack/features/admin/notifications/admin_notifications_screen.dart';
import 'package:fieldtrack/features/admin/audit/admin_audit_screen.dart';
import 'package:fieldtrack/features/admin/settings/admin_settings_screen.dart';
import 'package:fieldtrack/features/admin/profile/admin_profile_screen.dart';
import 'package:fieldtrack/core/utils/toast_service.dart';
import 'package:fieldtrack/features/admin/users/user_profile_screen.dart';
import 'package:fieldtrack/features/admin/users/edit_user_screen.dart';
import 'package:fieldtrack/features/admin/users/add_user_screen.dart';
import 'package:fieldtrack/shared/screens/not_found_screen.dart';

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


class _AdminRouterNotifier extends ChangeNotifier {
  _AdminRouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
  AuthState get _auth => _ref.read(authProvider);

  String? redirect(BuildContext context, GoRouterState state) {
    if (_auth.isLoading) return null;

    final isAuth = _auth.isAuthenticated;
    final user = _auth.user;
    final path = state.uri.path;
    final isAuthRoute = path.startsWith('/admin/login') || path.startsWith('/admin/forgot-password') || path.startsWith('/admin/verify-otp') || path.startsWith('/admin/reset-password');

    if (!isAuth && !isAuthRoute) {
      return '/admin/login';
    }

    if (isAuth && isAuthRoute) {
      if (user?.role == 'ADMIN') {
        return '/admin/dashboard';
      }
    }

    if (isAuth && user?.role != 'ADMIN' && path.startsWith('/admin') && !isAuthRoute) {
      _ref.read(authProvider.notifier).logout();
      return '/admin/login';
    }

    return null;
  }
}

final adminRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AdminRouterNotifier(ref);

  return GoRouter(
    navigatorKey: ToastService.navigatorKey,
    initialLocation: '/admin/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    errorBuilder: (context, state) => NotFoundScreen(
      location: state.uri.toString(),
      homeRoute: '/admin/dashboard',
    ),
    routes: [
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/forgot-password',
        builder: (context, state) => const AdminForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/admin/verify-otp',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return AdminOtpScreen(email: email);
        },
      ),
      GoRoute(
        path: '/admin/reset-password',
        builder: (context, state) => const AdminResetPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AdminScaffold(
            currentLocation: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/users',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminUsersScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/users/add',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AddUserScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/users/profile/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return _buildPageWithFadeTransition<void>(
                context: context,
                state: state,
                child: UserProfileScreen(userId: id),
              );
            },
          ),
          GoRoute(
            path: '/admin/users/edit/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return _buildPageWithFadeTransition<void>(
                context: context,
                state: state,
                child: EditUserScreen(userId: id),
              );
            },
          ),
          GoRoute(
            path: '/admin/departments',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminDepartmentsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/departments/add',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminAddDepartmentScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/departments/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return _buildPageWithFadeTransition<void>(
                context: context,
                state: state,
                child: AdminDepartmentDetailScreen(departmentId: id),
              );
            },
          ),
          GoRoute(
            path: '/admin/projects',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminProjectsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/reports',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/map',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminMapScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/notifications',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminNotificationsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/audit',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminAuditScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settings',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminSettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/profile',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
