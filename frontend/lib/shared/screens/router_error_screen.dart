import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/global_error_widget.dart';

class RouterErrorScreen extends StatelessWidget {
  final Exception? error;

  const RouterErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Error'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: GlobalErrorWidget(
        error: error,
        onRetry: () {
          context.go('/');
        },
      ),
    );
  }
}
