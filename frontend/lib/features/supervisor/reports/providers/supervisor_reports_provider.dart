import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/network/api_client.dart';

class SupervisorReportsData {
  final Map<String, dynamic> stats;
  final Map<String, dynamic> gaugeMap;
  final List<dynamic> trendData;
  final List<dynamic> recentActivities;

  SupervisorReportsData({
    required this.stats,
    required this.gaugeMap,
    required this.trendData,
    required this.recentActivities,
  });

  factory SupervisorReportsData.fromJson(Map<String, dynamic> json) {
    return SupervisorReportsData(
      stats: json['stats'] ?? {},
      gaugeMap: json['gaugeMap'] ?? {},
      trendData: json['trendData'] ?? [],
      recentActivities: json['recentActivities'] ?? [],
    );
  }
}

final supervisorReportsProvider = FutureProvider.autoDispose<SupervisorReportsData>((ref) async {
  try {
    final response = await ApiClient().dio.get('/reports/supervisor');
    return SupervisorReportsData.fromJson(response.data);
  } catch (e) {
    if (e is DioException) {
      throw Exception(e.response?.data?['error'] ?? 'Failed to load reports');
    }
    throw Exception('An unexpected error occurred');
  }
});
