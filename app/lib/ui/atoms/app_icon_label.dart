import 'package:flutter/material.dart';

/// AppIconLabel: Icon + text pair — the most repeated pattern in SportOS.
///
/// Replaces 20+ inline Row(Icon, SizedBox, Text) across cards, panels, etc.
///
/// Usage:
/// ```dart
/// AppIconLabel(Icons.location_on, 'Екатеринбург')
/// AppIconLabel(Icons.pets, 'Rex', color: cs.primary, bold: true)
/// AppIconLabel.small(Icons.calendar_today, '15 марта')
/// ```
class AppIconLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final double iconSize;
  final double fontSize;
  final FontWeight fontWeight;
  final double gap;
  final int maxLines;
  final TextOverflow overflow;

  const AppIconLabel(
    this.icon,
    this.text, {
    super.key,
    this.color,
    this.iconSize = 14,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w400,
    this.gap = 4,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  /// Small variant — 10px, tight.
  factory AppIconLabel.small(IconData icon, String text, {Key? key, Color? color}) {
    return AppIconLabel(icon, text, key: key, color: color, iconSize: 12, fontSize: 10, gap: 3);
  }

  /// Bold variant — emphasized.
  factory AppIconLabel.bold(IconData icon, String text, {Key? key, Color? color}) {
    return AppIconLabel(icon, text, key: key, color: color, iconSize: 16, fontSize: 14, fontWeight: FontWeight.w700);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: resolvedColor),
        SizedBox(width: gap),
        Flexible(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: overflow,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: resolvedColor,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
