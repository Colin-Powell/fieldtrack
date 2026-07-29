import 'package:dio/dio.dart';
import 'package:fieldtrack/core/network/api_client.dart';
import 'package:fieldtrack/core/network/api_result.dart';
import 'dart:io';

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
        message: e.message ?? 'Failed to create draft activity',
        exception: e,
      );
    } catch (e) {
      return Failure(message: e.toString());
    }
  }

  Future<ApiResult<Map<String, dynamic>>> uploadEvidence({
    required String activityId,
    required String uploaderId,
    required String filePath,
    required double latitude,
    required double longitude,
    required double gpsAccuracy,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Failure(message: 'File not found locally');
      }

      String fileName = file.path.split('/').last;

      FormData formData = FormData.fromMap({
        'activityId': activityId,
        'uploaderId': uploaderId,
        'gpsLatitude': latitude.toString(),
        'gpsLongitude': longitude.toString(),
        'gpsAccuracy': gpsAccuracy.toString(),
        'capturedAt': DateTime.now().toIso8601String(),
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
        message: e.message ?? 'Failed to upload evidence',
        exception: e,
      );
    } catch (e) {
      return Failure(message: e.toString());
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
        message: e.message ?? 'Failed to submit activity',
        exception: e,
      );
    } catch (e) {
      return Failure(message: e.toString());
    }
  }

  Future<ApiResult<List<dynamic>>> getStudentActivities(String studentId) async {
    try {
      final response = await _apiClient.dio.get(
        '/activities/student/all',
        queryParameters: {'studentId': studentId},
      );
      return Success(response.data as List<dynamic>);
    } on DioException catch (e) {
      return Failure(
        message: e.message ?? 'Failed to load activities',
        exception: e,
      );
    } catch (e) {
      return Failure(message: e.toString());
    }
  }

  Future<ApiResult<Map<String, dynamic>>> getActivityById(String activityId) async {
    try {
      final response = await _apiClient.dio.get('/activities/$activityId');
      return Success(response.data);
    } on DioException catch (e) {
      return Failure(
        message: e.message ?? 'Failed to load activity details',
        exception: e,
      );
    } catch (e) {
      return Failure(message: e.toString());
    }
  }
}
