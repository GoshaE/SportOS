import 'package:flutter/material.dart';
import '../../core/widgets/app_cached_image.dart';

import '../atoms/app_gradient_overlay.dart';
import '../atoms/app_icon_label.dart';

/// Presentation mode.
enum EntityCardMode {
  hero,   // Large background image + gradient overlay
  bento,  // Compact with accent border + structured info
}

/// AppEntityCard: Universal card for any entity (Event, Club, Series, etc).
///
/// Replaces:
/// - `AppEventCard` (410 lines)
/// - `AppClubCard` (450 lines)
///
/// Both had identical hero/bento structure with different data.
/// Now one widget handles both via configurable slots.
///
/// Usage:
/// ```dart
/// // Event card (bento)
/// AppEntityCard(
///   title: 'Кубок Урала 2026',
///   subtitle: '15 марта · Екатеринбург',
///   statusBadge: AppChip.status('LIVE', type: ChipType.error),
///   infoChips: [
///     AppChip.icon(Icons.directions_run, 'Ездовой'),
///     AppChip.icon(Icons.people, '48/60'),
///   ],
///   onTap: () {},
/// )
///
/// // Club card (hero)
/// AppEntityCard(
///   mode: EntityCardMode.hero,
///   title: 'Гонки Севера',
///   subtitle: 'Мурманск · Ездовой спорт',
///   imageUrl: 'https://...',
///   avatar: CircleAvatar(...),
///   statusBadge: AppChip.status('Участник', type: ChipType.success),
///   onTap: () {},
/// )
/// ```
class AppEntityCard extends StatelessWidget {
  // ─── Core Data ──────────────────────────────────────────────
  final String title;
  final String? subtitle;
  final EntityCardMode mode;
  final VoidCallback? onTap;

  // ─── Visual Slots ───────────────────────────────────────────
  final String? imageUrl;       // Background (hero) or thumbnail (bento)
  final Widget? avatar;         // Leading avatar/logo (bento mode)
  final Widget? statusBadge;    // Top-right (bento) or top-left (hero)
  final List<Widget> infoChips; // Bottom row of info chips
  final Widget? secondaryBadge; // Below statusBadge (e.g. "3 заявки")
  final String? heroTag;        // For Hero animations
  final Color? accentColor;     // Left border in bento mode

  // ─── Hero-mode specific ─────────────────────────────────────
  final double heroHeight;

  const AppEntityCard({
    super.key,
    required this.title,
    this.subtitle,
    this.mode = EntityCardMode.bento,
    this.onTap,
    this.imageUrl,
    this.avatar,
    this.statusBadge,
    this.infoChips = const [],
    this.secondaryBadge,
    this.heroTag,
    this.accentColor,
    this.heroHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      EntityCardMode.hero  => _buildHero(context),
      EntityCardMode.bento => _buildBento(context),
    };
  }

  // ════════════════════════════════════════════════════════════
  // BENTO MODE — compact list card
  // ════════════════════════════════════════════════════════════

  Widget _buildBento(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = accentColor ?? cs.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accent, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: Avatar + Title + Badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (avatar != null) ...[
                      avatar!,
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status + Secondary badges
                    if (statusBadge != null || secondaryBadge != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ?statusBadge,
                          if (secondaryBadge != null) ...[
                            const SizedBox(height: 4),
                            secondaryBadge!,
                          ],
                        ],
                      ),
                  ],
                ),

                // Bottom: Info chips
                if (infoChips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: infoChips,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // HERO MODE — full image card
  // ════════════════════════════════════════════════════════════

  Widget _buildHero(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: heroHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background image
              _buildHeroImage(cs),

              // 2. Gradient overlay
              const AppGradientOverlay(),

              // 3. Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Status badge
                    if (statusBadge != null) ...[
                      statusBadge!,
                      const SizedBox(height: 8),
                    ],
                    // Title
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Subtitle + info
                    if (subtitle != null || infoChips.isNotEmpty)
                      Row(
                        children: [
                          if (subtitle != null) ...[
                            Expanded(
                              child: AppIconLabel(
                                Icons.calendar_today,
                                subtitle!,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                          ...infoChips.map((chip) => Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: chip,
                          )),
                        ],
                      ),
                  ],
                ),
              ),

              // 4. Arrow
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(ColorScheme cs) {
    Widget image;
    if (imageUrl != null) {
      image = AppCachedImage(url: imageUrl!, fit: BoxFit.cover);
    } else {
      image = Container(color: cs.surfaceContainerHighest);
    }

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: image);
    }
    return image;
  }
}
