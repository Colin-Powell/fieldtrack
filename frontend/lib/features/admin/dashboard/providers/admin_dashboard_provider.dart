import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class AdminDashboardStats {
  final int totalStudents;
  final int activeSupervisors;
  final int activeProjects;
  final int pendingReviews;

  AdminDashboardStats({
    required this.totalStudents,
    required this.activeSupervisors,
    required this.activeProjects,
    required this.pendingReviews,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      totalStudents: json['totalStudents'] ?? 0,
      activeSupervisors: json['activeSupervisors'] ?? 0,
      activeProjects: json['activeProjects'] ?? 0,
      pendingReviews: json['pendingReviews'] ?? 0,
    );
  }
}

final adminDashboardProvider = FutureProvider<AdminDashboardStats>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/dashboard/admin');
  return AdminDashboardStats.fromJson(response.data);
});
