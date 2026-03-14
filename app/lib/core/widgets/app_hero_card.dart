import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// AppHeroCard: A card that expands into a full-screen page with a
/// smooth container-transform animation (Material Design "shared axis").
///
/// Wraps [OpenContainer] from the `animations` package to provide
/// a seamless card → detail transition without manual Hero tags.
///
/// Usage:
/// ```dart
/// AppHeroCard(
///   closedBuilder: (context) => EventCard(event),
///   openBuilder: (context) => EventDetailScreen(eventId: event.id),
/// )
/// ```
///
/// With custom styling:
/// ```dart
/// AppHeroCard(
///   closedElevation: 2,
///   closedBorderRadius: 16,
///   transitionDuration: Duration(milliseconds: 400),
///   closedBuilder: (context) => MyCard(),
///   openBuilder: (context) => DetailScreen(),
/// )
/// ```
class AppHeroCard extends StatelessWidget {
  /// Builder for the closed (card) state.
  final Widget Function(BuildContext context) closedBuilder;

  /// Builder for the open (detail page) state.
  final Widget Function(BuildContext context) openBuilder;

  /// Elevation of the closed card. Defaults to 0.
  final double closedElevation;

  /// Elevation of the open page. Defaults to 0.
  final double openElevation;

  /// Border radius of the closed card. Defaults to 16.
  final double closedBorderRadius;

  /// Duration of the container transform animation.
  final Duration transitionDuration;

  /// Called when the container is closed (returned from detail).
  final VoidCallback? onClosed;

  /// Optional closed container color override.
  final Color? closedColor;

  /// Optional open container color override.
  final Color? openColor;

  /// Whether to use root navigator (for GoRouter compatibility).
  final bool useRootNavigator;

  /// The type of fade transition to use.
  final ContainerTransitionType transitionType;

  const AppHeroCard({
    super.key,
    required this.closedBuilder,
    required this.openBuilder,
    this.closedElevation = 0,
    this.openElevation = 0,
    this.closedBorderRadius = 16,
    this.transitionDuration = const Duration(milliseconds: 450),
    this.onClosed,
    this.closedColor,
    this.openColor,
    this.useRootNavigator = true,
    this.transitionType = ContainerTransitionType.fadeThrough,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return OpenContainer(
      transitionDuration: transitionDuration,
      transitionType: transitionType,
      useRootNavigator: useRootNavigator,
      openElevation: openElevation,
      closedElevation: closedElevation,
      closedColor: closedColor ?? cs.surfaceContainer,
      openColor: openColor ?? cs.surface,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(closedBorderRadius),
      ),
      openShape: const RoundedRectangleBorder(),
      onClosed: onClosed != null ? (_) => onClosed!() : null,
      closedBuilder: (context, openContainer) {
        return _ClosedWrapper(
          onTap: openContainer,
          child: closedBuilder(context),
        );
      },
      openBuilder: (context, closeContainer) {
        return openBuilder(context);
      },
    );
  }
}

/// Wraps the closed card to make it tappable with ripple effect.
class _ClosedWrapper extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _ClosedWrapper({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: child,
    );
  }
}

/// AppHeroFAB: A Floating Action Button that expands into a full-screen page.
///
/// Great for "create new" flows where the FAB transforms into a form.
///
/// Usage:
/// ```dart
/// AppHeroFAB(
///   icon: Icons.add,
///   openBuilder: (context) => CreateEventScreen(),
/// )
/// ```
class AppHeroFAB extends StatelessWidget {
  final IconData icon;
  final Widget Function(BuildContext context) openBuilder;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;
  final double elevation;

  const AppHeroFAB({
    super.key,
    this.icon = Icons.add,
    required this.openBuilder,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
    this.elevation = 6,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 500),
      transitionType: ContainerTransitionType.fadeThrough,
      useRootNavigator: true,
      closedElevation: elevation,
      openElevation: 0,
      closedColor: backgroundColor ?? cs.primaryContainer,
      openColor: cs.surface,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      closedBuilder: (context, openContainer) {
        return SizedBox(
          width: 56,
          height: 56,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: openContainer,
              customBorder: const CircleBorder(),
              child: Tooltip(
                message: tooltip ?? '',
                child: Icon(
                  icon,
                  color: iconColor ?? cs.onPrimaryContainer,
                ),
              ),
            ),
          ),
        );
      },
      openBuilder: (context, closeContainer) {
        return openBuilder(context);
      },
    );
  }
}
