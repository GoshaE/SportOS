import 'package:flutter/material.dart';

/// AppGradientOverlay: Dark gradient over images for text readability.
///
/// Used in hero-mode cards (EventCard, ClubCard → EntityCard).
/// Prevents duplicating the same gradient definition across cards.
///
/// Usage:
/// ```dart
/// Stack(children: [
///   Image(...),
///   const AppGradientOverlay(),
///   Positioned(bottom: 16, child: Text(...)),
/// ])
/// ```
class AppGradientOverlay extends StatelessWidget {
  /// Gradient direction.
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  /// Gradient strength (0.0–1.0). Default 0.85.
  final double maxOpacity;

  const AppGradientOverlay({
    super.key,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
    this.maxOpacity = 0.85,
  });

  /// Bottom-to-top gradient (default for hero cards).
  const AppGradientOverlay.bottomUp({
    super.key,
    this.maxOpacity = 0.85,
  })  : begin = Alignment.bottomCenter,
        end = const Alignment(0, -0.2);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(maxOpacity * 0.12),
              Colors.black.withOpacity(maxOpacity * 0.82),
              Colors.black.withOpacity(maxOpacity),
            ],
            stops: const [0.0, 0.4, 0.75, 1.0],
          ),
        ),
      ),
    );
  }
}
