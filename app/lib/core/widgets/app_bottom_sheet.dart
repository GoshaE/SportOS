import 'dart:ui';
import 'package:flutter/material.dart';

/// AppBottomSheet: Adaptive modal — bottom sheet on mobile, dialog on desktop/tablet.
///
/// Breakpoint: 600px (Material Design compact/medium boundary).
///
/// Usage:
/// ```dart
/// AppBottomSheet.show(context, title: 'Редактировать', child: ...)
/// ```
class AppBottomSheet {
  /// Compact breakpoint — below this width we show a bottom sheet.
  static const double _compactBreakpoint = 600;

  /// Shows an adaptive modal: bottom sheet on narrow screens,
  /// centered dialog on wide screens (tablet/desktop).
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    double initialHeight = 0.7,
    double maxHeight = 0.95,
    double minHeight = 0.3,
    List<Widget>? actions,
    double dialogMaxWidth = 520,
  }) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < _compactBreakpoint) {
      return _showSheet<T>(
        context,
        title: title,
        child: child,
        initialHeight: initialHeight,
        maxHeight: maxHeight,
        minHeight: minHeight,
        actions: actions,
      );
    } else {
      return _showDialog<T>(
        context,
        title: title,
        child: child,
        actions: actions,
        maxWidth: dialogMaxWidth,
      );
    }
  }

  // ── Mobile: Bottom Sheet ──
  static Future<T?> _showSheet<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    required double initialHeight,
    required double maxHeight,
    required double minHeight,
    List<Widget>? actions,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) {
        // Flutter сам учитывает клавиатуру при isScrollControlled: true.
        // Мы просто задаём максимальную фракцию высоты экрана.
        final screenHeight = MediaQuery.sizeOf(ctx).height;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * maxHeight,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title bar
                _buildTitleBar(context, ctx, title),
                const Divider(height: 1),
                // Scrollable content
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(20),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [child],
                  ),
                ),
                // Optional actions bar
                if (actions != null && actions.isNotEmpty)
                  _buildActions(actions),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Desktop/Tablet: Centered Dialog ──
  static Future<T?> _showDialog<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    List<Widget>? actions,
    required double maxWidth,
  }) {
    return showDialog<T>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.85),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title bar
                _buildTitleBar(context, ctx, title),
                const Divider(height: 1),
                // Content — flexible within max height
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: child,
                  ),
                ),
                // Actions
                if (actions != null && actions.isNotEmpty)
                  _buildActions(actions),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared: Title bar ──
  static Widget _buildTitleBar(BuildContext context, BuildContext ctx, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
          ),
        ],
      ),
    );
  }

  // ── Shared: Actions bar ──
  static Widget _buildActions(List<Widget> actions) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: actions[i]),
            ],
          ],
        ),
      ),
    );
  }
}

/// A custom PageRoute designed for nested navigators over glass (blur) backgrounds.
/// It uses `opaque: false` to ensure we don't accidentally render solid backgrounds
/// after transitions, and explicitly fades out the outgoing page while the new page fades in.
class AppGlassRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  AppGlassRoute({required this.child})
      : super(
          opaque: false, // DO NOT hide the previous route instantly when done
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // How this route comes IN
            final slideIn = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
            final fadeIn = Tween<double>(begin: 0.0, end: 1.0)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

            // How this route behaves when another is pushed ON TOP of it
            final slideOut = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.08, 0))
                .animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic));
            final fadeOut = Tween<double>(begin: 1.0, end: 0.0)
                .animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic));

            return SlideTransition(
              position: slideOut,
              child: FadeTransition(
                opacity: fadeOut,
                child: SlideTransition(
                  position: slideIn,
                  child: FadeTransition(
                    opacity: fadeIn,
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
}
