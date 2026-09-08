import 'package:flutter/material.dart';
import '../app/theme.dart';

class TexturedBackground extends StatelessWidget {
  final Widget child;
  final bool showGradients;
  final bool showDots;

  const TexturedBackground({
    super.key,
    required this.child,
    this.showGradients = true,
    this.showDots = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base Background Color with subtle gradient in light mode
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCanvas : null,
              gradient: isDark
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFCFDFF),
                        Color(0xFFF4F7FB),
                      ],
                    ),
            ),
          ),
        ),

        // Ambient Radiant Glows
        if (showGradients)
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  // Top-Right Ambient Warm Solar Glow
                  Positioned(
                    top: -100,
                    right: -90,
                    width: 420,
                    height: 420,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.orange.withValues(alpha: isDark ? 0.09 : 0.13),
                            AppTheme.orange.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top-Left Ambient Emerald Mint Glow (prominent in light mode)
                  Positioned(
                    top: -60,
                    left: -80,
                    width: 320,
                    height: 320,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF10B981).withValues(alpha: isDark ? 0.04 : 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom-Left Ambient Cool Indigo Glow
                  Positioned(
                    bottom: -80,
                    left: -80,
                    width: 380,
                    height: 380,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            (isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5))
                                .withValues(alpha: isDark ? 0.06 : 0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Architectural Micro-Dot Grid (tactile & prominent on light mode)
        if (showDots)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DotGridPainter(
                  dotColor: isDark
                      ? Colors.white.withValues(alpha: 0.045)
                      : const Color(0xFF1E293B).withValues(alpha: 0.095),
                  spacing: 22.0,
                  dotRadius: isDark ? 1.0 : 1.25,
                ),
              ),
            ),
          ),

        // Screen Content
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;
  final double dotRadius;

  _DotGridPainter({
    required this.dotColor,
    required this.spacing,
    required this.dotRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    final xCount = (size.width / spacing).ceil();
    final yCount = (size.height / spacing).ceil();

    for (int i = 0; i <= xCount; i++) {
      final x = i * spacing;
      for (int j = 0; j <= yCount; j++) {
        final y = j * spacing;
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.spacing != spacing ||
        oldDelegate.dotRadius != dotRadius;
  }
}
