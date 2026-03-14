import 'package:flutter/material.dart';
import 'app_cached_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// AppProtocolRow: Custom premium row for multi-column tables (Protocols, Standings)
///
/// Table mode: Columns with constrained widths to prevent excessive stretching.
/// Card mode:  Compact mobile-friendly card layout.
class AppProtocolRow extends StatelessWidget {
  final int? place;
  final String? placeText;
  final String bib;
  final String name;
  final String cat;
  final String dog;
  final String time;
  final String delta;
  final String penalty;
  final String? avatarUrl;
  final bool isHeader;
  final bool isCardView;
  final VoidCallback? onTap;

  const AppProtocolRow({
    super.key,
    this.place,
    this.placeText,
    required this.bib,
    required this.name,
    required this.cat,
    required this.dog,
    required this.time,
    required this.delta,
    required this.penalty,
    this.avatarUrl,
    this.isHeader = false,
    this.isCardView = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDnf = placeText == 'DNF' || placeText == 'DNS' || placeText == 'DSQ';

    Widget content = Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isHeader ? 12 : (isCardView ? 14 : 16)),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: isCardView ? _buildCardView(theme, cs, isDnf) : _buildTableView(theme, cs, isDnf),
    );

    if (onTap != null && !isHeader) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }

  Widget _buildCardView(ThemeData theme, ColorScheme cs, bool isDnf) {
    if (isHeader) return const SizedBox.shrink(); // Hide header in card mode
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 32, child: _placeWidget(theme, cs)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(4)),
              child: Text(bib, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
            ),
            const SizedBox(width: 8),
            if (!isHeader) ...[
              _avatarWidget(theme, cs, place),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: isDnf ? cs.onSurfaceVariant : cs.onSurface))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cat.startsWith('Ж') ? cs.errorContainer.withValues(alpha: 0.25) : cs.primaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(cat, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, fontWeight: FontWeight.bold, color: cat.startsWith('Ж') ? cs.error : cs.primary)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.pets, size: 12, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(child: Text(dog, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, overflow: TextOverflow.ellipsis))),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (penalty != '—') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: cs.tertiaryContainer.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)),
                child: Text('Штр: $penalty', style: theme.textTheme.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: cs.tertiary)),
              ),
              const SizedBox(width: 6),
            ],
            if (delta != '—') Text('Δ $delta', style: AppTypography.monoTiming.copyWith(color: cs.onSurfaceVariant, fontSize: 12)),
            const Spacer(),
            Text(time, style: AppTypography.monoTiming.copyWith(fontWeight: FontWeight.bold, fontSize: 16, color: place == 1 ? cs.primary : (isDnf ? cs.error : cs.onSurface))),
          ],
        ),
      ],
    );
  }

  Widget _buildTableView(ThemeData theme, ColorScheme cs, bool isDnf) {
    return Row(
      children: [
        // #  — fixed 44px
        SizedBox(width: 44, child: Center(child: isHeader ? _headerText('#', theme, cs) : _placeWidget(theme, cs))),
        // BIB — fixed 44px
        SizedBox(width: 44, child: isHeader ? _headerText('BIB', theme, cs) : Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
          child: Text(bib, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant), textAlign: TextAlign.center),
        )),
        const SizedBox(width: 12),
        // Avatar — fixed 36px (ALWAYS present, even in header for alignment)
        SizedBox(
          width: 36,
          child: isHeader
              ? const SizedBox.shrink() // Empty space to maintain column alignment
              : _avatarWidget(theme, cs, place),
        ),
        const SizedBox(width: 8),
        // Name — constrained: flex 2, maxWidth 200
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: SizedBox(
            width: 200,
            child: isHeader
                ? _headerText('Спортсмен', theme, cs)
                : Text(
                    name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: (place != null && place! <= 3) ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                      color: isDnf ? cs.onSurfaceVariant : cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ),
        const SizedBox(width: 8),
        // Category — fixed 70px
        SizedBox(
          width: 70,
          child: isHeader
              ? _headerText('КАТ.', theme, cs)
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cat.startsWith('Ж') ? cs.errorContainer.withValues(alpha: 0.25) : cs.primaryContainer.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(cat, style: theme.textTheme.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: cat.startsWith('Ж') ? cs.error : cs.primary)),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        // Dog — constrained: maxWidth 160
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: SizedBox(
            width: 160,
            child: isHeader
                ? _headerText('Собака', theme, cs)
                : Text(dog, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, overflow: TextOverflow.ellipsis), maxLines: 1),
          ),
        ),
        const SizedBox(width: 8),
        // Time — fixed 80px
        SizedBox(width: 80, child: isHeader ? _headerText('Время', theme, cs) : Text(time, style: AppTypography.monoTiming.copyWith(fontWeight: FontWeight.bold, fontSize: 14, color: place == 1 ? cs.primary : (isDnf ? cs.error : cs.onSurface)))),
        const SizedBox(width: 8),
        // Delta — fixed 60px
        SizedBox(width: 60, child: isHeader ? _headerText('Δ', theme, cs) : Text(delta, style: AppTypography.monoTiming.copyWith(color: cs.onSurfaceVariant, fontSize: 12))),
        const SizedBox(width: 8),
        // Penalty — fixed 50px
        SizedBox(width: 50, child: isHeader ? _headerText('Штр.', theme, cs) : Text(penalty, style: theme.textTheme.labelMedium?.copyWith(color: penalty != '—' ? cs.tertiary : cs.outline, fontSize: 12, fontWeight: penalty != '—' ? FontWeight.bold : FontWeight.normal))),
      ],
    );
  }

  Widget _headerText(String text, ThemeData theme, ColorScheme cs) {
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.bold, 
        color: cs.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _placeWidget(ThemeData theme, ColorScheme cs) {
    if (placeText != null && place == null) {
      final isError = placeText == 'DNF' || placeText == 'DNS' || placeText == 'DSQ';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isError ? cs.errorContainer.withValues(alpha: 0.25) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
          border: isError ? Border.all(color: cs.error.withValues(alpha: 0.2)) : null,
        ),
        child: Text(
          placeText!,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isError ? cs.error : cs.onSurfaceVariant,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Text('${place ?? '-'}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onSurfaceVariant));
  }

  Widget _avatarWidget(ThemeData theme, ColorScheme cs, int? place) {
    Color? borderColor;
    if (place == 1) borderColor = AppColors.gold;
    else if (place == 2) borderColor = AppColors.silver;
    else if (place == 3) borderColor = AppColors.bronze;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primaryContainer.withValues(alpha: 0.5),
        border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? AppCachedImage(url: avatarUrl!, fit: BoxFit.cover, width: 28, height: 28)
            : Center(
                child: Text(
                  name.isNotEmpty ? name.characters.first : '?',
                  style: theme.textTheme.labelMedium?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }
}
