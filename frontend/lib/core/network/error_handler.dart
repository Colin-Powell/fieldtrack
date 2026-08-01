import 'package:dio/dio.dart';

class ErrorHandler {
  static String getFriendlyErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'The server took too long to respond. Please check your connection and try again.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 400) {
            return 'There was an issue with your request. Please check your input.';
          } else if (statusCode == 401) {
            return 'Your session has expired. Please log in again.';
          } else if (statusCode == 403) {
            return 'You do not have permission to access this resource.';
          } else if (statusCode == 404) {
            return 'The requested resource could not be found.';
          } else if (statusCode == 409) {
            return 'There was a conflict with the server state. Please try again.';
          } else if (statusCode == 422) {
            return 'The submitted data is invalid.';
          } else if (statusCode == 429) {
            return 'You are making requests too quickly. Please slow down.';
          } else if (statusCode != null && statusCode >= 500) {
            return 'Our servers are currently experiencing issues. Please try again later.';
          }
          return 'An error occurred while communicating with the server.';
        case DioExceptionType.cancel:
          return 'The operation was cancelled.';
        case DioExceptionType.connectionError:
          return 'It seems you do not have an active internet connection. Please reconnect and try again.';
        case DioExceptionType.unknown:
          return 'An unexpected error occurred. Please try again.';
        default:
          return 'An unknown network error occurred.';
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
