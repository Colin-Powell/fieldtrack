import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/providers/auth_provider.dart';
import 'package:fieldtrack/core/providers/activity_provider.dart';
import 'package:fieldtrack/core/network/api_result.dart';

final studentActivitiesProvider = FutureProvider.family.autoDispose<ApiResult<List<dynamic>>, Map<String, dynamic>>((ref, params) async {
  final authState = ref.watch(authProvider);
  final studentId = authState.user?.id;
  
  if (studentId == null) {
    return const Success([]);
  }
  
  final service = ref.read(activityServiceProvider);
  return await service.getStudentActivities(
    studentId, 
    page: params['page'] ?? 1, 
    limit: params['limit'] ?? 50,
    status: params['status'],
    search: params['search'],
  );
});

typedef StudentActivitiesParams = ({String studentId, int? page, int? limit, String? status, String? search});

final studentActivitiesByStudentIdProvider = FutureProvider.family.autoDispose<ApiResult<List<dynamic>>, StudentActivitiesParams>((ref, params) async {
  final service = ref.read(activityServiceProvider);
  return await service.getStudentActivities(
    params.studentId,
    page: params.page ?? 1,
    limit: params.limit ?? 50,
    status: params.status,
    search: params.search,
  );
});

final activityDetailsProvider = FutureProvider.family.autoDispose<ApiResult<Map<String, dynamic>>, String>((ref, activityId) async {
  final service = ref.read(activityServiceProvider);
  return await service.getActivityById(activityId);
});
