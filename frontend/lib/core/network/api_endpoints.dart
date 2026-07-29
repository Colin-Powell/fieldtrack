/// Centralised API endpoint constants for the FieldTrack app.
///
/// All paths are relative to [ApiClient] base URL.
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ──────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String forcePasswordChange = '/auth/force-password-change';
  static const String refreshToken = '/auth/refresh';

  // ── Supervisor / Student Management ──────────────────────────────────
  static const String students = '/supervisor/students';
  static String studentById(String id) => '/supervisor/students/$id';
  static String studentActivities(String studentId) =>
      '/supervisor/students/$studentId/activities';
  static String studentActivity(String studentId, String activityId) =>
      '/supervisor/students/$studentId/activities/$activityId';
  static String studentDailyLogs(String studentId) =>
      '/supervisor/students/$studentId/logs';
  static String studentDailyLog(String studentId, String logId) =>
      '/supervisor/students/$studentId/logs/$logId';
  static String studentEvidence(String studentId, String activityId) =>
      '/supervisor/students/$studentId/activities/$activityId/evidence';
  static String studentLocation(String studentId) =>
      '/supervisor/students/$studentId/location';
  static String studentReviews(String studentId) =>
      '/supervisor/students/$studentId/reviews';
  static String studentTimeline(String studentId) =>
      '/supervisor/students/$studentId/timeline';
  static String studentNotifications(String studentId) =>
      '/supervisor/students/$studentId/notifications';

  // ── Dashboard ────────────────────────────────────────────────────────
  static const String dashboardStats = '/dashboard/supervisor';
  static const String recentActivities =
      '/supervisor/dashboard/recent-activities';
  static const String activityFeed = '/supervisor/dashboard/feed';
  static const String pendingReviews = '/supervisor/dashboard/pending-reviews';

  // ── Supervisor Actions ───────────────────────────────────────────────
  static const String reviewActivity = '/reviews';
  static String reviewById(String id) => '/supervisor/reviews/$id';
  static const String generateReport = '/supervisor/reports/generate';
  static const String exportLogs = '/supervisor/logs/export';

  // ── Map / Location ───────────────────────────────────────────────────
  static const String liveLocations = '/supervisor/map/live';
  static String studentGpsHistory(String studentId) =>
      '/sessions/student/$studentId/pings';

  // ── Notifications ────────────────────────────────────────────────────
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';

  // ── Sessions (Check-In/Out) ──────────────────────────────────────────
  static const String sessionCheckIn = '/sessions/checkin';
  static const String sessionCheckOut = '/sessions/checkout';
  static const String sessionActive = '/sessions/active';
  static const String sessionLocationPing = '/sessions/ping';

  // ── Activities (Field Logs) ──────────────────────────────────────────
  static const String activities = '/activities';
  static String activitySubmit(String id) => '/activities/$id/submit';
  static const String studentAllActivities = '/activities/student/all';

  // ── Media ────────────────────────────────────────────────────────────
  static const String mediaUpload = '/media/upload';
}
