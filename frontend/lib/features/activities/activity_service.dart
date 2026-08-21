import 'package:dio/dio.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:fieldtrack/core/network/api_result.dart';
import 'dart:io';
import 'package:fieldtrack/core/network/error_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:fieldtrack/core/network/offline_queue_service.dart';
import 'package:path_provider/path_provider.dart';

class ActivityService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResult<Map<String, dynamic>>> createDraftActivity({
    required String studentId,
    required String title,
    required String description,
    required String methodology,
    required double latitude,
    required double longitude,
    required double gpsAccuracy,
  }) async {
    final localId = const Uuid().v4();
    final data = {
      'localId': localId,
      'studentId': studentId,
      'title': title,
      'description': description,
      'methodology': methodology,
      'latitude': latitude,
      'longitude': longitude,
      'gpsAccuracy': gpsAccuracy,
    };

    try {
      final response = await _apiClient.dio.post('/activities', data: data);
      return Success(response.data);
    } catch (e) {
      if (e is DioException && (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError)) {
        await OfflineQueueService().enqueueRequest(
          operation: 'CREATE_ACTIVITY',
          endpoint: '/activities',
          method: 'POST',
          data: data,
          localEntityId: localId,
        );
        return Success({
          'id': localId,
          'status': 'DRAFT',
          'syncStatus': 'pending',
          ...data,
        });
      }
      return Failure(message: ErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> updateActivity({
    required String activityId,
    required String studentId,
    required String title,
    required String description,
    required String methodology,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/activities/$activityId',
        data: {
          'studentId': studentId,
          'title': title,
          'description': description,
          'methodology': methodology,
        },
      );
      return Success(response.data);
    } catch (e) {
      if (e is DioException && (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError)) {
        await OfflineQueueService().enqueueRequest(
          operation: 'UPDATE_ACTIVITY',
          endpoint: '/activities/$activityId',
          method: 'PUT',
          data: {
            'studentId': studentId,
            'title': title,
            'description': description,
            'methodology': methodology,
          },
          dependencies: [activityId], // Only if it's a local ID it will wait
        );
        return Success({
          'id': activityId,
          'status': 'DRAFT',
          'syncStatus': 'pending',
          'title': title,
          'description': description,
        });
      }
      return Failure(message: ErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> uploadEvidence({
    required String activityId,
    required String uploaderId,
    required String filePath,
    required double latitude,
    required double longitude,
    required double gpsAccuracy,
    required String evidenceType,
  }) async {
    final localId = const Uuid().v4();
    final file = File(filePath);
    String fileName = file.path.split('/').last;
    final capturedAt = DateTime.now().toIso8601String();

    try {
      FormData formData = FormData.fromMap({
        'localId': localId,
        'activityId': activityId,
        'uploaderId': uploaderId,
        'gpsLatitude': latitude.toString(),
        'gpsLongitude': longitude.toString(),
        'gpsAccuracy': gpsAccuracy.toString(),
        'capturedAt': capturedAt,
        'evidenceType': evidenceType,
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _apiClient.dio.post('/media/upload', data: formData);
      return Success(response.data);
    } catch (e) {
      if (e is DioException && (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError)) {
        // Copy file to offline media dir
        final dir = await getApplicationDocumentsDirectory();
        final offlineMediaDir = Directory('${dir.path}/offline_media');
        if (!await offlineMediaDir.exists()) await offlineMediaDir.create(recursive: true);
        final copiedFile = await file.copy('${offlineMediaDir.path}/${const Uuid().v4()}_$fileName');

        final payload = {
          '__isFormData__': true,
          'fields': {
            'localId': localId,
            'activityId': activityId,
            'uploaderId': uploaderId,
            'gpsLatitude': latitude.toString(),
            'gpsLongitude': longitude.toString(),
            'gpsAccuracy': gpsAccuracy.toString(),
            'capturedAt': capturedAt,
            'evidenceType': evidenceType,
          },
          'files': [
            {
              'fieldName': 'file',
              'path': copiedFile.path,
              'filename': fileName,
            }
          ]
        };

        await OfflineQueueService().enqueueRequest(
          operation: 'UPLOAD_EVIDENCE',
          endpoint: '/media/upload',
          method: 'POST',
          data: payload,
          localEntityId: localId,
          dependencies: [activityId], // Wait for this activityId to resolve
        );
        
        return Success({
          'id': localId,
          'status': 'pending',
          'syncStatus': 'pending',
          'originalName': fileName,
        });
      }
      return Failure(message: ErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  Future<ApiResult<void>> submitActivity({
    required String activityId,
    required String studentId,
  }) async {
    final data = {
      'studentId': studentId,
    };
    try {
      await _apiClient.dio.post(
        '/activities/$activityId/submit',
        data: data,
      );
      return const Success(null);
    } catch (e) {
      if (e is DioException && (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError)) {
        await OfflineQueueService().enqueueRequest(
          operation: 'SUBMIT_ACTIVITY',
          endpoint: '/activities/$activityId/submit',
          method: 'POST',
          data: data,
          dependencies: [activityId],
        );
        return const Success(null); // Optimistic success
      }
      return Failure(message: ErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  Future<ApiResult<List<dynamic>>> getStudentActivities(
    String studentId, {
    int page = 1,
    int limit = 50,
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = {
        'studentId': studentId,
        'page': page,
        'limit': limit,
      };
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.dio.get(
        '/activities/student/all',
        queryParameters: queryParams,
      );
      return Success(response.data as List<dynamic>);
    } on DioException catch (e) {
      return Failure(
        message: ErrorHandler.getFriendlyErrorMessage(e),
        exception: e,
      );
    } catch (e) {
      return Failure(message: ErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> getActivityById(String activityId) async {
    try {
      final response = await _apiClient.dio.get('/activities/$activityId');
      return Success(response.data);
    } on DioException catch (e) {
      return Failure(
        message: ErrorHandler.getFriendlyErrorMessage(e),
        exception: e,
      );
    } catch (e) {
      return Failure(message: ErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  Future<ApiResult<void>> deleteActivity(String activityId) async {
    try {
      await _apiClient.dio.delete('/activities/$activityId');
      return const Success(null);
    } on DioException catch (e) {
      return Failure(
        message: ErrorHandler.getFriendlyErrorMessage(e),
        exception: e,
      );
    } catch (e) {
      return Failure(message: ErrorHandler.getFriendlyErrorMessage(e));
    }
  }
}
