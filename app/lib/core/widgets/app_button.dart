import 'package:flutter/material.dart';

/// Button size presets.
enum AppButtonSize {
  /// Full-width CTA (56px height, pill shape, full width).
  normal,

  /// Compact inline button (36px height, pill shape, shrink-wrap).
  small,
}

/// AppButton: Unified button component for the entire application.
///
/// Covers ALL button use-cases — from full-width CTA to inline actions.
///
/// ## Factories
///
/// | Factory | Use case | Size |
/// |---|---|---|
/// | `.primary()` | Main CTA: «Сохранить», «Далее» | normal (full-width) |
/// | `.secondary()` | Alt CTA: «Назад», «Сбросить» | normal (full-width) |
/// | `.danger()` | Destructive: «Удалить» | normal (full-width) |
/// | `.small()` | Inline filled: «+ Добавить», «Штраф» | small (shrink) |
/// | `.smallSecondary()` | Inline outlined: «Изменить», «Скопировать» | small (shrink) |
/// | `.smallDanger()` | Inline destructive: «Убрать» | small (shrink) |
/// | `.text()` | Text link: «Отмена», «Очистить» | auto (shrink) |
///
/// ## Examples
///
/// ```dart
/// AppButton.primary(text: 'Сохранить', onPressed: _save)
/// AppButton.small(text: '+ Добавить', icon: Icons.add, onPressed: _add)
/// AppButton.text(text: 'Отмена', onPressed: () => Navigator.pop(context))
/// ```
class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final _AppButtonVariant _variant;
  final AppButtonSize size;
  final bool isLoading;
  final double? width;
  final Color? backgroundColor;

  const AppButton._({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    _AppButtonVariant variant = _AppButtonVariant.filled,
    this.size = AppButtonSize.normal,
    this.isLoading = false,
    this.width,
    this.backgroundColor,
  }) : _variant = variant;

  /// Default constructor (filled, normal size, full-width).
  const AppButton({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    AppButtonSize size = AppButtonSize.normal,
    bool isLoading = false,
    double? width,
    Color? backgroundColor,
  }) : this._(
          key: key,
          text: text,
          onPressed: onPressed,
          icon: icon,
          size: size,
          isLoading: isLoading,
          width: width,
          backgroundColor: backgroundColor,
        );

  // ── Full-width CTA factories ──

  /// Main call to action (filled, full-width, 56px).
  factory AppButton.primary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    Color? backgroundColor,
    double? width = double.infinity,
  }) {
    return AppButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      icon: icon,
      variant: _AppButtonVariant.filled,
      size: AppButtonSize.normal,
      isLoading: isLoading,
      backgroundColor: backgroundColor,
      width: width,
    );
  }

  /// Secondary / outlined CTA (full-width, 56px).
  factory AppButton.secondary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width = double.infinity,
  }) {
    return AppButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      icon: icon,
      variant: _AppButtonVariant.outlined,
      size: AppButtonSize.normal,
      isLoading: isLoading,
      width: width,
    );
  }

  /// Destructive CTA (filled error, full-width, 56px).
  factory AppButton.danger({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width = double.infinity,
  }) {
    return AppButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      icon: icon,
      variant: _AppButtonVariant.danger,
      size: AppButtonSize.normal,
      isLoading: isLoading,
      width: width,
    );
  }

  // ── Compact inline factories ──

  /// Small filled inline button (36px, shrink-wrap).
  factory AppButton.small({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    Color? backgroundColor,
  }) {
    return AppButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      icon: icon,
      variant: _AppButtonVariant.filled,
      size: AppButtonSize.small,
      isLoading: isLoading,
      backgroundColor: backgroundColor,
    );
  }

  /// Small outlined inline button (36px, shrink-wrap).
  factory AppButton.smallSecondary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return AppButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      icon: icon,
      variant: _AppButtonVariant.outlined,
      size: AppButtonSize.small,
      isLoading: isLoading,
    );
  }

  /// Small danger inline button (36px, shrink-wrap).
  factory AppButton.smallDanger({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return AppButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      icon: icon,
      variant: _AppButtonVariant.danger,
      size: AppButtonSize.small,
      isLoading: isLoading,
    );
  }

  // ── Text button factory ──

  /// Text-only button — replaces raw TextButton.
  factory AppButton.text({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isDanger = false,
  }) {
    return AppButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      icon: icon,
      variant: isDanger ? _AppButtonVariant.textDanger : _AppButtonVariant.text,
      size: AppButtonSize.small,
      isLoading: isLoading,
    );
  }

  // ── Sizing constants ──

  double get _height => size == AppButtonSize.normal ? 56.0 : 36.0;
  double get _fontSize => size == AppButtonSize.normal ? 16.0 : 13.0;
  FontWeight get _fontWeight =>
      size == AppButtonSize.normal ? FontWeight.bold : FontWeight.w600;
  double get _iconSize => size == AppButtonSize.normal ? 22.0 : 18.0;
  double get _loaderSize => size == AppButtonSize.normal ? 20.0 : 16.0;

  EdgeInsetsGeometry get _padding => size == AppButtonSize.normal
      ? const EdgeInsets.symmetric(horizontal: 24, vertical: 14)
      : const EdgeInsets.symmetric(horizontal: 14, vertical: 6);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Resolve effective width
    final effectiveWidth =
        width ?? (size == AppButtonSize.normal ? double.infinity : null);

    Widget button;

    switch (_variant) {
      case _AppButtonVariant.filled:
        button = _buildFilled(cs, cs.primary, cs.onPrimary);
      case _AppButtonVariant.danger:
        button = _buildFilled(cs, cs.error, cs.onError);
      case _AppButtonVariant.outlined:
        button = _buildOutlined(cs);
      case _AppButtonVariant.text:
        button = _buildText(cs, cs.primary);
      case _AppButtonVariant.textDanger:
        button = _buildText(cs, cs.error);
    }

    if (effectiveWidth != null) {
      return SizedBox(width: effectiveWidth, height: _height, child: button);
    }
    return SizedBox(height: _height, child: button);
  }

  // ── Builders ──

  Widget _buildFilled(ColorScheme cs, Color bg, Color fg) {
    Color bgColor = backgroundColor ?? bg;
    if (onPressed == null) bgColor = cs.onSurface.withValues(alpha: 0.12);

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fg,
        shape: const StadiumBorder(),
        elevation: 0,
        padding: _padding,
        textStyle: TextStyle(fontSize: _fontSize, fontWeight: _fontWeight),
      ),
      onPressed: isLoading ? null : onPressed,
      icon: _buildIconWidget(fg),
      label: Text(text),
    );
  }

  Widget _buildOutlined(ColorScheme cs) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.primary,
        side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3), width: 1),
        shape: const StadiumBorder(),
        padding: _padding,
        textStyle: TextStyle(fontSize: _fontSize, fontWeight: _fontWeight),
      ),
      onPressed: isLoading ? null : onPressed,
      icon: _buildIconWidget(cs.primary),
      label: Text(text),
    );
  }

  Widget _buildText(ColorScheme cs, Color color) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: _padding,
        textStyle: TextStyle(fontSize: _fontSize, fontWeight: _fontWeight),
      ),
      onPressed: isLoading ? null : onPressed,
      icon: _buildIconWidget(color),
      label: Text(text),
    );
  }

  Widget _buildIconWidget(Color color) {
    if (isLoading) {
      return SizedBox(
        width: _loaderSize,
        height: _loaderSize,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    if (icon == null) return const SizedBox.shrink();
    return Icon(icon, size: _iconSize);
  }
}

enum _AppButtonVariant { filled, outlined, danger, text, textDanger }
