
import 'package:flutter/material.dart';

/// Bottom navigation bar — "Glass Full-Width"
/// Fully floating, strong glassmorphism, animated pill indicator.
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Add extra bottom padding relative to safe area
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final double safeBottom = bottomPadding > 0 ? bottomPadding : 16;

    return Container(
      padding: EdgeInsets.only(bottom: safeBottom, top: 12, left: 8, right: 8),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.onSurfaceVariant.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (i) {
              final isActive = i == currentIndex;
              return Expanded(
                child: _NavItem(
                  item: items[i],
                  isActive: isActive,
                  onTap: () => onTap(i),
                  activeColor: isDark ? cs.primary : cs.primary,
                  activeContainerColor: isDark 
                      ? cs.primary.withOpacity(0.2) 
                      : cs.primaryContainer.withOpacity(0.7),
                  inactiveColor: isDark 
                      ? Colors.white.withOpacity(0.4) 
                      : cs.onSurfaceVariant.withOpacity(0.6),
                ),
              );
            }),
          ),
    );
  }
}

class FloatingNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String? badge;
  final String? label;

  const FloatingNavItem({
    required this.icon,
    required this.activeIcon,
    this.badge,
    this.label,
  });
}

class _NavItem extends StatelessWidget {
  final FloatingNavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final Color activeContainerColor;
  final Color inactiveColor;

  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    required this.activeContainerColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        color: Colors.transparent, // Expand tap area
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 20 : 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isActive ? activeContainerColor : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) {
                      return ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      );
                    },
                    child: Icon(
                      isActive ? item.activeIcon : item.icon,
                      key: ValueKey(isActive),
                      color: isActive ? activeColor : inactiveColor,
                      size: isActive ? 26 : 24, // Noticeable size difference
                    ),
                  ),
                  // Badge
                  if (item.badge != null)
                    Positioned(
                      top: -4,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
                        ),
                        child: Text(
                          item.badge!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (item.label != null) ...[
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: isActive ? activeColor : inactiveColor,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: isActive ? 11 : 10,
                ),
                child: Text(item.label!),
              )
            ]
          ],
        ),
      ),
    );
  }
}

