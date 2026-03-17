import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool forceBackButton;
  final VoidCallback? onBackButtonPressed;
  final PreferredSizeWidget? bottom;
  final double elevation;
  final Color? backgroundColor;
  final bool centerTitle;

  const AppAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.forceBackButton = false,
    this.onBackButtonPressed,
    this.bottom,
    this.elevation = 0,
    this.backgroundColor,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool canPop = context.canPop();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    Widget? activeLeading = leading;
    // Intercept standard leading back actions to use our custom button
    if (activeLeading == null && (forceBackButton || (automaticallyImplyLeading && canPop))) {
      activeLeading = Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 16, color: cs.onSurface),
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: onBackButtonPressed ?? () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/hub');
            }
          },
        ),
      );
    } else if (activeLeading != null) {
      // Wrap standard leading icons to fit the aesthetic if they aren't completely custom
      activeLeading = Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: activeLeading,
      );
    }

    return AppBar(
      title: title,
      centerTitle: centerTitle,
      actions: actions != null
          ? [
              ...actions!.map((action) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: action,
                  )),
              const SizedBox(width: 8),
            ]
          : null,
      leading: activeLeading,
      automaticallyImplyLeading: false, // Handled manually
      bottom: bottom,
      elevation: elevation,
      backgroundColor: backgroundColor ?? cs.surface,
      surfaceTintColor: Colors.transparent,
      titleSpacing: activeLeading == null ? 24 : 8,
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      shape: Border(
        bottom: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
