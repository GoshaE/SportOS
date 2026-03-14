import 'package:flutter/material.dart';

/// AppShimmer: A reusable, high-contrast skeleton loading effect.
/// 
/// Replaces spinning indicators with a solid, moving gradient
/// to indicate loading states, especially useful outdoors where
/// spinners might be hard to see.
class AppShimmer extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  /// A convenience constructor for a simple rectangular or circular block
  factory AppShimmer.block({
    Key? key,
    double? width,
    double? height,
    double borderRadius = 8.0,
  }) {
    return AppShimmer(
      key: key,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 16.0,
        decoration: BoxDecoration(
          color: Colors.white, // Needs a solid color for the shader to mask
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    // Default to high-contrast surface colors
    final base = widget.baseColor ?? cs.surfaceContainerHighest;
    final highlight = widget.highlightColor ?? cs.surfaceContainerHighest.withValues(alpha: 0.5); // A slightly lighter/darker variant

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.1, 0.5, 0.9],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}
