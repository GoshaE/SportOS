import 'package:flutter/material.dart';

/// AppButton: Standardized buttons across the application
class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final bool isPrimary;
  final bool isDanger;
  final bool isSecondary;
  final bool isLoading;
  final double? width;
  final double height;
  final Color? backgroundColor;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isPrimary = false,
    this.isDanger = false,
    this.isSecondary = false,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 56,
    this.backgroundColor,
  });

  /// Factory for the main call to action
  factory AppButton.primary({required String text, VoidCallback? onPressed, IconData? icon, bool isLoading = false, Color? backgroundColor, double? width = double.infinity}) {
    return AppButton(text: text, onPressed: onPressed, isPrimary: true, icon: icon, isLoading: isLoading, backgroundColor: backgroundColor, width: width);
  }

  /// Factory for secondary / outlined actions
  factory AppButton.secondary({required String text, VoidCallback? onPressed, IconData? icon, bool isLoading = false, double? width = double.infinity}) {
    return AppButton(text: text, onPressed: onPressed, isSecondary: true, icon: icon, isLoading: isLoading, width: width);
  }

  /// Factory for destructive actions
  factory AppButton.danger({required String text, VoidCallback? onPressed, IconData? icon, bool isLoading = false, double? width = double.infinity}) {
    return AppButton(text: text, onPressed: onPressed, isDanger: true, icon: icon, isLoading: isLoading, width: width);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (isSecondary) {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.primary,
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3), width: 1),
            shape: const StadiumBorder(), // Pill shape
          ),
          onPressed: isLoading ? null : onPressed,
          icon: _buildIcon(cs),
          label: _buildText(context),
        ),
      );
    }

    // Default to Filled
    Color bgColor = backgroundColor ?? cs.primary;
    if (isDanger) bgColor = cs.error;
    if (onPressed == null) bgColor = cs.onSurface.withValues(alpha: 0.12);

    return SizedBox(
      width: width,
      height: height,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: cs.onPrimary,
          shape: const StadiumBorder(), // Pill shape
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed,
        icon: _buildIcon(cs),
        label: _buildText(context),
      ),
    );
  }

  Widget _buildIcon(ColorScheme cs) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
      );
    }
    if (icon == null) return const SizedBox.shrink();
    return Icon(icon, size: 24);
  }

  Widget _buildText(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
