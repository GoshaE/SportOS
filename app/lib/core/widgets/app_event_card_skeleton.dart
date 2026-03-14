import 'package:flutter/material.dart';
import 'app_shimmer.dart';

/// AppEventCardSkeleton: A solid shimmer skeleton for event loading states.
/// 
/// Matches the approximate layout of AppEventCard (Bento / Hero modes)
/// to provide a smooth perceived load without spinning rings.
class AppEventCardSkeleton extends StatelessWidget {
  final bool isHero;

  const AppEventCardSkeleton({super.key, this.isHero = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (isHero) {
      return Container(
        height: 250,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const AppShimmer(
          child: SizedBox.expand(),
        ),
      );
    }

    // Bento Mode default
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurfaceVariant.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar block skeleton
              AppShimmer.block(width: 60, height: 60, borderRadius: 16),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge skeleton
                    AppShimmer.block(width: 80, height: 24, borderRadius: 6),
                    const SizedBox(height: 8),
                    // Title skeleton (2 lines)
                    AppShimmer.block(height: 20),
                    const SizedBox(height: 4),
                    AppShimmer.block(width: 150, height: 20),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chips skeletons
          Row(
            children: [
              AppShimmer.block(width: 100, height: 32, borderRadius: 16),
              const SizedBox(width: 8),
              AppShimmer.block(width: 80, height: 32, borderRadius: 16),
            ],
          )
        ],
      ),
    );
  }
}
