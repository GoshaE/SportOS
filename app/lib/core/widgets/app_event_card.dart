import 'package:flutter/material.dart';
import 'app_cached_image.dart';

/// Event status for card display
enum EventCardStatus {
  upcoming,   // Blue — предстоит
  live,       // Red — LIVE
  completed,  // Green — завершён
  draft,      // Grey — черновик
}

/// AppEventCard: Unified event card for feed, my_events, series, club_profile.
///
/// Supports two presentation modes:
/// 1. Hero Mode (EventCardMode.hero): Large background image, blur gradient, 
///    glass status badge. Used for Home/Feed to create a wow-effect.
/// 2. Bento Mode (EventCardMode.bento): Compact glass card with structured info
///    chips. Used for lists, my events, series where structure is important.
///
/// Usage:
/// ```dart
/// AppEventCard(
///   title: 'Кубок Урала 2026',
///   subtitle: '15 марта · Екатеринбург',
///   sport: '🐕 Ездовой',
///   status: EventCardStatus.upcoming,
///   mode: EventCardMode.hero, // or EventCardMode.bento
///   imageUrl: 'https://...', // Required for hero mode
///   onTap: () => context.push('/hub/event/evt-1'),
/// )
/// ```

enum EventCardMode {
  hero,
  bento,
}

class AppEventCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? sport;
  final EventCardStatus status;
  final String? badge;
  final Widget? leading;
  final VoidCallback? onTap;
  final Color? accentColor;
  final EventCardMode mode;
  final String? imageUrl;
  final String? slotsText; // e.g. "48 / 60 мест"
  final double? slotsProgress; // e.g. 0.8
  final String? heroTag;

  const AppEventCard({
    super.key,
    required this.title,
    this.subtitle,
    this.sport,
    this.status = EventCardStatus.upcoming,
    this.badge,
    this.leading,
    this.onTap,
    this.accentColor,
    this.mode = EventCardMode.bento,
    this.imageUrl,
    this.slotsText,
    this.slotsProgress,
    this.heroTag,
  });

  Color _statusColor(ColorScheme cs) => accentColor ?? switch (status) {
    EventCardStatus.upcoming  => cs.primary,
    EventCardStatus.live      => cs.error,
    EventCardStatus.completed => cs.primaryContainer,
    EventCardStatus.draft     => cs.onSurfaceVariant,
  };

  (Color, Color) _statusColors(ColorScheme cs) {
    if (status == EventCardStatus.draft) return (cs.surfaceContainerHighest, cs.onSurfaceVariant);

    final bg = switch (status) {
      EventCardStatus.upcoming => cs.primary,
      EventCardStatus.live => cs.error,
      EventCardStatus.completed => cs.primaryContainer,
      _ => cs.surfaceContainerHighest,
    };
    return (bg, cs.onPrimary);
  }

  String _statusLabel() => switch (status) {
    EventCardStatus.upcoming  => 'Предстоит',
    EventCardStatus.live      => 'LIVE',
    EventCardStatus.completed => 'Завершён',
    EventCardStatus.draft     => 'Черновик',
  };

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case EventCardMode.hero:
        return _buildHeroMode(context);
      case EventCardMode.bento:
        return _buildBentoMode(context);
    }
  }

  // ════════════════════════════════════════════
  // Bento Mode (Compact List View)
  // ════════════════════════════════════════════
  Widget _buildBentoMode(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fgBg = _statusColors(cs);
    final solidBg = fgBg.$1;
    final solidFg = fgBg.$2;

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
                border: Border(left: BorderSide(color: solidBg, width: 4)), // Accent line
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Leading + Title + Status Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: 12),
                        ],
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
                              if (subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                              ]
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                         Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: solidBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _statusLabel(),
                                style: theme.textTheme.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: solidFg),
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(height: 4),
                              Text(badge!, style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ],
                    ),
                    
                    // Bottom Row: Chips (Sport, Slots)
                    if (sport != null || slotsText != null) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (sport != null) _buildInfoChip(context, Icons.directions_run, sport!),
                          if (slotsText != null) _buildSlotsChip(context),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildSlotsChip(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(slotsText!, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: cs.onSurfaceVariant)),
          if (slotsProgress != null) ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 30,
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: slotsProgress,
                  backgroundColor: cs.outlineVariant.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(slotsProgress! >= 1.0 ? cs.error : cs.primary),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  // Hero Mode (Large image + gradient)
  // ════════════════════════════════════════════
  Widget _buildHeroMode(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _statusColor(cs);
    final isError = color == cs.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Image
              if (imageUrl != null)
                heroTag != null
                    ? Hero(
                        tag: heroTag!,
                        child: AppCachedImage(
                          url: imageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : AppCachedImage(
                        url: imageUrl!,
                        fit: BoxFit.cover,
                      )
              else
                Container(color: cs.surfaceContainerHighest), // Fallback

              // 2. Dark Gradient for text readability (no blur to keep image crisp)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                    stops: const [0.0, 0.4, 0.75, 1.0],
                  ),
                ),
              ),

              // 3. Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Status Badge (Top-ish, but aligned with text)
                    if (badge != null || true) // Always show status in Hero mode
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color, // Solid color
                          borderRadius: BorderRadius.circular(6), // RoundedSquare
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4), // Generic shadow for depth
                          ]
                        ),
                        child: Text(
                          badge ?? _statusLabel(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isError ? Colors.white : cs.onPrimary, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
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
                    
                    // Subtitle & Sport
                    Row(
                      children: [
                        if (subtitle != null) ...[
                          Icon(Icons.calendar_today, size: 12, color: Colors.white.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              subtitle!, 
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (sport != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.directions_run, size: 12, color: Colors.white.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(
                            sport!, 
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              
              // 4. Arrow icon in top right
               Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
