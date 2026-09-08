import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Refined Core Palette ───
  static const Color black = Color(0xFF090A0F);
  static const Color white = Color(0xFFFFFFFF);
  
  // Light Palette
  static const Color lightBg = Color(0xFFF6F8FC);       // Soft architectural canvas
  static const Color lightCanvas = Color(0xFFF6F8FC);
  static const Color lightCard = Color(0xFFFFFFFF);     // Pure white card
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFFFFFFF);

  // Dark Palette (Obsidian & Deep Slate)
  static const Color darkBg = Color(0xFF0C0E14);         // Ultra-deep obsidian
  static const Color darkCanvas = Color(0xFF0C0E14);
  static const Color darkCard = Color(0xFF151823);       // Slate tinted card
  static const Color darkSurface = Color(0xFF151823);
  static const Color darkCardElevated = Color(0xFF1B2030); // Level 2 elevated card

  // ─── Primary Accent: Solar Orange ───
  static const Color orange = Color(0xFFFF6B35);         // Vibrant solar orange (primary CTA)
  static const Color orangeLight = Color(0xFFFFEDE6);    // Orange tint bg
  static const Color orangeGlow = Color(0x33FF6B35);     // Ambient glow

  // ─── Vibrant Palette (Badges, Chips, Accents) ───
  static const Color vibrantOrange = Color(0xFFFF6B35);
  static const Color vibrantBlue = Color(0xFF3B82F6);
  static const Color vibrantGreen = Color(0xFF10B981);
  static const Color vibrantPurple = Color(0xFF8B5CF6);
  static const Color vibrantRed = Color(0xFFEF4444);
  static const Color vibrantYellow = Color(0xFFF59E0B);
  static const Color primaryYellow = Color(0xFFFF6B35);   // Align legacy primaryYellow to signature orange

  // Alias
  static const Color accentBlack = black;
  static const Color primaryAccent = orange;

  // ─── Text Hierarchy ───
  static const Color textDark = Color(0xFF0F172A);       // High-contrast slate
  static const Color textLight = Color(0xFFF8FAFC);      // Bright crisp white
  static const Color textMutedDark = Color(0xFF94A3B8);  // Slate muted
  static const Color textMutedLight = Color(0xFF64748B); // Slate muted light
  static const Color textSubtleDark = Color(0xFF64748B);
  static const Color textSubtleLight = Color(0xFF94A3B8);

  // ─── Status Colors ───
  static const Color statusGreenText = vibrantGreen;
  static const Color statusAmberText = vibrantOrange;
  static const Color statusRedText = vibrantRed;
  static const Color statusGrayText = Color(0xFF6B7280);

  // ─── Borders ───
  static const Color borderDark = Color(0xFF262C3E);
  static const Color borderDarkSubtle = Color(0xFF1E2332);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderLightSubtle = Color(0xFFEDF2F7);

  // ─── Border Radius ───
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;
  static const double radiusPill = 100.0;

  // ─── Card Decoration ───
  static BoxDecoration cardDecoration(BuildContext context, {
    Color? color,
    double borderRadius = radiusLg,
    Color? borderColor,
    bool withShadow = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseTop = color ?? (isDark ? const Color(0xEE222A3B) : const Color(0xFAFFFFFF));
    final baseBottom = color ?? (isDark ? const Color(0xD8171E2D) : const Color(0xEEF8FAFC));

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [baseTop, baseBottom],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ??
            (isDark
                ? Colors.white.withValues(alpha: 0.11)
                : Colors.white.withValues(alpha: 0.85)),
        width: 1.1,
      ),
      boxShadow: withShadow
          ? [
              if (isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                )
              else
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ]
          : null,
    );
  }

  // Flat decoration without heavy shadows
  static BoxDecoration flatDecoration(BuildContext context, {
    Color? borderColor,
    double borderRadius = radiusLg,
    Color? color,
  }) => cardDecoration(
    context,
    color: color,
    borderRadius: borderRadius,
    borderColor: borderColor,
    withShadow: false,
  );

  // Dedicated Liquid Glass decoration with specular borders & ambient depth
  static BoxDecoration liquidGlassDecoration(
    BuildContext context, {
    double borderRadius = radiusLg,
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

    final border = isSelected && accentColor != null
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
      border: Border.all(color: border, width: isSelected ? 1.5 : 1.1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        if (accentColor != null)
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
      ],
    );
  }

  // Signature curved top hero "drop" decoration with Liquid Obsidian Glass
  static BoxDecoration heroDropDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF262E40), Color(0xFF1B212F)]
            : const [Color(0xFF1F232B), Color(0xFF101216)],
      ),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      border: Border(
        bottom: BorderSide(
          color: isDark ? const Color(0xFF3B465E) : Colors.black12,
          width: 1.5,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        if (isDark)
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
      ],
    );
  }

  // Smooth route transition designed for Hero top black drop morphing
  static PageRouteBuilder morphPageRoute({required Widget screen}) {
    return PageRouteBuilder(
      pageBuilder: (_, anim, secondaryAnim) => screen,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
          reverseCurve: Curves.easeInOutCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: child,
        );
      },
    );
  }

  // ─── Text Theme ───
  static TextTheme _buildTextTheme(Color main, Color muted) {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(color: main, fontWeight: FontWeight.w800, letterSpacing: -1.5, fontSize: 48),
      displayMedium: GoogleFonts.inter(color: main, fontWeight: FontWeight.w800, letterSpacing: -1, fontSize: 36),
      headlineLarge: GoogleFonts.inter(color: main, fontWeight: FontWeight.w800, letterSpacing: -0.5, fontSize: 28),
      headlineMedium: GoogleFonts.inter(color: main, fontWeight: FontWeight.w700, fontSize: 22),
      headlineSmall: GoogleFonts.inter(color: main, fontWeight: FontWeight.w700, fontSize: 18),
      titleLarge: GoogleFonts.inter(color: main, fontWeight: FontWeight.w700, fontSize: 17),
      titleMedium: GoogleFonts.inter(color: main, fontWeight: FontWeight.w600, fontSize: 15),
      bodyLarge: GoogleFonts.inter(color: main, fontSize: 16, height: 1.4),
      bodyMedium: GoogleFonts.inter(color: muted, fontSize: 14, height: 1.4),
      bodySmall: GoogleFonts.inter(color: muted, fontSize: 12),
      labelLarge: GoogleFonts.inter(color: main, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.2),
    );
  }

  // ─── ElevatedButton Style (Orange Pill) ───
  static ButtonStyle get orangeButton => ElevatedButton.styleFrom(
    backgroundColor: orange,
    foregroundColor: white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
  );

  // ─── Dark Theme ───
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkCanvas,
      primaryColor: orange,
      colorScheme: const ColorScheme.dark(
        primary: orange,
        secondary: white,
        surface: darkSurface,
        onSurface: textLight,
      ),
      textTheme: _buildTextTheme(textLight, textMutedDark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textLight),
        titleTextStyle: GoogleFonts.inter(color: textLight, fontWeight: FontWeight.w800, fontSize: 20),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderDark),
        ),
      ),
      dividerTheme: const DividerThemeData(color: borderDark, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(style: orangeButton),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? white : textMutedDark),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? orange : borderDark),
      ),
    );
  }

  // ─── Light Theme ───
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: orange,
      colorScheme: const ColorScheme.light(
        primary: orange,
        secondary: black,
        surface: lightSurface,
        onSurface: textDark,
      ),
      textTheme: _buildTextTheme(textDark, textMutedLight),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.inter(color: textDark, fontWeight: FontWeight.w800, fontSize: 20),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderLight),
        ),
      ),
      dividerTheme: const DividerThemeData(color: borderLight, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(style: orangeButton),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? white : textMutedLight),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? orange : borderLight),
      ),
    );
  }
}
