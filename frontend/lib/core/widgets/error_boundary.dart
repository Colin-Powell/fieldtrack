import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Error Boundary Widget - Catches exceptions and displays user-friendly error UI
/// Prevents single error from crashing entire app
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final VoidCallback? onErrorReset;
  final String title;

  const ErrorBoundary({
    required this.child,
    this.onErrorReset,
    this.title = 'Something went wrong',
    super.key,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  late _ErrorBoundaryNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = _ErrorBoundaryNotifier();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  void _resetError() {
    setState(() {
      _notifier.clearError();
    });
    widget.onErrorReset?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_notifier.hasError) {
      return Material(
        child: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Error icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Icon(
                          PhosphorIconsFill.warning,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error title
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Error message
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Text(
                        _notifier.errorMessage,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reset button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _resetError,
                        icon: Icon(PhosphorIcons.arrowCounterClockwise()),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1BA654),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Additional help text
                    Text(
                      'If the problem persists, please contact support at admin@fieldtrack.com',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return _ErrorBoundaryScope(notifier: _notifier, child: widget.child);
  }
}

/// Scope widget to pass error notifier to descendants
class _ErrorBoundaryScope extends InheritedNotifier<_ErrorBoundaryNotifier> {
  const _ErrorBoundaryScope({
    required _ErrorBoundaryNotifier notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static _ErrorBoundaryNotifier? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ErrorBoundaryScope>()
        ?.notifier;
  }
}

/// Notifier to track error state
class _ErrorBoundaryNotifier extends ChangeNotifier {
  String _errorMessage = '';
  bool _hasError = false;

  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  void setError(String message) {
    _errorMessage = message;
    _hasError = true;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    _hasError = false;
    notifyListeners();
  }
}
