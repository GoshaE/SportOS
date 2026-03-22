import 'package:flutter/material.dart';

/// BIB tile state (visual style)
enum BibState {
  available,  // Active, tappable — bold primary border
  assigned,   // Already assigned — muted, check mark
  finished,   // Crossed out
  dns,        // Red, blocked
  current,    // Highlighted — accent background
  disabled,   // Not started yet — muted, non-interactive
}

/// AppBibTile: Grid tile showing a BIB number with status styling.
///
/// Replaces _bibTile, _finishedBibTile in finish_screen and BIB
/// displays in starter/dictator screens.
///
/// Usage:
/// ```dart
/// GridView.count(
///   crossAxisCount: 3,
///   children: [
///     AppBibTile(bib: '07', name: 'Петров', state: BibState.available, onTap: () {}),
///     AppBibTile(bib: '24', name: 'Иванов', state: BibState.finished),
///   ],
/// )
/// ```
class AppBibTile extends StatelessWidget {
  final String bib;
  final String? name;
  final String? lapInfo;
  final BibState state;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AppBibTile({
    super.key,
    required this.bib,
    this.name,
    this.lapInfo,
    this.state = BibState.available,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bgColor, textColor, borderColor, decoration, icon) = _style(cs);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: borderColor.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            if (icon != null)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(icon, size: 14, color: textColor.withValues(alpha: 0.6)),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (lapInfo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        lapInfo!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: textColor.withValues(alpha: 0.6), height: 1.0),
                      ),
                    ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      bib,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        decoration: decoration,
                      ),
                    ),
                  ),
                  if (name != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        name!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: textColor.withValues(alpha: 0.9)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color bg, Color text, Color border, TextDecoration?, IconData?) _style(ColorScheme cs) => switch (state) {
    BibState.available => (
      cs.primaryContainer.withValues(alpha: 0.2),
      cs.primary,
      cs.primary.withValues(alpha: 0.6),
      null,
      null,
    ),
    BibState.assigned => (
      cs.surfaceContainerHighest.withValues(alpha: 0.4),
      cs.onSurfaceVariant,
      cs.outlineVariant.withValues(alpha: 0.5),
      null,
      Icons.check_circle_outline,
    ),
    BibState.finished => (
      cs.surfaceContainerHighest.withValues(alpha: 0.6),
      cs.outline,
      cs.outlineVariant.withValues(alpha: 0.3),
      TextDecoration.lineThrough,
      Icons.done_all,
    ),
    BibState.dns => (
      cs.errorContainer.withValues(alpha: 0.15),
      cs.error,
      cs.error.withValues(alpha: 0.3),
      TextDecoration.lineThrough,
      Icons.block,
    ),
    BibState.current => (
      cs.tertiaryContainer.withValues(alpha: 0.3),
      cs.tertiary,
      cs.tertiary.withValues(alpha: 0.7),
      null,
      Icons.play_circle_outline,
    ),
    BibState.disabled => (
      cs.surfaceContainerHighest.withValues(alpha: 0.15),
      cs.outline.withValues(alpha: 0.5),
      cs.outlineVariant.withValues(alpha: 0.15),
      null,
      Icons.hourglass_empty,
    ),
  };
}
