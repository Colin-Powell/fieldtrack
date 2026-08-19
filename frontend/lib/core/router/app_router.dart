import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../providers/checkin_provider.dart';
import '../utils/toast_service.dart';
import 'package:fieldtrack/shared/screens/router_error_screen.dart';
import 'package:fieldtrack/shared/screens/not_found_screen.dart';
import 'package:fieldtrack/features/auth/splash_screen.dart';
import 'package:fieldtrack/features/auth/welcome_screen.dart';
import 'package:fieldtrack/features/auth/login_screen.dart';
import 'package:fieldtrack/features/auth/forgot_password_screen.dart';
import 'package:fieldtrack/features/auth/otp_verification_screen.dart';
import 'package:fieldtrack/features/auth/reset_password_screen.dart';
import 'package:fieldtrack/features/auth/force_password_change_screen.dart';
import 'package:fieldtrack/features/dashboard/dashboard_screen.dart';
import 'package:fieldtrack/features/field_session/field_session_screen.dart';
import 'package:fieldtrack/features/activities/activities_screen.dart';
import 'package:fieldtrack/features/map/map_screen.dart';
import 'package:fieldtrack/features/notifications/notifications_screen.dart';
import 'package:fieldtrack/features/profile/profile_screen.dart';
import 'package:fieldtrack/features/settings/settings_screen.dart';
import 'package:fieldtrack/features/activities/activity_detail_screen.dart';
import 'package:fieldtrack/features/checkin/checkin_screen.dart';
import 'package:fieldtrack/features/main_navigation/main_navigation_screen.dart';
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
import 'package:fieldtrack/features/admin/users/add_user_screen.dart';
import 'package:fieldtrack/features/admin/users/edit_user_screen.dart';
import 'package:fieldtrack/features/admin/users/user_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RouterNotifier — bridges Riverpod auth state → GoRouter refreshListenable
// ─────────────────────────────────────────────────────────────────────────────
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    // Listen to authProvider and notify GoRouter whenever it changes
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
    _ref.listen<CheckInState>(checkInProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  AuthState get _auth => _ref.read(authProvider);

  String? redirect(BuildContext context, GoRouterState state) {
    if (_auth.isLoading) return null;

    final isAuth = _auth.isAuthenticated;
    final user = _auth.user;
    final path = state.uri.path;

    final isAuthRoute =
        path == '/login' ||
        path == '/welcome' ||
        path == '/splash' ||
        path == '/forgot-password' ||
        path == '/otp' ||
        path == '/reset-password';

    // 1. Not logged in → welcome
    if (!isAuth && !isAuthRoute) return '/welcome';

    // 2. Must change password
    if (isAuth &&
        user?.mustChangePassword == true &&
        path != '/force-password-change') {
      return '/force-password-change';
    }
    if (isAuth &&
        user?.mustChangePassword == false &&
        path == '/force-password-change') {
      return '/portal';
    }

    // 3. Logged in but on auth route → route to portal
    if (isAuth && isAuthRoute) {
      if (user?.role == 'STUDENT') return '/portal';
      if (user?.role == 'ADMIN') return '/admin';
      if (user?.role == 'SUPERVISOR') return '/supervisor';
    }

    // 4. Non-students can't access /portal
    if (isAuth && user?.role != 'STUDENT' && path.startsWith('/portal')) {
      return '/login';
    }

    // 5. Non-admins can't access /admin
    if (isAuth && user?.role != 'ADMIN' && path.startsWith('/admin')) {
      return '/login';
    }

    // 6. Prevent starting a field session if not checked in
    if (isAuth && user?.role == 'STUDENT' && path.startsWith('/field-session')) {
      final checkInState = _ref.read(checkInProvider);
      if (!checkInState.isCheckedIn) {
        return '/checkin';
      }
    }

    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// routerProvider — stable singleton; never re-created on auth change
// ─────────────────────────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    navigatorKey: ToastService.navigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    errorBuilder: (context, state) => NotFoundScreen(
      location: state.uri.toString(),
      homeRoute: '/dashboard',
    ),
    routes: [
      // ── Auth & misc ────────────────────────────────────────────────────
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final email = state.extra is String ? state.extra as String : null;
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, __) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/force-password-change',
        builder: (_, __) => const ForcePasswordChangeScreen(),
      ),

      // ── Student portal ─────────────────────────────────────────────────
      GoRoute(
        path: '/portal',
        builder: (_, __) => const MainNavigationScreen(),
      ),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(
        path: '/field-session',
        builder: (_, state) => FieldSessionScreen(activityId: state.uri.queryParameters['id']),
      ),
      GoRoute(
        path: '/activities',
        builder: (_, __) => const ActivitiesScreen(),
      ),
      GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
        path: '/activity-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ActivityDetailScreen(activityId: id);
        },
      ),
      GoRoute(path: '/checkin', builder: (_, __) => const CheckInScreen()),

      // ── Admin portal — sidebar shell ────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            AdminScaffold(currentLocation: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/admin', redirect: (_, __) => '/admin/dashboard'),
          GoRoute(
            path: '/admin/dashboard',
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, __) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/departments',
            builder: (_, __) => const AdminDepartmentsScreen(),
          ),
          GoRoute(
            path: '/admin/projects',
            builder: (_, __) => const AdminProjectsScreen(),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (_, __) => const AdminReportsScreen(),
          ),
          GoRoute(
            path: '/admin/map',
            builder: (_, __) => const AdminMapScreen(),
          ),
          GoRoute(
            path: '/admin/notifications',
            builder: (_, __) => const AdminNotificationsScreen(),
          ),
          GoRoute(
            path: '/admin/audit',
            builder: (_, __) => const AdminAuditScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (_, __) => const AdminSettingsScreen(),
          ),
          GoRoute(
            path: '/admin/profile',
            builder: (_, __) => const AdminProfileScreen(),
          ),
          // ── Admin user management sub-routes ─
          GoRoute(
            path: '/admin/users/add',
            builder: (_, __) => const AddUserScreen(),
          ),
          GoRoute(
            path: '/admin/users/:id/profile',
            builder: (_, state) =>
                UserProfileScreen(userId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/admin/users/:id/edit',
            builder: (_, state) =>
                EditUserScreen(userId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});
