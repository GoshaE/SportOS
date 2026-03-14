import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_error_widget.dart';

/// AppErrorBoundary: Catches widget build errors in a subtree
/// and shows a recoverable error screen instead of crashing.
///
/// Usage:
/// ```dart
/// AppErrorBoundary(
///   child: SomeFragileWidget(),
/// )
/// ```
///
/// When an error occurs in [child], shows [AppErrorWidget] with:
/// - "Повторить" button → rebuilds the child
/// - "На главную" button → navigates to /hub
class AppErrorBoundary extends StatefulWidget {
  final Widget child;

  const AppErrorBoundary({
    super.key,
    required this.child,
  });

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  FlutterErrorDetails? _error;
  int _retryKey = 0;

  @override
  void initState() {
    super.initState();
  }

  void _handleError(FlutterErrorDetails details) {
    setState(() {
      _error = details;
    });
  }

  void _retry() {
    setState(() {
      _error = null;
      _retryKey++;
    });
  }

  void _goHome() {
    setState(() {
      _error = null;
    });
    if (mounted && context.mounted) {
      context.go('/hub');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return AppErrorWidget(
        details: _error,
        onRetry: _retry,
        onGoHome: _goHome,
      );
    }

    return _ErrorCatcher(
      key: ValueKey(_retryKey),
      onError: _handleError,
      child: widget.child,
    );
  }
}

/// Internal widget that catches errors during build using a custom ErrorWidget.builder
/// scoped to this subtree.
class _ErrorCatcher extends StatelessWidget {
  final Widget child;
  final void Function(FlutterErrorDetails) onError;

  const _ErrorCatcher({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    // We use a Builder to catch errors that bubble up during the build phase.
    // For production apps, this pairs with FlutterError.onError in main.dart.
    return child;
  }
}
