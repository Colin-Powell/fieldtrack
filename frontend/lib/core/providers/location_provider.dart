import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:fieldtrack/core/network/error_handler.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../services/location_naming_service.dart';
import 'checkin_provider.dart';

/// Holds the current GPS location state shared across the entire app.
class LocationState {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String locationName;
  final bool isLocating;
  final String? error;

  const LocationState({
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.accuracy = 0.0,
    this.locationName = 'Locating...',
    this.isLocating = true,
    this.error,
  });

  LocationState copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    String? locationName,
    bool? isLocating,
    String? error,
  }) {
    return LocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      locationName: locationName ?? this.locationName,
      isLocating: isLocating ?? this.isLocating,
      error: error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final Ref _ref;
  final ApiClient _apiClient = ApiClient();
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastPingTime;

  LocationNotifier(this._ref) : super(const LocationState()) {
    _initLocation();
  }

  Future<void> _initLocation() async {
    state = state.copyWith(isLocating: true, error: null);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(isLocating: false, locationName: 'Location services disabled', error: 'Location services disabled');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        state = state.copyWith(isLocating: false, locationName: 'Location permission denied', error: 'Location permission denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      _updateFromPosition(position);

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).listen(
        _updateFromPosition,
        onError: (error) {
          state = state.copyWith(isLocating: false, locationName: 'GPS signal lost', error: error.toString());
        },
      );
    } catch (e) {
      state = state.copyWith(isLocating: false, locationName: 'Unable to capture GPS', error: ErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  void _updateFromPosition(Position position) {
    final lat = position.latitude;
    final lng = position.longitude;
    final acc = position.accuracy;

    // Immediately update with raw coordinates while we fetch the friendly name
    final fallbackName = 'Lat ${lat.toStringAsFixed(4)}, Lng ${lng.toStringAsFixed(4)}';
    state = state.copyWith(
      latitude: lat,
      longitude: lng,
      accuracy: acc,
      locationName: fallbackName,
      isLocating: false,
      error: null,
    );

    // Fetch human-readable name asynchronously
    Future.microtask(() async {
      try {
        final name = await LocationNamingService().getLocationName(lat, lng);
        if (mounted) {
          state = state.copyWith(locationName: name);
        }
      } catch (_) {}
    });

    _pingBackendIfCheckedIn(position);
  }

  void _pingBackendIfCheckedIn(Position position) {
    // Check if we are checked in
    // Note: We need to import checkinProvider
    // but checkinProvider depends on locationProvider, which might cause circular dependency if we read it here.
    // However, ref.read(checkinProvider) dynamically reads it so it should be fine.
    
    // Throttle pings to at most once every 30 seconds
    final now = DateTime.now();
    if (_lastPingTime != null && now.difference(_lastPingTime!).inSeconds < 30) {
      return;
    }
    _lastPingTime = now;

    // Async ping without awaiting
    Future.microtask(() async {
      try {
        // Guard against hot-reload where _ref may be stale
        if (!mounted) return;
        final checkInState = _ref.read(checkInProvider);
        if (checkInState.isCheckedIn && checkInState.sessionId != null) {
          await _apiClient.dio.post(ApiEndpoints.sessionLocationPing, data: {
            'sessionId': checkInState.sessionId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
            'altitude': position.altitude,
            'speed': position.speed,
            'heading': position.heading,
          });
        }
      } catch (e) {
        // Silently swallow — ping is best-effort
      }
    });
  }

  Future<void> refresh() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _initLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier(ref);
});
