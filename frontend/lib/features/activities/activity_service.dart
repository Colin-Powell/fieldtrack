import 'package:dio/dio.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:fieldtrack/core/network/api_result.dart';
import 'dart:io';
import 'package:fieldtrack/core/network/error_handler.dart';

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
    try {
      final response = await _apiClient.dio.post(
        '/activities',
        data: {
          'studentId': studentId,
          'title': title,
          'description': description,
          'methodology': methodology,
          'latitude': latitude,
          'longitude': longitude,
          'gpsAccuracy': gpsAccuracy,
        },
      );
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
    } on DioException catch (e) {
      return Failure(
        message: ErrorHandler.getFriendlyErrorMessage(e),
        exception: e,
      );
    } catch (e) {
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
    try {
      final file = File(filePath);
      String fileName = file.path.split('/').last;

      FormData formData = FormData.fromMap({
        'activityId': activityId,
        'uploaderId': uploaderId,
        'gpsLatitude': latitude.toString(),
        'gpsLongitude': longitude.toString(),
        'gpsAccuracy': gpsAccuracy.toString(),
        'capturedAt': DateTime.now().toIso8601String(),
        'evidenceType': evidenceType,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post(
        '/media/upload',
        data: formData,
      );
      
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

  Future<ApiResult<void>> submitActivity({
    required String activityId,
    required String studentId,
  }) async {
    try {
      await _apiClient.dio.post(
        '/activities/$activityId/submit',
        data: {
          'studentId': studentId,
        },
      );
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
