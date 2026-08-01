import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fieldtrack/core/network/error_handler.dart';

class GlobalErrorWidget extends StatelessWidget {
  final dynamic error;
  final VoidCallback onRetry;

  const GlobalErrorWidget({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    String title = 'Something went wrong';
    String message = 'An unexpected error occurred. Please try again.';
    IconData icon = PhosphorIconsRegular.warning;

    if (error is String) {
      message = error as String;
    } else {
      message = ErrorHandler.getFriendlyErrorMessage(error);
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
