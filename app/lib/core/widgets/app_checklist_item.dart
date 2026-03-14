import 'package:flutter/material.dart';

/// A checklist item showing done/pending state with optional navigation.
/// Used in event_overview for prep checklists.
class AppChecklistItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool done;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AppChecklistItem({
    super.key,
    required this.title,
    this.subtitle,
    this.done = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? cs.primary : cs.tertiary,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: done ? TextDecoration.lineThrough : null,
            color: done ? cs.onSurfaceVariant : null,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: done ? cs.onSurfaceVariant : cs.tertiary,
                ),
              )
            : null,
        trailing: trailing ?? Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}
