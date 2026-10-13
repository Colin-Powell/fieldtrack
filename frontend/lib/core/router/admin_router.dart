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
    final isAuthRoute = path == '/login' ||
        path.startsWith('/admin/login') ||
        path == '/forgot-password' ||
        path.startsWith('/admin/forgot-password') ||
        path == '/verify-otp' ||
        path.startsWith('/admin/verify-otp') ||
        path == '/reset-password' ||
        path.startsWith('/admin/reset-password');

    if (!isAuth && !isAuthRoute) {
      return '/login';
    }

    if (isAuth && isAuthRoute) {
      if (user?.role == 'ADMIN') {
        return '/dashboard';
      }
    }

    if (isAuth && user?.role != 'ADMIN' && !isAuthRoute) {
      _ref.read(authProvider.notifier).logout();
      return '/login';
    }

    return null;
  }
}

final adminRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AdminRouterNotifier(ref);

  return GoRouter(
    navigatorKey: ToastService.navigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    errorBuilder: (context, state) => NotFoundScreen(
      location: state.uri.toString(),
      homeRoute: '/dashboard',
    ),
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/dashboard',
      ),
      GoRoute(
        path: '/admin',
        redirect: (_, __) => '/dashboard',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/login',
        redirect: (_, __) => '/login',
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const AdminForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/admin/forgot-password',
        redirect: (_, __) => '/forgot-password',
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return AdminOtpScreen(email: email);
        },
      ),
      GoRoute(
        path: '/admin/verify-otp',
        redirect: (_, __) => '/verify-otp',
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const AdminResetPasswordScreen(),
      ),
      GoRoute(
        path: '/admin/reset-password',
        redirect: (_, __) => '/reset-password',
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
            path: '/dashboard',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/dashboard',
            redirect: (_, __) => '/dashboard',
          ),
          GoRoute(
            path: '/users',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminUsersScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/users',
            redirect: (_, __) => '/users',
          ),
          GoRoute(
            path: '/users/add',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AddUserScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/users/add',
            redirect: (_, __) => '/users/add',
          ),
          GoRoute(
            path: '/users/profile/:id',
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
            path: '/admin/users/profile/:id',
            redirect: (context, state) => '/users/profile/${state.pathParameters['id']}',
          ),
          GoRoute(
            path: '/users/edit/:id',
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
            path: '/admin/users/edit/:id',
            redirect: (context, state) => '/users/edit/${state.pathParameters['id']}',
          ),
          GoRoute(
            path: '/departments',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminDepartmentsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/departments',
            redirect: (_, __) => '/departments',
          ),
          GoRoute(
            path: '/departments/add',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminAddDepartmentScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/departments/add',
            redirect: (_, __) => '/departments/add',
          ),
          GoRoute(
            path: '/departments/:id',
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
            path: '/admin/departments/:id',
            redirect: (context, state) => '/departments/${state.pathParameters['id']}',
          ),
          GoRoute(
            path: '/projects',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminProjectsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/projects',
            redirect: (_, __) => '/projects',
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/reports',
            redirect: (_, __) => '/reports',
          ),
          GoRoute(
            path: '/map',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminMapScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/map',
            redirect: (_, __) => '/map',
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminNotificationsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/notifications',
            redirect: (_, __) => '/notifications',
          ),
          GoRoute(
            path: '/audit',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminAuditScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/audit',
            redirect: (_, __) => '/audit',
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminSettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settings',
            redirect: (_, __) => '/settings',
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _buildPageWithFadeTransition<void>(
              context: context,
              state: state,
              child: const AdminProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/profile',
            redirect: (_, __) => '/profile',
          ),
        ],
      ),
    ],
  );
});
