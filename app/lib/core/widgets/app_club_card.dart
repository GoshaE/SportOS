import 'package:flutter/material.dart';
import 'app_cached_image.dart';
import 'status_badge.dart';

/// Presentation modes for Club Cards
enum ClubCardMode {
  hero,  // Large background image, glassmorphic info (for featured clubs)
  bento, // Compact glass card with accent border (for lists)
}

/// AppClubCard: Unified club card for catalog, my clubs, and featured sections.
///
/// Supports two presentation modes:
/// 1. Hero Mode: Large cover image, blur gradient, prominent logo and glass badge.
///    Suitable for showcasing "Top Clubs" or "Featured".
/// 2. Bento Mode: Compact glass card with structured info chips.
///    Used for lists ("My Clubs", "All Clubs").
class AppClubCard extends StatelessWidget {
  final String title;
  final String location;
  final String sport;
  final String members;
  final String? role; // e.g. 'Владелец', 'Участник'
  final String? pendingLabel; // e.g. '3' for pending requests
  final String? fee; // e.g. 'Бесплатно'
  final String? logoUrl;
  final String? coverUrl;
  final BadgeType? roleBadgeType;
  final VoidCallback? onTap;
  final ClubCardMode mode;
  final String? heroTag;

  const AppClubCard({
    super.key,
    required this.title,
    required this.location,
    required this.sport,
    required this.members,
    this.role,
    this.pendingLabel,
    this.fee,
    this.logoUrl,
    this.coverUrl,
    this.roleBadgeType,
    this.onTap,
    this.mode = ClubCardMode.bento,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case ClubCardMode.hero:
        return _buildHeroMode(context);
      case ClubCardMode.bento:
        return _buildBentoMode(context);
    }
  }

  // ════════════════════════════════════════════
  // Bento Mode (Compact List View)
  // ════════════════════════════════════════════
  Widget _buildBentoMode(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    // Determine accent color based on user's role/badge
    final accentColor = switch (roleBadgeType) {
      BadgeType.success => cs.primary,
      BadgeType.warning => cs.tertiary,
      BadgeType.info => cs.secondary,
      BadgeType.error => cs.error,
      _ => cs.onSurfaceVariant.withValues(alpha: 0.5),
    };

    final hasPending = pendingLabel != null && pendingLabel != '0';

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
            border: Border(left: BorderSide(color: accentColor, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar / Logo
                if (heroTag != null)
                  Hero(
                    tag: heroTag!,
                    child: _buildAvatar(cs),
                  )
                else
                  _buildAvatar(cs),
                  
                const SizedBox(width: 12),
                
                // Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Location & Sport Row
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: cs.primary),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              location,
                              style: TextStyle(fontSize: 12, color: cs.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              sport,
                              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Members & Status/Fee Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildChip(
                            context, 
                            Icons.group, 
                            '$members участн.', 
                            cs.surfaceContainerHighest.withValues(alpha: 0.5), 
                            cs.onSurfaceVariant
                          ),
                          if (fee != null)
                            _buildChip(
                              context, 
                              Icons.payments_outlined, 
                              fee!, 
                              cs.surfaceContainerHighest.withValues(alpha: 0.5), 
                              cs.onSurfaceVariant
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Trailing Badges
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (role != null)
                      StatusBadge(
                        text: role!,
                        type: roleBadgeType ?? BadgeType.neutral,
                      ),
                    if (hasPending) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '$pendingLabel заяв.',
                          style: TextStyle(
                            color: cs.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // Hero Mode (Featured/Top View)
  // ════════════════════════════════════════════
  Widget _buildHeroMode(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    // Fallback image if coverUrl is missing
    final String safeImageUrl = coverUrl ?? logoUrl ?? 'assets/images/club1.jpeg';

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12, right: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 220,
          width: 280,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Image
              if (heroTag != null && coverUrl != null)
                Hero(
                  tag: 'cover-$heroTag',
                  child: AppCachedImage(url: safeImageUrl, fit: BoxFit.cover),
                )
              else
                AppCachedImage(url: safeImageUrl, fit: BoxFit.cover),

              // 2. Dark Gradient Overlay (Bottom to Top)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: const Alignment(0, -0.2), // Fades out slightly above middle
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // 3. Top Badges
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (role != null)
                      _buildGlassBadge(role!, roleBadgeType ?? BadgeType.neutral, cs),
                    if (fee != null)
                      _buildGlassBadge(fee!, BadgeType.neutral, cs, icon: Icons.payments_outlined),
                  ],
                ),
              ),

              // 4. Content (Logo, Title, Location)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Avatar
                    if (heroTag != null && logoUrl != null)
                      Hero(
                        tag: heroTag!,
                        child: _buildAvatar(cs, size: 56, outlineColor: Colors.white24),
                      )
                    else
                      _buildAvatar(cs, size: 56, outlineColor: Colors.white24),
                      
                    const SizedBox(width: 12),
                    
                    // Text blocks
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '$location · $sport',
                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // Helpers
  // ════════════════════════════════════════════

  Widget _buildAvatar(ColorScheme cs, {double size = 48, Color? outlineColor}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: outlineColor ?? cs.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        color: cs.surfaceContainerHighest,
        image: logoUrl != null
            ? DecorationImage(
                image: logoUrl!.startsWith('http') 
                    ? NetworkImage(logoUrl!) as ImageProvider
                    : AssetImage(logoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: logoUrl == null
          ? Center(
              child: Text(
                title.isNotEmpty ? title[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurfaceVariant,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label, Color bgColor, Color fgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fgColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBadge(String text, BadgeType type, ColorScheme cs, {IconData? icon}) {
    final (baseColor, iconColor) = switch (type) {
      BadgeType.success => (cs.primary.withValues(alpha: 0.2), cs.primaryContainer),
      BadgeType.warning => (cs.tertiary.withValues(alpha: 0.2), cs.tertiary),
      BadgeType.error   => (cs.error.withValues(alpha: 0.2), cs.errorContainer),
      BadgeType.info    => (cs.secondary.withValues(alpha: 0.2), cs.secondaryContainer),
      BadgeType.neutral => (Colors.black45, Colors.white70),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
