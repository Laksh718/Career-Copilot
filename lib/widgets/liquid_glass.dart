import 'dart:ui';
import 'package:flutter/material.dart';

/// Premier Liquid Glass UI Container
/// Implements frosted backdrop blur, specular refraction sheen,
/// translucent glass gradients, and ambient liquid caustic glows.
class LiquidGlass extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tintColor;
  final Color? accentColor;
  final double opacity;
  final bool withSpecularHighlight;
  final VoidCallback? onTap;
  final Border? customBorder;
  final double? width;
  final double? height;

  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 22,
    this.blur = 16,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.tintColor,
    this.accentColor,
    this.opacity = 1.0,
    this.withSpecularHighlight = true,
    this.onTap,
    this.customBorder,
    this.width,
    this.height,
  });

  /// Static helper to produce a Liquid Glass BoxDecoration
  static BoxDecoration decoration(
    BuildContext context, {
    double borderRadius = 22,
    Color? accentColor,
    Color? tintColor,
    bool isSelected = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseTop = tintColor != null
        ? tintColor.withValues(alpha: isDark ? 0.35 : 0.25)
        : (isDark ? const Color(0xEE222A3B) : const Color(0xF7FFFFFF));

    final baseBottom = tintColor != null
        ? tintColor.withValues(alpha: isDark ? 0.20 : 0.12)
        : (isDark ? const Color(0xD8171E2D) : const Color(0xEEF3F7FA));

    final borderColor = isSelected && accentColor != null
        ? accentColor.withValues(alpha: isDark ? 0.75 : 0.65)
        : (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.85));

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [baseTop, baseBottom],
      ),
      border: Border.all(
        color: borderColor,
        width: isSelected ? 1.5 : 1.1,
      ),
      boxShadow: [
        // Ambient glass shadow
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        // Caustic glow if accent color supplied
        if (accentColor != null)
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
      ],
    );
  }

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: LiquidGlass.decoration(
            context,
            borderRadius: widget.borderRadius,
            accentColor: widget.accentColor,
            tintColor: widget.tintColor,
          ),
          child: Stack(
            children: [
              // Specular Top Sheen (simulates light refraction across curved top glass rim)
              if (widget.withSpecularHighlight)
                Positioned(
                  top: 0,
                  left: 8,
                  right: 8,
                  height: 1.5,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: isDark ? 0.35 : 0.70),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              widget.child,
            ],
          ),
        ),
      ),
    );

    if (widget.onTap == null) {
      return widget.margin != null
          ? Padding(padding: widget.margin!, child: content)
          : content;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap!();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.margin != null
            ? Padding(padding: widget.margin!, child: content)
            : content,
      ),
    );
  }
}
