import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/core/providers/auth_provider.dart';
import 'package:fieldtrack/core/providers/activity_provider.dart';
import 'package:fieldtrack/core/network/api_result.dart';

final studentActivitiesProvider = FutureProvider.autoDispose<ApiResult<List<dynamic>>>((ref) async {
  final authState = ref.watch(authProvider);
  final studentId = authState.user?.id;
  
  if (studentId == null) {
    return const Success([]);
  }
  
  final service = ref.read(activityServiceProvider);
  return await service.getStudentActivities(studentId);
});

final studentActivitiesByStudentIdProvider = FutureProvider.family.autoDispose<ApiResult<List<dynamic>>, String>((ref, studentId) async {
  final service = ref.read(activityServiceProvider);
  return await service.getStudentActivities(studentId);
});

final activityDetailsProvider = FutureProvider.family.autoDispose<ApiResult<Map<String, dynamic>>, String>((ref, activityId) async {
  final service = ref.read(activityServiceProvider);
  return await service.getActivityById(activityId);
});
