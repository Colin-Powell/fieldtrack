import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldtrack/features/activities/activity_service.dart';

final activityServiceProvider = Provider<ActivityService>((ref) {
  return ActivityService();
});
