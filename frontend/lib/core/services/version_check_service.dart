import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionCheckService {
  final Dio _dio;
  
  VersionCheckService(this._dio);

  /// Checks the backend for version requirements.
  /// Returns a map with 'updateRequired', 'updateAvailable', and 'updateUrl' if applicable.
  Future<Map<String, dynamic>> checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await _dio.get('/api/v1/system/version');
      final data = response.data;

      if (data == null) {
        return {'updateRequired': false, 'updateAvailable': false};
      }

      final requiredVersion = data['requiredVersion'] as String?;
      final latestVersion = data['latestVersion'] as String?;
      final updateUrl = data['updateUrl'] as String?;

      bool isRequired = false;
      bool isAvailable = false;

      if (requiredVersion != null && _isVersionLower(currentVersion, requiredVersion)) {
        isRequired = true;
      }

      if (latestVersion != null && _isVersionLower(currentVersion, latestVersion)) {
        isAvailable = true;
      }

      return {
        'updateRequired': isRequired,
        'updateAvailable': isAvailable,
        'updateUrl': updateUrl,
      };
    } catch (e) {
      // If version check fails (network issue), we don't force update to avoid blocking users offline.
      print('Version check failed: $e');
      return {'updateRequired': false, 'updateAvailable': false};
    }
  }

  /// Helper to compare semantic versions.
  /// Returns true if v1 < v2.
  bool _isVersionLower(String v1, String v2) {
    try {
      final v1Parts = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final v2Parts = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final part1 = i < v1Parts.length ? v1Parts[i] : 0;
        final part2 = i < v2Parts.length ? v2Parts[i] : 0;

        if (part1 < part2) return true;
        if (part1 > part2) return false;
      }
      return false; // Equal versions
    } catch (e) {
      return false;
    }
  }
}
