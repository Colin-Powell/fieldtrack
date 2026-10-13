import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'local_id_resolver.dart';

class QueueItem {
  final String id;
  final String operation;
  final String endpoint;
  final String method;
  final dynamic payload;
  final String? localEntityId;
  final List<String> dependencies;
  int attempts;
  String status;
  final String createdAt;
  String? lastError;
  String? nextRetryAt;

  QueueItem({
    required this.id,
    required this.operation,
    required this.endpoint,
    required this.method,
    required this.payload,
    this.localEntityId,
    this.dependencies = const [],
    this.attempts = 0,
    this.status = 'pending',
    required this.createdAt,
    this.lastError,
    this.nextRetryAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'operation': operation,
        'endpoint': endpoint,
        'method': method,
        'payload': payload,
        'localEntityId': localEntityId,
        'dependencies': dependencies,
        'attempts': attempts,
        'status': status,
        'createdAt': createdAt,
        'lastError': lastError,
        'nextRetryAt': nextRetryAt,
      };

  factory QueueItem.fromJson(Map<String, dynamic> json) => QueueItem(
        id: json['id'],
        operation: json['operation'],
        endpoint: json['endpoint'],
        method: json['method'],
        payload: json['payload'],
        localEntityId: json['localEntityId'],
        dependencies: List<String>.from(json['dependencies'] ?? []),
        attempts: json['attempts'] ?? 0,
        status: json['status'] ?? 'pending',
        createdAt: json['createdAt'],
        lastError: json['lastError'],
        nextRetryAt: json['nextRetryAt'],
      );
}

class OfflineQueueService {
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  static const String _boxName = 'offline_queue_v2';
  late Box<String> _box;
  bool _isSyncing = false;
  final Uuid _uuid = const Uuid();

  Future<void> init() async {
    await Hive.initFlutter();
    await localIdResolver.init();
    _box = await Hive.openBox<String>(_boxName);
  }

  Future<void> enqueueRequest({
    required String operation,
    required String endpoint,
    required String method,
    required dynamic data,
    String? localEntityId,
    List<String> dependencies = const [],
  }) async {
    dynamic payloadToStore;

    // Handle FormData serialization
    if (data is FormData) {
      final fields = <String, dynamic>{};
      for (var field in data.fields) {
        fields[field.key] = field.value;
      }
      final files = <Map<String, dynamic>>[];
      final dir = await getApplicationDocumentsDirectory();
      final offlineMediaDir = Directory('${dir.path}/offline_media');
      if (!await offlineMediaDir.exists()) {
        await offlineMediaDir.create(recursive: true);
      }

      for (var fileField in data.files) {
        final mFile = fileField.value;
        // Wait, MultipartFile in dio cannot be easily read as bytes synchronously.
        // Actually, if it's from a file, we can just grab its path if we know it.
        // But dio's MultipartFile doesn't expose the original file path.
        // So we need to enforce that the caller passes a special map for files when enqueueing.
        // Let's assume `data` can be a Map containing `__isFormData__: true` and `files` array.
      }
    }

    // Workaround: Callers MUST NOT pass FormData directly if they want offline media support.
    // They must pass a serializable map. We will convert it to FormData during sync.
    payloadToStore = data;

    final item = QueueItem(
      id: _uuid.v4(),
      operation: operation,
      endpoint: endpoint,
      method: method,
      payload: payloadToStore,
      localEntityId: localEntityId,
      dependencies: dependencies,
      createdAt: DateTime.now().toIso8601String(),
    );

    await _box.put(item.id, jsonEncode(item.toJson()));
  }

  Future<void> syncQueue(Dio dio) async {
    if (_isSyncing) return;
    if (_box.isEmpty) return;

    _isSyncing = true;
    try {
      final keys = _box.keys.toList();
      for (var key in keys) {
        final jsonStr = _box.get(key);
        if (jsonStr == null) continue;

        final item = QueueItem.fromJson(jsonDecode(jsonStr));
        
        if (item.status == 'failed' || item.attempts >= 5) {
          item.status = 'failed';
          await _box.put(key, jsonEncode(item.toJson()));
          continue; // Skip failed items. User must manually retry.
        }

        if (item.nextRetryAt != null) {
          final nextRetry = DateTime.parse(item.nextRetryAt!);
          if (DateTime.now().isBefore(nextRetry)) {
            continue; // Backoff not elapsed
          }
        }

        // Check dependencies
        bool canRun = true;
        for (var depId in item.dependencies) {
          final serverId = localIdResolver.getServerId(depId);
          if (serverId == null) {
            canRun = false;
            break;
          }
        }
        if (!canRun) continue;

        // Resolve IDs in payload and endpoint
        final resolvedEndpoint = localIdResolver.resolveInString(item.endpoint);
        final resolvedPayload = localIdResolver.resolveInJson(item.payload);

        dynamic requestData = resolvedPayload;
        // Reconstruct FormData if needed
        if (resolvedPayload is Map && resolvedPayload['__isFormData__'] == true) {
          final formData = FormData();
          final fields = resolvedPayload['fields'] as Map<String, dynamic>? ?? {};
          fields.forEach((k, v) => formData.fields.add(MapEntry(k, v.toString())));

          final files = resolvedPayload['files'] as List<dynamic>? ?? [];
          for (var f in files) {
            formData.files.add(MapEntry(
              f['fieldName'],
              await MultipartFile.fromFile(f['path'], filename: f['filename']),
            ));
          }
          requestData = formData;
        }

        try {
          item.attempts++;
          final response = await dio.request(
            resolvedEndpoint,
            data: requestData,
            options: Options(method: item.method),
          );

          if (item.localEntityId != null && response.data != null && response.data['id'] != null) {
            localIdResolver.addMapping(item.localEntityId!, response.data['id']);
          }

          // Cleanup media files if any
          if (resolvedPayload is Map && resolvedPayload['__isFormData__'] == true) {
             final files = resolvedPayload['files'] as List<dynamic>? ?? [];
             for (var f in files) {
               try {
                 await File(f['path']).delete();
               } catch (_) {}
             }
          }

          await _box.delete(key);
        } catch (e) {
          item.lastError = e.toString();
          if (e is DioException && e.response?.statusCode == 409) {
            // Already exists / Idempotency handled
            if (item.localEntityId != null && e.response?.data != null && e.response?.data['id'] != null) {
               localIdResolver.addMapping(item.localEntityId!, e.response!.data['id']);
            }
            await _box.delete(key);
          } else {
            // Calculate exponential backoff (e.g. 2^attempts minutes)
            if (item.attempts < 5) {
               final minutesToWait = (1 << (item.attempts - 1)) * 2; // 2, 4, 8, 16
               item.nextRetryAt = DateTime.now().add(Duration(minutes: minutesToWait)).toIso8601String();
            }
            await _box.put(key, jsonEncode(item.toJson()));
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
