import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_queue_service.dart';
import 'package:fieldtrack/core/utils/toast_service.dart';

class ConnectivityInterceptor extends Interceptor {
  final OfflineQueueService _queue = OfflineQueueService();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // Offline
      if (options.method.toUpperCase() != 'GET') {
        // Enqueue mutation for later replay
        try {
          await _queue.enqueueRequest(options);
          ToastService.showInfo(
            'No internet connection. Action queued for synchronization.',
          );
        } catch (_) {
          // ignore enqueue errors
        }

        // Return a 202-like response to indicate queued
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 202,
            data: {'queued': true},
          ),
        );
      }
    }
    return handler.next(options);
  }
}
