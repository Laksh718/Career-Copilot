import 'package:flutter/material.dart';
import 'liquid_glass.dart';

/// Backwards-compatible GlassCard upgraded to genuine Liquid Glass UI
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? accentColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.width,
    this.height,
    this.borderRadius = 22,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      width: width,
      height: height,
      padding: padding,
      borderRadius: borderRadius,
      accentColor: accentColor,
      onTap: onTap,
      child: child,
    );
  }
}
