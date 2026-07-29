import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_result.dart';
import '../../shared/widgets/global_error_widget.dart';

class ApiResultBuilder<T> extends StatelessWidget {
  final AsyncValue<ApiResult<T>> asyncValue;
  final Widget Function(T data) onData;
  final VoidCallback onRetry;
  final Widget? customLoading;
  
  const ApiResultBuilder({
    super.key,
    required this.asyncValue,
    required this.onData,
    required this.onRetry,
    this.customLoading,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (result) {
        if (result is Success<T>) {
          return onData((result as Success<T>).data);
        } else if (result is Failure<T>) {
          return GlobalErrorWidget(
            error: (result as Failure<T>).message,
            onRetry: onRetry,
          );
        } else {
          return customLoading ?? const Center(child: CircularProgressIndicator());
        }
      },
      error: (err, stack) => GlobalErrorWidget(error: err, onRetry: onRetry),
      loading: () => customLoading ?? const Center(child: CircularProgressIndicator()),
    );
  }
}
