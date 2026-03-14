import 'package:flutter/material.dart';

/// AppCachedImage: Safe network image loader with error handling.
///
/// Prevents crashes from `NetworkImageLoadException` (404, timeout, etc.)
/// by showing a placeholder icon instead.
///
/// Usage:
/// ```dart
/// AppCachedImage(
///   url: 'https://example.com/photo.jpg',
///   width: 200,
///   height: 150,
///   fit: BoxFit.cover,
/// )
/// ```
class AppCachedImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;
  final double placeholderIconSize;
  final Color? placeholderColor;
  final Color? placeholderBackgroundColor;

  const AppCachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.image_outlined,
    this.placeholderIconSize = 32,
    this.placeholderColor,
    this.placeholderBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final placeholder = _buildPlaceholder(cs);

    if (url == null || url!.isEmpty) {
      return placeholder;
    }

    Widget image = url!.startsWith('http')
        ? Image.network(
            url!,
            width: width,
            height: height,
            fit: fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                width: width,
                height: height,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    color: cs.primary.withValues(alpha: 0.5),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => placeholder,
          )
        : Image.asset(
            url!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => placeholder,
          );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildPlaceholder(ColorScheme cs) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: placeholderBackgroundColor ?? cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          placeholderIcon,
          size: placeholderIconSize,
          color: placeholderColor ?? cs.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
