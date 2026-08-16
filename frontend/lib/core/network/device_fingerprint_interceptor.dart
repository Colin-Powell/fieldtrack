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
    // 1. Get or Generate Device ID
    _deviceId = await secureStorage.read(key: 'device_id');
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await secureStorage.write(key: 'device_id', value: _deviceId);
    }

    // 2. Extract Device Info
    final deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final webBrowserInfo = await deviceInfoPlugin.webBrowserInfo;
        _platform = 'Web';
        _deviceModel = webBrowserInfo.browserName.name;
        _osVersion = webBrowserInfo.appVersion;
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        _platform = 'Android';
        _deviceModel = androidInfo.model;
        _osVersion = androidInfo.version.release;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        _platform = 'iOS';
        _deviceModel = iosInfo.utsname.machine;
        _osVersion = iosInfo.systemVersion;
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
