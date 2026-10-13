import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fieldtrack/core/network/api_client.dart';

class LocationNamingService {
  static final LocationNamingService _instance = LocationNamingService._internal();

  factory LocationNamingService() {
    return _instance;
  }

  LocationNamingService._internal();

  // In-memory cache: "lat_rounded,lng_rounded" -> "Resolved Name"
  final Map<String, String> _cache = {};
  
  // Throttle tracking
  DateTime? _lastRequestTime;

  /// Resolves latitude and longitude to a human-readable name using Nominatim.
  /// 
  /// Caches the results by rounding coordinates to 3 decimal places (~110m accuracy)
  /// to avoid hitting the API rate limits (1 req/sec).
  Future<String> getLocationName(double lat, double lng) async {
    // 1. Check Cache
    final String cacheKey = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Default fallback in case of errors or rate limiting
    final String fallbackName = 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';

    // 2. Throttle Requests (Nominatim strictly requires max 1 req/sec)
    final now = DateTime.now();
    if (_lastRequestTime != null && now.difference(_lastRequestTime!).inSeconds < 1) {
      // If we are making requests too fast, just return raw coordinates for this frame.
      // Alternatively, we could delay, but returning fallback is safer for UI responsiveness.
      return fallbackName;
    }
    _lastRequestTime = now;

    // 3. Fetch from Nominatim
    try {
      final dio = ApiClient().dio; // Reuse existing Dio instance
      
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'zoom': 10, // City/County level
          'addressdetails': 1,
        },
        options: Options(
          headers: {
            // Nominatim requires a valid User-Agent
            'User-Agent': 'FieldTrack-FlutterApp/1.0 (contact@fieldtrack.app)',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['address'] != null) {
          final address = data['address'];
          
          String? name = address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'];
          
          if (name == null && data['display_name'] != null) {
            name = (data['display_name'] as String).split(',')[0].trim();
          }

          if (name != null && name.isNotEmpty) {
            _cache[cacheKey] = name;
            return name;
          }
        }
      }
    } catch (e) {
      debugPrint('LocationNamingService Error: $e');
    }

    // Return fallback if geocoding failed
    return fallbackName;
  }
}
