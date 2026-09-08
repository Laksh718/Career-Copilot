import 'package:flutter/material.dart';

/// The Career Copilot logo — black/orange/yellow on white,
/// so [onDark] inverts to white bg pill for visibility on dark surfaces.
class AppLogo extends StatelessWidget {
  final double size;
  final bool onDark;

  const AppLogo({
    super.key,
    this.size = 36,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onDark ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: onDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      padding: onDark ? EdgeInsets.all(size * 0.06) : EdgeInsets.zero,
      child: Image.asset(
        'assets/images/app_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
