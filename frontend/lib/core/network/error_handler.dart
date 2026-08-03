import 'package:dio/dio.dart';

class ErrorHandler {
  static String getFriendlyErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Please try again.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 400) return 'Invalid request.';
          if (statusCode == 401) return 'Session expired. Please log in.';
          if (statusCode == 403) return 'Access denied.';
          if (statusCode == 404) return 'Resource not found.';
          if (statusCode == 409) return 'Conflict error. Please try again.';
          if (statusCode == 422) return 'Invalid data submitted.';
          if (statusCode == 429) return 'Too many requests. Slow down.';
          if (statusCode != null && statusCode >= 500) return 'Server error. Try again later.';
          return 'Network error.';
        case DioExceptionType.cancel:
          return 'Request cancelled.';
        case DioExceptionType.connectionError:
          return 'No internet connection.';
        case DioExceptionType.unknown:
          return 'Unexpected error occurred.';
        default:
          return 'Unknown network error.';
      }
    } else if (error is String) {
      return error;
    }
    
    // If it's a standard exception that has a message, try to extract it cleanly
    final errorString = error.toString();
    if (errorString.startsWith('Exception: ')) {
      return errorString.substring(11);
    }
    return 'An unexpected error occurred: $errorString';
  }
}
