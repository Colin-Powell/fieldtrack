import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as pkg_provider;
import '../providers/auth_provider.dart';

import 'package:fieldtrack/features/supervisor/authentication/supervisor_login_screen.dart';
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

final supervisorRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/supervisor/login',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isAuth = authState.isAuthenticated;
      final user = authState.user;
      final path = state.uri.path;
      final isLoginRoute = path == '/supervisor/login';

      if (!isAuth && !isLoginRoute) {
        return '/supervisor/login';
      }

      if (isAuth && isLoginRoute) {
        if (user?.role == 'SUPERVISOR' || user?.role == 'ADMIN') {
          return '/supervisor/dashboard';
        }
      }

      if (isAuth && user?.role != 'SUPERVISOR' && user?.role != 'ADMIN' && path.startsWith('/supervisor') && !isLoginRoute) {
        ref.read(authProvider.notifier).logout();
        return '/supervisor/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/supervisor/login',
        builder: (context, state) => const SupervisorLoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return pkg_provider.ChangeNotifierProvider<DashboardState>(
            create: (_) => DashboardState()..loadDashboard(),
            builder: (context, _) => child,
          );
        },
        routes: [
          GoRoute(
            path: '/supervisor/dashboard',
            builder: (context, state) {
              return const SupervisorScaffold(
                currentLocation: '/supervisor/dashboard',
                child: SupervisorDashboardScreen(),
              );
            },
          ),
          GoRoute(
            path: '/supervisor/students',
            builder: (context, state) {
              return const SupervisorScaffold(
                currentLocation: '/supervisor/students',
                child: SupervisorStudentsScreen(),
              );
            },
          ),
          GoRoute(
            path: '/supervisor/student/:id',
            builder: (context, state) {
              final studentId = state.pathParameters['id'] ?? '';
              return SupervisorScaffold(
                currentLocation: '/supervisor/student/$studentId',
                child: SupervisorStudentProfileScreen(
                  studentId: studentId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/supervisor/student/:id/logs',
            builder: (context, state) {
              final studentId = state.pathParameters['id'] ?? '';
              final studentName = state.extra is String
                  ? (state.extra as String)
                  : 'Jane Akinyi';
              return SupervisorScaffold(
                currentLocation: '/supervisor/student/$studentId/logs',
                child: SupervisorDailyFieldLogsScreen(
                  studentId: studentId,
                  studentName: studentName,
                ),
              );
            },
          ),
          GoRoute(
            path: '/supervisor/student/:id/location',
            builder: (context, state) {
              final studentId = state.pathParameters['id'] ?? '';
              return SupervisorScaffold(
                currentLocation: '/supervisor/student/$studentId/location',
                child: SupervisorLocationScreen(studentId: studentId),
              );
            },
          ),
          GoRoute(
            path: '/supervisor/student/:id/activity/:activityId',
            builder: (context, state) {
              final studentId = state.pathParameters['id'] ?? '';
              final activityId = state.pathParameters['activityId'] ?? '';
              final extraMap = state.extra is Map<String, String>
                  ? (state.extra as Map<String, String>)
                  : <String, String>{};
              final studentName = extraMap['studentName'] ?? 'Jane Akinyi';
              final activityTitle = extraMap['activityTitle'] ?? 'Activity Details';
              return SupervisorScaffold(
                currentLocation:
                    '/supervisor/student/$studentId/activity/$activityId',
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
            builder: (context, state) {
              final studentId = state.pathParameters['id'] ?? '';
              final activityId = state.pathParameters['activityId'] ?? '';
              return SupervisorScaffold(
                currentLocation:
                    '/supervisor/student/$studentId/activity/$activityId/evidence',
                child: SupervisorEvidenceScreen(
                  studentId: studentId,
                  activityId: activityId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/supervisor/reports',
            builder: (context, state) {
              return const SupervisorScaffold(
                currentLocation: '/supervisor/reports',
                child: SupervisorReportsScreen(),
              );
            },
          ),
          GoRoute(
            path: '/supervisor/map',
            builder: (context, state) {
              return const SupervisorScaffold(
                currentLocation: '/supervisor/map',
                child: SupervisorMapScreen(),
              );
            },
          ),
          GoRoute(
            path: '/supervisor/settings',
            builder: (context, state) {
              final initialTab = state.extra is String
                  ? (state.extra as String)
                  : 'Notifications';
              return SupervisorScaffold(
                currentLocation: '/supervisor/settings',
                child: SupervisorSettingsScreen(initialTab: initialTab),
              );
            },
          ),
          GoRoute(
            path: '/supervisor/profile',
            builder: (context, state) {
              return const SupervisorScaffold(
                currentLocation: '/supervisor/profile',
                child: SupervisorProfileScreen(),
              );
            },
          ),
        ],
      ),
    ],
  );
});
