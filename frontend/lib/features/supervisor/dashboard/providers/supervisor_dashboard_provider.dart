import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class SupervisorDashboardStats {
  final int checkedOut;
  final int checkedIn;
  final int studentsInField;
  final int pendingApprovals;
  final List<dynamic> recentLogs;

  SupervisorDashboardStats({
    required this.checkedOut,
    required this.checkedIn,
    required this.studentsInField,
    required this.pendingApprovals,
    required this.recentLogs,
  });

  factory SupervisorDashboardStats.fromJson(Map<String, dynamic> json) {
    return SupervisorDashboardStats(
      checkedOut: json['checkedOut'] ?? 0,
      checkedIn: json['checkedIn'] ?? 0,
      studentsInField: json['studentsInField'] ?? 0,
      pendingApprovals: json['pendingApprovals'] ?? 0,
      recentLogs: json['recentLogs'] ?? [],
    );
  }
}

final supervisorDashboardProvider = FutureProvider<SupervisorDashboardStats>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/dashboard/supervisor');
  return SupervisorDashboardStats.fromJson(response.data);
});
