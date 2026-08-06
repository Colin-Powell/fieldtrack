import 'package:dio/dio.dart';

class ErrorHandler {
  static String getFriendlyErrorMessage(dynamic error) {
    if (error is DioException) {
      final message = _extractMessage(error.response?.data);
      if (message.isNotEmpty) {
        return message;
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 400) return 'Invalid request';
          if (statusCode == 401) return 'Session expired';
          if (statusCode == 403) return 'Access denied';
          if (statusCode == 404) return 'Not found';
          if (statusCode == 409) return 'Conflict';
          if (statusCode == 422) return 'Invalid data';
          if (statusCode == 429) return 'Rate limited';
          if (statusCode != null && statusCode >= 500) return 'Server error';
          return 'Network error';
        case DioExceptionType.cancel:
          return 'Request cancelled';
        case DioExceptionType.connectionError:
          return 'No internet';
        case DioExceptionType.unknown:
          return 'Unexpected error';
        default:
          return 'Unknown error';
      }
    } else if (error is String) {
      return error;
    }

    final errorString = error.toString();
    if (errorString.startsWith('Exception: ')) {
      return errorString.substring(11);
    }
    return 'An unexpected error occurred: $errorString';
  }

  static String _extractMessage(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final message = payload['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }

      final error = payload['error']?.toString().trim();
      if (error != null && error.isNotEmpty) {
        return error;
      }

      final details = payload['details'];
      if (details is List) {
        for (final detail in details) {
          if (detail is Map) {
            final detailMessage = detail['message']?.toString().trim();
            if (detailMessage != null && detailMessage.isNotEmpty) {
              return detailMessage;
            }
          }
        }
      }
    }

    if (payload is String) {
      final trimmed = payload.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return '';
  }
}
