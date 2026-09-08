import 'package:flutter/material.dart';

/// The Career Copilot logo — White-based logo with orange/yellow accents.
/// - On dark surfaces: shows cleanly with optional soft warm aura glow.
/// - On light surfaces (when [onLight] is true): wrapped in a sleek dark pill
///   (Color(0xFF0C1017)) so the white text and emblem pop sharply.
/// - [emblemOnly]: if true, shows the square icon emblem without text.
class AppLogo extends StatelessWidget {
  final double? size;
  final double? width;
  final double? height;
  final bool? onDark;
  final bool onLight;
  final bool emblemOnly;

  const AppLogo({
    super.key,
    this.size,
    this.width,
    this.height,
    this.onDark,
    this.onLight = false,
    this.emblemOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveW = width ?? size ?? 48.0;
    final effectiveH = height ?? size ?? 48.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool effectiveOnDark = onDark ?? isDark;
    final bool needsDarkPill = onLight || !effectiveOnDark;

    final image = Image.asset(
      emblemOnly ? 'assets/images/app_logo_emblem.png' : 'assets/images/app_logo.png',
      width: effectiveW,
      height: effectiveH,
      fit: BoxFit.contain,
    );

    if (needsDarkPill) {
      return Container(
        width: effectiveW,
        height: effectiveH,
        decoration: BoxDecoration(
          color: const Color(0xFF0C1017),
          borderRadius: BorderRadius.circular(effectiveH * 0.28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(effectiveH * 0.12),
        child: image,
      );
    }

    return SizedBox(
      width: effectiveW,
      height: effectiveH,
      child: image,
    );
  }
}
