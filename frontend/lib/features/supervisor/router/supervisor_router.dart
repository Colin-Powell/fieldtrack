import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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

/// Standalone GoRouter configuration for the Supervisor Portal.
///
/// This router is completely independent from the Student Portal router
/// (`app_router.dart`). It manages only supervisor-specific routes and
/// excludes forgot-password, OTP verification, and force-password-change
/// screens.
final GoRouter supervisorRouter = GoRouter(
  initialLocation: '/supervisor/login',
  routes: [
    // ── Authentication ──────────────────────────────────────────────────
    GoRoute(
      path: '/supervisor/login',
      builder: (context, state) => const SupervisorLoginScreen(),
    ),
    GoRoute(
      path: '/supervisor/forgot-password',
      builder: (context, state) => const SupervisorForgotPasswordScreen(),
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
      builder: (context, state) => const SupervisorResetPasswordScreen(),
    ),

    // ── Shell Route to inject DashboardState Provider above SupervisorScaffold/child pages ──
    ShellRoute(
      builder: (context, state, child) {
        return ChangeNotifierProvider<DashboardState>(
          create: (_) => DashboardState()..loadDashboard(),
          builder: (context, _) => child,
        );
      },
      routes: [
        // ── Dashboard ───────────────────────────────────────────────────────
        GoRoute(
          path: '/supervisor/dashboard',
          builder: (context, state) {
            return const SupervisorScaffold(
              currentLocation: '/supervisor/dashboard',
              child: SupervisorDashboardScreen(),
            );
          },
        ),

        // ── Students ────────────────────────────────────────────────────────
        GoRoute(
          path: '/supervisor/students',
          builder: (context, state) {
            return const SupervisorScaffold(
              currentLocation: '/supervisor/students',
              child: SupervisorStudentsScreen(),
            );
          },
        ),

        // ── Student Profile ─────────────────────────────────────────────────
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

        // ── Student Field Logs ──────────────────────────────────────────────
        GoRoute(
          path: '/supervisor/student/:id/logs',
          builder: (context, state) {
            final studentId = state.pathParameters['id'] ?? '';
            final studentName = state.extra is String
                ? (state.extra as String)
                : '';
            return SupervisorScaffold(
              currentLocation: '/supervisor/student/$studentId/logs',
              child: SupervisorDailyFieldLogsScreen(
                studentId: studentId,
                studentName: studentName,
              ),
            );
          },
        ),

        // ── Student Location ────────────────────────────────────────────────
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

        // ── Student Activity Details ────────────────────────────────────────
        GoRoute(
          path: '/supervisor/student/:id/activity/:activityId',
          builder: (context, state) {
            final studentId = state.pathParameters['id'] ?? '';
            final activityId = state.pathParameters['activityId'] ?? '';
            final extraMap = state.extra is Map<String, String>
                ? (state.extra as Map<String, String>)
                : <String, String>{};
            final studentName = extraMap['studentName'] ?? '';
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

        // ── Student Activity Evidence ───────────────────────────────────────
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

        // ── Reports ─────────────────────────────────────────────────────────
        GoRoute(
          path: '/supervisor/reports',
          builder: (context, state) {
            return const SupervisorScaffold(
              currentLocation: '/supervisor/reports',
              child: SupervisorReportsScreen(),
            );
          },
        ),

        // ── Map ─────────────────────────────────────────────────────────────
        GoRoute(
          path: '/supervisor/map',
          builder: (context, state) {
            return const SupervisorScaffold(
              currentLocation: '/supervisor/map',
              child: SupervisorMapScreen(),
            );
          },
        ),

        // ── Profile ─────────────────────────────────────────────────────────
        GoRoute(
          path: '/supervisor/profile',
          builder: (context, state) {
            return const SupervisorScaffold(
              currentLocation: '/supervisor/profile',
              child: SupervisorProfileScreen(),
            );
          },
        ),

        // ── Settings ────────────────────────────────────────────────────────
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
      ],
    ),
  ],
);
