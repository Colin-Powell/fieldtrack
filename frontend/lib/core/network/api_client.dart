import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: 'http://127.0.0.1:3000/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Automatically inject the JWT token for all requests
        try {
          final token = await _secureStorage.read(key: 'jwt_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          print('Secure storage read error in interceptor: $e');
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // If 401 Unauthorized, try to refresh token
          final refreshToken = await _secureStorage.read(key: 'refresh_token');
          if (refreshToken != null) {
            try {
              // Create a new Dio instance to avoid interceptor loops
              final retryDio = Dio(BaseOptions(baseUrl: 'http://192.168.18.2:3000/api/v1'));
              final response = await retryDio.post('/auth/refresh', data: {
                'refreshToken': refreshToken,
              });

              if (response.statusCode == 200 && response.data['success'] == true) {
                final newToken = response.data['token'];
                await _secureStorage.write(key: 'jwt_token', value: newToken);

                // Retry original request
                final opts = e.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                
                final retryResponse = await dio.fetch(opts);
                return handler.resolve(retryResponse);
              }
            } catch (_) {
              // Refresh token failed, clear everything
              await _secureStorage.delete(key: 'jwt_token');
              await _secureStorage.delete(key: 'refresh_token');
              // TODO: Redirect to login via Event Bus or similar
            }
          } else {
            await _secureStorage.delete(key: 'jwt_token');
            await _secureStorage.delete(key: 'refresh_token');
          }
        }
        return handler.next(e);
      },
    ));
  }
}
