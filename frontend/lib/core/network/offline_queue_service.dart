import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

class OfflineQueueService {
  static const String _boxName = 'offline_mutation_queue';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_boxName);
  }

  Future<void> enqueueRequest(RequestOptions options) async {
    final box = Hive.box<String>(_boxName);
    
    final requestData = {
      'method': options.method,
      'path': options.path,
      'headers': options.headers,
      'data': options.data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Add to Hive
    await box.add(jsonEncode(requestData));
  }

  Future<void> syncQueue(Dio dio) async {
    final box = Hive.box<String>(_boxName);
    if (box.isEmpty) return;

    final keys = box.keys.toList();
    for (var key in keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        final requestData = jsonDecode(jsonStr) as Map<String, dynamic>;
        
        try {
          // Replay request
          await dio.request(
            requestData['path'],
            data: requestData['data'],
            options: Options(
              method: requestData['method'],
              headers: Map<String, dynamic>.from(requestData['headers'] ?? {}),
            ),
          );
          
          // On success, remove from queue
          await box.delete(key);
        } catch (e) {
          if (e is DioException) {
            if (e.response?.statusCode == 409) {
              // Handle conflict (e.g., notify user, maybe delete from queue to avoid infinite loop)
              await box.delete(key);
            }
          }
          // Other errors (e.g. still offline) will leave it in the queue for next sync
        }
      }
    }
  }
}
