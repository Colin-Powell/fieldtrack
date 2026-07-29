import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class AuthenticationInterceptor extends Interceptor {
  final FlutterSecureStorage secureStorage;
  final Dio dio;

  AuthenticationInterceptor(this.dio, this.secureStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final token = await secureStorage.read(key: 'jwt_token');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      // Ignore secure storage read errors and proceed
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await secureStorage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          final retryDio = Dio(BaseOptions(baseUrl: AppConstants.apiUrl));
          final response = await retryDio.post('/auth/refresh', data: {
            'refreshToken': refreshToken,
          });

          if (response.statusCode == 200 && response.data['success'] == true) {
            final newToken = response.data['token'];
            await secureStorage.write(key: 'jwt_token', value: newToken);

            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newToken';

            final retryResponse = await dio.fetch(opts);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          await secureStorage.delete(key: 'jwt_token');
          await secureStorage.delete(key: 'refresh_token');
        }
      } else {
        await secureStorage.delete(key: 'jwt_token');
        await secureStorage.delete(key: 'refresh_token');
      }
    }
    return handler.next(err);
  }
}
