import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/network/api_client.dart';

class StudentDashboardStats {
  final String status;
  final int hoursLogged;
  final int approvals;

  StudentDashboardStats({
    required this.status,
    required this.hoursLogged,
    required this.approvals,
  });

  factory StudentDashboardStats.fromJson(Map<String, dynamic> json) {
    return StudentDashboardStats(
      status: json['status'] as String? ?? 'IDLE',
      hoursLogged: json['hoursLogged'] as int? ?? 0,
      approvals: json['approvals'] as int? ?? 0,
    );
  }
}

final studentDashboardProvider = FutureProvider<StudentDashboardStats>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/dashboard/student');
  return StudentDashboardStats.fromJson(response.data);
});
