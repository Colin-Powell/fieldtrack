import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fieldtrack/shared/widgets/empty_state_widget.dart';
import 'api_result.dart';
import '../../shared/widgets/global_error_widget.dart';

class ApiResultBuilder<T> extends StatefulWidget {
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
  State<ApiResultBuilder<T>> createState() => _ApiResultBuilderState<T>();
}

class _ApiResultBuilderState<T> extends State<ApiResultBuilder<T>> {
  T? _cachedData;

  @override
  Widget build(BuildContext context) {
    if (widget.asyncValue.hasValue && widget.asyncValue.value is Success<T>) {
      _cachedData = (widget.asyncValue.value as Success<T>).data;
    }

    return widget.asyncValue.when(
      data: (result) {
        if (result is Success<T>) {
          return widget.onData(result.data);
        } else if (result is Failure<T>) {
          if (_cachedData != null) {
            return widget.onData(_cachedData as T);
          }
          return EmptyStateWidget(
            title: 'Offline / Error',
            message: result.message.isNotEmpty ? result.message : 'You are offline. Connect to the internet to view this content.',
            icon: PhosphorIconsRegular.wifiSlash,
            actionLabel: 'Retry',
            onAction: widget.onRetry,
          );
        } else {
          if (_cachedData != null) return widget.onData(_cachedData as T);
          return widget.customLoading ?? const Center(child: CircularProgressIndicator());
        }
      },
      error: (err, stack) {
        if (_cachedData != null) return widget.onData(_cachedData as T);
        return EmptyStateWidget(
          title: 'Offline / Error',
          message: err.toString(),
          icon: PhosphorIconsRegular.wifiSlash,
          actionLabel: 'Retry',
          onAction: widget.onRetry,
        );
      },
      loading: () {
        if (_cachedData != null) return widget.onData(_cachedData as T);
        return widget.customLoading ?? const Center(child: CircularProgressIndicator());
      },
    );
  }
}
