import 'package:flutter/material.dart';

import 'package:sportos_app/core/widgets/app_cached_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class PodiumAthlete {
  final int place;
  final String name;
  final String bib;
  final String time;
  final String dog;
  final String? delta;
  final String? avatarUrl;

  const PodiumAthlete({
    required this.place,
    required this.name,
    required this.bib,
    required this.time,
    required this.dog,
    this.delta,
    this.avatarUrl,
  });
}

class AppPodiumView extends StatelessWidget {
  final List<PodiumAthlete> athletes;
  
  const AppPodiumView({
    super.key,
    required this.athletes,
  });

  @override
  Widget build(BuildContext context) {
    if (athletes.isEmpty) return const SizedBox.shrink();

    // Sort to ensure we can pick by place
    final sorted = List<PodiumAthlete>.from(athletes)..sort((a, b) => a.place.compareTo(b.place));
    
    final gold = sorted.firstWhere((a) => a.place == 1, orElse: () => _empty(1));
    
    if (gold.name.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gold.withOpacity(0.15),
              cs.surfaceContainerHighest.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Hero Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 3),
                boxShadow: [
                  BoxShadow(color: AppColors.gold.withOpacity(0.4), blurRadius: 16, spreadRadius: 2),
                ]
              ),
              child: ClipOval(
                child: gold.avatarUrl != null
                    ? AppCachedImage(url: gold.avatarUrl!, fit: BoxFit.cover, width: 80, height: 80)
                    : Container(
                        color: cs.surfaceContainer, 
                        alignment: Alignment.center, 
                        child: Text(
                          gold.name.characters.first, 
                          style: theme.textTheme.displaySmall?.copyWith(color: AppColors.gold)
                        )
                      ),
              ),
            ),
            const SizedBox(width: 20),
            
            // Champion Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, color: AppColors.gold, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'ЧЕМПИОН',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.gold, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    gold.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                        ),
                        child: Text(
                          gold.time,
                          style: AppTypography.monoTiming.copyWith(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (gold.dog.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Container(width: 4, height: 4, decoration: BoxDecoration(color: cs.onSurfaceVariant.withOpacity(0.5), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Icon(Icons.pets, size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            gold.dog, 
                            style: theme.textTheme.titleSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PodiumAthlete _empty(int place) => PodiumAthlete(place: place, name: '', bib: '', time: '', dog: '');
}
