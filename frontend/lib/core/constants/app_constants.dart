import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const appName = 'FieldTrack';
  static const primaryColorHex = '#16A34A';
  static const secondaryColorHex = '#DCFCE7';
  static const backgroundColorHex = '#F8FAFC';
  static const defaultRadius = 24.0;

  static String get apiUrl {
    String? envUrl;
    try {
      if (dotenv.isInitialized) {
        envUrl = dotenv.env['API_URL']?.trim().isNotEmpty == true
            ? dotenv.env['API_URL']
            : dotenv.env['BASE_URL'];
      }
    } catch (_) {
      envUrl = null;
    }

    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    if (kIsWeb) {
      return 'https://fieldtrack-api-ge94.onrender.com/api/v1';
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'https://fieldtrack-api-ge94.onrender.com/api/v1';
      }
    } catch (_) {}

    return 'https://fieldtrack-api-ge94.onrender.com/api/v1';
  }
}
