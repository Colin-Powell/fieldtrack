import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'dart:io';
import '../constants/app_constants.dart';
import 'auth_interceptor.dart';
import 'connectivity_interceptor.dart';
import 'offline_queue_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final OfflineQueueService offlineQueue = OfflineQueueService();
  CacheOptions? _cacheOptions;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
  }

  Future<void> init() async {
    // Initialize offline queue
    await offlineQueue.init();

    // Initialize cache store
    CacheStore cacheStore;
    if (kIsWeb) {
      cacheStore = MemCacheStore();
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final hiveStore = HiveCacheStore(dir.path);
      await hiveStore.clean(); // Temporary fix to clear corrupt caches
      cacheStore = hiveStore;
    }
    _cacheOptions = CacheOptions(
      store: cacheStore,
      policy: CachePolicy.request,
      hitCacheOnErrorExcept: [401, 403, 404, 500],
      maxStale: const Duration(days: 7),
      priority: CachePriority.normal,
      cipher: null,
      keyBuilder: (request) {
        return CacheOptions.defaultCacheKeyBuilder(request) + (request.headers['Authorization'] ?? '');
      },
      allowPostMethod: false,
    );

    // 1. Connectivity (Checks online/offline status, throws if offline and method is not GET)
    if (!kIsWeb) {
      dio.interceptors.add(ConnectivityInterceptor());
    }

    // 2. Auth Interceptor
    dio.interceptors.add(AuthenticationInterceptor(dio, _secureStorage));

    // 3. Cache Interceptor
    dio.interceptors.add(DioCacheInterceptor(options: _cacheOptions!));

    // 4. Retry Interceptor
    dio.interceptors.add(RetryInterceptor(
      dio: dio,
      logPrint: print,
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
      ],
      retryEvaluator: (error, attempt) {
        if (error.type == DioExceptionType.connectionTimeout || 
            error.type == DioExceptionType.receiveTimeout || 
            error.type == DioExceptionType.sendTimeout ||
            error.error is SocketException) {
          return true;
        }
        return false;
      },
    ));
    
    // 5. Logging Interceptor
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: false,
      error: true,
    ));
  }

  /// Expose method to manually trigger sync when coming back online
  Future<void> syncOfflineMutations() async {
    await offlineQueue.syncQueue(dio);
  }
}
