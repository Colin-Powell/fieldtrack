import 'package:flutter/foundation.dart';

class AppConstants {
  static const appName = 'FieldTrack';
  static const primaryColorHex = '#16A34A';
  static const secondaryColorHex = '#DCFCE7';
  static const backgroundColorHex = '#F8FAFC';
  static const defaultRadius = 24.0;
  
  static String get apiUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:3000/api/v1';
    }
    // Check if Android (works for both physical devices and emulators on the same network)
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://192.168.18.4:3000/api/v1';
      }
    } catch (_) {}
    
    // Fallback for physical devices over Wi-Fi (iOS/etc)
    return 'http://192.168.18.4:3000/api/v1';
  }
}
