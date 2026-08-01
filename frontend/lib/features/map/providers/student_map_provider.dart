import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:fieldtrack/core/providers/location_provider.dart';
import 'package:fieldtrack/features/activities/providers/student_activities_provider.dart';
import 'package:fieldtrack/core/network/api_result.dart';

class ActivityMarkerData {
  final LatLng position;
  final String title;
  final String description;
  final String? avatarUrl;
  
  const ActivityMarkerData({
    required this.position,
    required this.title,
    required this.description,
    this.avatarUrl,
  });
}

class StudentMapState {
  final List<LatLng> visitedRoute;
  final List<ActivityMarkerData> activityLocations;
  final LatLng? supervisorLocation;

  const StudentMapState({
    this.visitedRoute = const [],
    this.activityLocations = const [],
    this.supervisorLocation,
  });

  StudentMapState copyWith({
    List<LatLng>? visitedRoute,
    List<ActivityMarkerData>? activityLocations,
    LatLng? supervisorLocation,
  }) {
    return StudentMapState(
      visitedRoute: visitedRoute ?? this.visitedRoute,
      activityLocations: activityLocations ?? this.activityLocations,
      supervisorLocation: supervisorLocation ?? this.supervisorLocation,
    );
  }
}

class StudentMapNotifier extends StateNotifier<StudentMapState> {
  final Ref _ref;

  StudentMapNotifier(this._ref) : super(const StudentMapState()) {
    _init();
  }

  void _init() {
    // 1. Listen to location changes to draw the route
    _ref.listen<LocationState>(locationProvider, (previous, next) {
      if (!next.isLocating && next.error == null) {
        final currentPos = LatLng(next.latitude, next.longitude);
        
        // Simple logic: add to route if it's the first point or if we moved slightly
        if (state.visitedRoute.isEmpty) {
          state = state.copyWith(visitedRoute: [currentPos]);
        } else {
          final lastPos = state.visitedRoute.last;
          final distance = const Distance().as(LengthUnit.Meter, lastPos, currentPos);
          if (distance > 5.0) { // Only add points if moved > 5 meters
            state = state.copyWith(visitedRoute: [...state.visitedRoute, currentPos]);
          }
        }
      }
    });

    // 2. Mock Supervisor Location (e.g. Kilifi area near Pwani Uni)
    // In a real app, this would subscribe to a WebSocket or periodic API pull
    state = state.copyWith(supervisorLocation: const LatLng(-3.6350, 39.8470));

    // 3. Listen to activities to pull activity locations
    _ref.listen(studentActivitiesProvider, (previous, next) {
      next.whenData((activitiesResult) {
        if (activitiesResult is Success) {
          final activities = (activitiesResult as Success).data as List<dynamic>;
          final List<ActivityMarkerData> activityMarkers = [];
          for (final activity in activities) {
            if (activity['latitude'] != null && activity['longitude'] != null) {
              activityMarkers.add(
                ActivityMarkerData(
                  position: LatLng((activity['latitude'] as num).toDouble(), (activity['longitude'] as num).toDouble()),
                  title: activity['title'] ?? 'Activity',
                  description: activity['description'] ?? 'No description',
                  avatarUrl: activity['user']?['avatarUrl'], // Assuming populated or accessible via authProvider
                )
              );
            }
          }
          state = state.copyWith(activityLocations: activityMarkers);
        }
      });
    }, fireImmediately: true);
  }
}

final studentMapProvider = StateNotifierProvider<StudentMapNotifier, StudentMapState>((ref) {
  return StudentMapNotifier(ref);
});

