import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class GlobalErrorWidget extends StatelessWidget {
  final dynamic error;
  final VoidCallback onRetry;

  const GlobalErrorWidget({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    String title = 'Something went wrong';
    String message = 'An unexpected error occurred. Please try again.';
    IconData icon = PhosphorIconsRegular.warning;

    if (error is DioException) {
      final dioError = error as DioException;
      
      switch (dioError.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          title = 'Connection Timeout';
          message = 'The server took too long to respond. Please check your connection and try again.';
          icon = PhosphorIconsRegular.clock;
          break;
        case DioExceptionType.badResponse:
          final statusCode = dioError.response?.statusCode;
          if (statusCode == 400) {
            title = 'Invalid Request';
            message = 'There was an issue with your request. Please check your input.';
          } else if (statusCode == 401) {
            title = 'Session Expired';
            message = 'Your session has expired. Please log in again.';
            icon = PhosphorIconsRegular.lockKey;
          } else if (statusCode == 403) {
            title = 'Access Denied';
            message = 'You do not have permission to access this resource.';
            icon = PhosphorIconsRegular.lock;
          } else if (statusCode == 404) {
            title = 'Resource Not Found';
            message = 'The requested resource could not be found.';
            icon = PhosphorIconsRegular.magnifyingGlass;
          } else if (statusCode == 409) {
            title = 'Conflict';
            message = 'There was a conflict with the server state. Please try again.';
          } else if (statusCode == 422) {
            title = 'Validation Error';
            message = 'The submitted data is invalid.';
          } else if (statusCode == 429) {
            title = 'Too Many Requests';
            message = 'You are making requests too quickly. Please slow down.';
            icon = PhosphorIconsRegular.hourglass;
          } else if (statusCode != null && statusCode >= 500) {
            title = 'Server Error';
            message = 'Our servers are currently experiencing issues. Please try again later.';
            icon = PhosphorIconsRegular.hardDrives;
          }
          break;
        case DioExceptionType.cancel:
          title = 'Request Cancelled';
          message = 'The operation was cancelled.';
          break;
        case DioExceptionType.connectionError:
          title = 'You are Offline';
          message = 'It seems you do not have an active internet connection. Please reconnect and try again.';
          icon = PhosphorIconsRegular.wifiSlash;
          break;
        case DioExceptionType.unknown:
          title = 'Unexpected Error';
          message = 'An unexpected error occurred. Please try again.';
          break;
        default:
          break;
      }
    } else if (error is String) {
      message = error as String;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
