import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

// ── Trend Data Point ──
class TrendDataPoint {
  final String label;
  final double value;
  final String dateLabel;

  const TrendDataPoint({required this.label, required this.value, required this.dateLabel});

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      label: json['label'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      dateLabel: json['dateLabel'] ?? '',
    );
  }
}

// ── Submission Segment ──
class SubmissionSegment {
  final String label;
  final double value;
  final String color;

  const SubmissionSegment({required this.label, required this.value, required this.color});

  factory SubmissionSegment.fromJson(Map<String, dynamic> json) {
    return SubmissionSegment(
      label: json['label'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      color: json['color'] ?? '#6B7280',
    );
  }
}

// ── Department Stat ──
class DeptStat {
  final String name;
  final int count;
  final double percentage;
  final String color;

  const DeptStat({required this.name, required this.count, required this.percentage, required this.color});

  factory DeptStat.fromJson(Map<String, dynamic> json) {
    return DeptStat(
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      color: json['color'] ?? '#169B45',
    );
  }
}

// ── Recent User ──
class RecentUser {
  final String name;
  final String role;
  final String time;
  final String avatarUrl;

  const RecentUser({required this.name, required this.role, required this.time, required this.avatarUrl});

  factory RecentUser.fromJson(Map<String, dynamic> json) {
    return RecentUser(
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      time: json['time'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
    );
  }
}

// ── System Activity ──
class SysActivity {
  final String title;
  final String desc;
  final String time;
  final String icon;
  final String color;

  const SysActivity({required this.title, required this.desc, required this.time, required this.icon, required this.color});

  factory SysActivity.fromJson(Map<String, dynamic> json) {
    return SysActivity(
      title: json['title'] ?? '',
      desc: json['desc'] ?? '',
      time: json['time'] ?? '',
      icon: json['icon'] ?? 'info',
      color: json['color'] ?? '#6B7280',
    );
  }
}

// ── Main Dashboard Stats ──
class AdminDashboardStats {
  final int totalStudents;
  final int activeSupervisors;
  final int studentsInField;
  final int submittedToday;
  final int pendingReviews;
  final int activeProjects;

  final List<TrendDataPoint> activityTrend;
  final List<TrendDataPoint> attendanceTrend;
  final List<SubmissionSegment> submissionStatus;
  final List<DeptStat> departmentStats;
  final List<RecentUser> recentUsers;
  final List<SysActivity> systemActivities;

  AdminDashboardStats({
    required this.totalStudents,
    required this.activeSupervisors,
    required this.studentsInField,
    required this.submittedToday,
    required this.pendingReviews,
    required this.activeProjects,
    required this.activityTrend,
    required this.attendanceTrend,
    required this.submissionStatus,
    required this.departmentStats,
    required this.recentUsers,
    required this.systemActivities,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      totalStudents: json['totalStudents'] ?? 0,
      activeSupervisors: json['activeSupervisors'] ?? 0,
      studentsInField: json['studentsInField'] ?? 0,
      submittedToday: json['submittedToday'] ?? 0,
      pendingReviews: json['pendingReviews'] ?? 0,
      activeProjects: json['activeProjects'] ?? 0,
      activityTrend: (json['activityTrend'] as List<dynamic>?)
              ?.map((e) => TrendDataPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      attendanceTrend: (json['attendanceTrend'] as List<dynamic>?)
              ?.map((e) => TrendDataPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      submissionStatus: (json['submissionStatus'] as List<dynamic>?)
              ?.map((e) => SubmissionSegment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      departmentStats: (json['departmentStats'] as List<dynamic>?)
              ?.map((e) => DeptStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentUsers: (json['recentUsers'] as List<dynamic>?)
              ?.map((e) => RecentUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      systemActivities: (json['systemActivities'] as List<dynamic>?)
              ?.map((e) => SysActivity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

final adminDashboardProvider = FutureProvider<AdminDashboardStats>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/dashboard/admin');
  return AdminDashboardStats.fromJson(response.data);
});

