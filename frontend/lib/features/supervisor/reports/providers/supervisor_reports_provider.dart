import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:fieldtrack/core/network/error_handler.dart';

class SupervisorReportsData {
  final Map<String, dynamic> stats;
  final Map<String, dynamic> gaugeMap;
  final List<dynamic> trendData;
  final List<dynamic> recentActivities;
  final List<dynamic> logSummary;
  final String period;

  SupervisorReportsData({
    required this.stats,
    required this.gaugeMap,
    required this.trendData,
    required this.recentActivities,
    required this.logSummary,
    required this.period,
  });

  factory SupervisorReportsData.fromJson(Map<String, dynamic> json) {
    return SupervisorReportsData(
      stats: json['stats'] ?? {},
      gaugeMap: json['gaugeMap'] ?? {},
      trendData: json['trendData'] ?? [],
      recentActivities: json['recentActivities'] ?? [],
      logSummary: json['logSummary'] ?? [],
      period: json['period'] ?? 'This Month',
    );
  }
}

final supervisorReportsProvider = FutureProvider.autoDispose
    .family<SupervisorReportsData, String>((ref, period) async {
      try {
        final response = await ApiClient().dio.get(
          '/reports/supervisor',
          queryParameters: {'period': period},
        );
        return SupervisorReportsData.fromJson(response.data);
      } catch (e) {
        if (e is DioException) {
          throw Exception(ErrorHandler.getFriendlyErrorMessage(e));
        }
        throw Exception('An unexpected error occurred');
      }
    });
