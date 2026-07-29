import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

import 'package:fieldtrack/features/admin/auth/admin_login_screen.dart';
import 'package:fieldtrack/features/admin/widgets/admin_scaffold.dart';
import 'package:fieldtrack/features/admin/dashboard/admin_dashboard_screen.dart';
import 'package:fieldtrack/features/admin/users/admin_users_screen.dart';
import 'package:fieldtrack/features/admin/departments/admin_departments_screen.dart';
import 'package:fieldtrack/features/admin/projects/admin_projects_screen.dart';
import 'package:fieldtrack/features/admin/reports/admin_reports_screen.dart';
import 'package:fieldtrack/features/admin/map/admin_map_screen.dart';
import 'package:fieldtrack/features/admin/notifications/admin_notifications_screen.dart';
import 'package:fieldtrack/features/admin/audit/admin_audit_screen.dart';
import 'package:fieldtrack/features/admin/settings/admin_settings_screen.dart';
import 'package:fieldtrack/features/admin/profile/admin_profile_screen.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/admin/login',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isAuth = authState.isAuthenticated;
      final user = authState.user;
      final path = state.uri.path;
      final isLoginRoute = path == '/admin/login';

      if (!isAuth && !isLoginRoute) {
        return '/admin/login';
      }

      if (isAuth && isLoginRoute) {
        if (user?.role == 'ADMIN') {
          return '/admin/dashboard';
        }
      }

      if (isAuth && user?.role != 'ADMIN' && path.startsWith('/admin') && !isLoginRoute) {
        ref.read(authProvider.notifier).logout();
        return '/admin/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) {
          return const AdminScaffold(
            currentLocation: '/admin/dashboard',
            child: AdminDashboardScreen(),
          );
        },
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) {
          return const AdminScaffold(
            currentLocation: '/admin/users',
            child: AdminUsersScreen(),
          );
        },
      ),
      GoRoute(
        path: '/admin/departments',
        builder: (context, state) {
          return const AdminScaffold(
            currentLocation: '/admin/departments',
            child: AdminDepartmentsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/admin/projects',
        builder: (context, state) {
          return const AdminScaffold(
            currentLocation: '/admin/projects',
            child: AdminProjectsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) {
          return const AdminScaffold(
            currentLocation: '/admin/reports',
            child: AdminReportsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/admin/map',
        builder: (context, state) {
          return const AdminScaffold(
            currentLocation: '/admin/map',
            child: AdminMapScreen(),
          );
        },
      ),
      GoRoute(
        path: '/admin/notifications',
        builder: (context, state) {
          return const AdminScaffold(
            currentLocation: '/admin/notifications',
            child: AdminNotificationsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/admin/audit',
        builder: (context, state) {
          return const AdminScaffold(
            currentLocation: '/admin/audit',
            child: AdminAuditScreen(),
          );
        },
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (context, state) {
          return const AdminScaffold(
            currentLocation: '/admin/settings',
            child: AdminSettingsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/admin/profile',
        builder: (context, state) {
          return const AdminScaffold(
            currentLocation: '/admin/profile',
            child: AdminProfileScreen(),
          );
        },
      ),
    ],
  );
});
