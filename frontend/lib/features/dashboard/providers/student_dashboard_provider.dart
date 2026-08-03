import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/network/api_client.dart';

class StudentDashboardStats {
  final String status;
  final int hoursLogged;
  final int approvals;
  final int totalActivities;
  final int evidenceFiles;
  final String syncStatus;

  StudentDashboardStats({
    required this.status,
    required this.hoursLogged,
    required this.approvals,
    required this.totalActivities,
    required this.evidenceFiles,
    required this.syncStatus,
  });

  factory StudentDashboardStats.fromJson(Map<String, dynamic> json) {
    return StudentDashboardStats(
      status: json['status'] as String? ?? 'IDLE',
      hoursLogged: json['hoursLogged'] as int? ?? 0,
      approvals: json['approvals'] as int? ?? 0,
      totalActivities: json['totalActivities'] as int? ?? 0,
      evidenceFiles: json['evidenceFiles'] as int? ?? 0,
      syncStatus: json['syncStatus'] as String? ?? 'Synced',
    );
  }
}

final studentDashboardProvider =
    FutureProvider.autoDispose<StudentDashboardStats>((ref) async {
      final api = ApiClient();
      final response = await api.dio.get('/dashboard/student');
      return StudentDashboardStats.fromJson(response.data);
    });
