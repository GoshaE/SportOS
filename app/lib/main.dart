import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/app_error_widget.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    // ── Layer 1: Catch Flutter framework errors (build, layout, paint) ──
    FlutterError.onError = (FlutterErrorDetails details) {
      // Always log to console
      FlutterError.presentError(details);
      // TODO: Send to Sentry/Crashlytics in production
      if (kReleaseMode) {
        // Sentry.captureException(details.exception, stackTrace: details.stack);
      }
    };

    // ── Layer 2: Replace red error screen with glassmorphic widget ──
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return AppErrorWidget(details: details);
    };

    runApp(
      const ProviderScope(
        child: SportOsApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    // ── Zone-level: Catch uncaught async errors (Future/Stream) ──
    debugPrint('⚠️ Unhandled async error: $error');
    debugPrint('Stack: $stack');
    // TODO: Send to Sentry/Crashlytics in production
    if (kReleaseMode) {
      // Sentry.captureException(error, stackTrace: stack);
    }
  });
}

class SportOsApp extends ConsumerWidget {
  const SportOsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'SportOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(colorScheme: themeState.lightScheme),
      darkTheme: AppTheme.darkTheme(colorScheme: themeState.darkScheme),
      themeMode: themeState.mode,
      routerConfig: router,
    );
  }
}
