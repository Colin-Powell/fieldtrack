import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceFingerprintInterceptor extends Interceptor {
  final FlutterSecureStorage secureStorage;
  String? _deviceId;
  String? _deviceModel;
  String? _platform;
  String? _osVersion;

  DeviceFingerprintInterceptor({required this.secureStorage});

  Future<void> init() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String? hardwareId;

    // 1. Extract Hardware Device Info
    try {
      if (kIsWeb) {
        final webBrowserInfo = await deviceInfoPlugin.webBrowserInfo;
        _platform = 'Web';
        _deviceModel = webBrowserInfo.browserName.name;
        _osVersion = webBrowserInfo.appVersion;
        // Web has no hardware ID
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        _platform = 'Android';
        _deviceModel = androidInfo.model;
        _osVersion = androidInfo.version.release;
        hardwareId = androidInfo.id; // Strict hardware ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        _platform = 'iOS';
        _deviceModel = iosInfo.utsname.machine;
        _osVersion = iosInfo.systemVersion;
        hardwareId = iosInfo.identifierForVendor; // Strict hardware ID
      } else {
        _platform = Platform.operatingSystem;
        _deviceModel = 'Unknown Model';
        _osVersion = Platform.operatingSystemVersion;
      }
    } catch (e) {
      _platform = 'Unknown';
      _deviceModel = 'Unknown';
      _osVersion = 'Unknown';
    }

    // 2. Assign Device ID (Strict > Fallback)
    if (hardwareId != null && hardwareId.isNotEmpty) {
      _deviceId = hardwareId;
      // Optionally store it, but we always rely on the OS now
      await secureStorage.write(key: 'device_id', value: _deviceId!);
    } else {
      // Fallback for Web or failures
      _deviceId = await secureStorage.read(key: 'device_id');
      if (_deviceId == null) {
        _deviceId = const Uuid().v4();
        await secureStorage.write(key: 'device_id', value: _deviceId!);
      }
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_deviceId == null) {
      await init();
    }
    
    options.headers['X-Device-Id'] = _deviceId;
    options.headers['X-Device-Model'] = _deviceModel;
    options.headers['X-Platform'] = _platform;
    options.headers['X-OS-Version'] = _osVersion;

    // Enhance the User-Agent if possible
    options.headers['User-Agent'] = 'FieldTrack/1.0.0 ($_platform $_osVersion; $_deviceModel) Dart/3.0';

    super.onRequest(options, handler);
  }
}
