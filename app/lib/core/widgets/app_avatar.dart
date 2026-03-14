import 'package:flutter/material.dart';
import 'app_cached_image.dart';

/// AppAvatar: User/dog/entity avatar with initials fallback and optional edit badge.
///
/// Usage:
/// ```dart
/// AppAvatar(name: 'Александр Иванов', size: 88, editable: true, onEdit: ...)
/// AppAvatar(name: 'Рекс', imageUrl: 'https://...', size: 48)
/// ```
class AppAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool editable;
  final VoidCallback? onEdit;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
    this.editable = false,
    this.onEdit,
    this.backgroundColor,
  });

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final chars = trimmed.characters;
    final first = chars.first;
    if (!RegExp(r'\p{L}', unicode: true).hasMatch(first)) return first;
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].characters.first.toUpperCase();
    return '${parts[0].characters.first}${parts[1].characters.first}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? cs.primary.withValues(alpha: 0.15);
    final textColor = cs.primary;
    final fontSize = size * 0.35;

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? AppCachedImage(
              url: imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholderColor: cs.surfaceContainerHighest,
            )
          : Center(
              child: Text(
                _initials,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
              ),
            ),
    );

    if (!editable) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onEdit,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 2),
              ),
              child: Icon(
                Icons.camera_alt,
                size: size * 0.16,
                color: cs.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
