import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class AdminReportFilters {
  final String period;
  final String department;
  final String supervisorId;
  final String county;

  AdminReportFilters({
    this.period = 'This Month',
    this.department = 'All Departments',
    this.supervisorId = 'All Supervisors',
    this.county = 'All Counties',
  });

  AdminReportFilters copyWith({
    String? period,
    String? department,
    String? supervisorId,
    String? county,
  }) {
    return AdminReportFilters(
      period: period ?? this.period,
      department: department ?? this.department,
      supervisorId: supervisorId ?? this.supervisorId,
      county: county ?? this.county,
    );
  }
}

final adminReportFiltersProvider = StateProvider<AdminReportFilters>((ref) {
  return AdminReportFilters();
});

final adminReportsProvider = FutureProvider.autoDispose((ref) async {
  final filters = ref.watch(adminReportFiltersProvider);
  final api = ApiClient();
  
  final queryParams = {
    'period': filters.period,
    'department': filters.department,
    'supervisorId': filters.supervisorId,
    'county': filters.county,
  };

  final response = await api.dio.get(
    ApiEndpoints.adminReports,
    queryParameters: queryParams,
  );
  
  return response.data as Map<String, dynamic>;
});
