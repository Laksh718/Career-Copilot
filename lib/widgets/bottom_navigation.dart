import 'dart:ui';
import 'package:flutter/material.dart';
import '../app/theme.dart';


/// Floating Liquid Glass Bottom Navigation Dock
/// Features:
/// - Frosted glass backdrop blur (sigma 20)
/// - Floating island dock with 26px squircle curvature
/// - Specular glass rim highlight
/// - Caustic ambient shadow
/// - Centered, hover-optimized symmetrical navigation items
/// - Elevated centered molten Liquid UI Add button with liquid reflection
class BottomNavigation extends StatelessWidget {
  static bool disableAnimationsForTest = false;
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SizedBox(
          height: 66,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // ── Floating Liquid Glass Dock Body ──
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? const [Color(0xEE222A3C), Color(0xD8161D2C)]
                              : const [Color(0xF4FFFFFF), Color(0xE8F0F4F9)],
                        ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.16)
                              : Colors.white.withValues(alpha: 0.90),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                            blurRadius: 24,
                            spreadRadius: 0,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: const Color(0xFFFF5722).withValues(alpha: isDark ? 0.08 : 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Specular Top Rim Reflection
                          Positioned(
                            top: 0,
                            left: 16,
                            right: 16,
                            height: 1.5,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: isDark ? 0.35 : 0.75),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Symmetrically spaced and vertically centered navigation destinations
                          Positioned.fill(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _NavItem(
                                    icon: Icons.home_rounded,
                                    label: 'Home',
                                    isSelected: currentIndex == 0,
                                    onTap: () => onTap(0),
                                  ),
                                ),
                                Expanded(
                                  child: _NavItem(
                                    icon: Icons.layers_rounded,
                                    label: 'Apps',
                                    isSelected: currentIndex == 1,
                                    onTap: () => onTap(1),
                                  ),
                                ),
                                Expanded(
                                  child: _NavItem(
                                    icon: Icons.alarm_rounded,
                                    label: 'Alarms',
                                    isSelected: currentIndex == 2,
                                    onTap: () => onTap(2),
                                  ),
                                ),
                                // Symmetrical center gap reserved for the floating Liquid Add button
                                const SizedBox(width: 48),
                                Expanded(
                                  child: _NavItem(
                                    icon: Icons.calendar_month_rounded,
                                    label: 'Events',
                                    isSelected: currentIndex == 4,
                                    onTap: () => onTap(4),
                                  ),
                                ),
                                Expanded(
                                  child: _NavItem(
                                    icon: Icons.chat_bubble_rounded,
                                    label: 'Chat',
                                    isSelected: currentIndex == 5,
                                    onTap: () => onTap(5),
                                  ),
                                ),
                                Expanded(
                                  child: _NavItem(
                                    icon: Icons.person_rounded,
                                    label: 'Profile',
                                    isSelected: currentIndex == 6,
                                    onTap: () => onTap(6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Elevated Centered Liquid UI Floating Add Button ──
              Positioned(
                top: -18,
                child: _LiquidAddButton(
                  isSelected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = AppTheme.orange;
    final inactiveColor = isDark ? AppTheme.textMutedDark : const Color(0xFF8B9CB2);

    final isSelected = widget.isSelected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: double.infinity,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.orange.withValues(alpha: isDark ? 0.22 : 0.14)
                        : (_isHovered
                            ? (isDark
                                ? Colors.white.withValues(alpha: 0.09)
                                : Colors.black.withValues(alpha: 0.05))
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.orange.withValues(alpha: isDark ? 0.45 : 0.35)
                          : (_isHovered
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.16)
                                  : Colors.black.withValues(alpha: 0.12))
                              : Colors.transparent),
                      width: 1,
                    ),
                  ),
                  child: AnimatedScale(
                    scale: _isHovered ? 1.10 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      widget.icon,
                      color: isSelected
                          ? activeColor
                          : (_isHovered
                              ? (isDark ? Colors.white : AppTheme.accentBlack)
                              : inactiveColor),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected
                          ? activeColor
                          : (_isHovered
                              ? (isDark ? Colors.white : AppTheme.accentBlack)
                              : inactiveColor),
                      fontSize: 9.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Liquid UI Floating Center Add Button
/// Features:
/// - Molten sunset magma gradient (amber -> vermilion -> neon magenta)
/// - Liquid specular reflection meniscus on top rim
/// - Dual-layer ambient liquid aura glowing shadow
/// - Tactile spring feedback on press
/// - Continuous fluid breathing pulse
class _LiquidAddButton extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _LiquidAddButton({
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LiquidAddButton> createState() => _LiquidAddButtonState();
}

class _LiquidAddButtonState extends State<_LiquidAddButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  late final AnimationController _entryController;
  late final Animation<double> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _slideAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    // Play once — slides up from inside the nav bar
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.90 : (_isHovered ? 1.06 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF8A00), // Molten liquid amber
                  Color(0xFFFF5252), // Liquid vermilion
                  Color(0xFFD946EF), // Liquid neon magenta
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: widget.isSelected ? 0.85 : 0.40),
                width: widget.isSelected ? 2.2 : 1.5,
              ),
              boxShadow: [
                // Deep molten liquid aura glow
                BoxShadow(
                  color: const Color(0xFFFF5722).withValues(alpha: isDark ? 0.55 : 0.40),
                  blurRadius: _isHovered ? 26 : 20,
                  spreadRadius: _isHovered ? 2 : 1,
                  offset: const Offset(0, 8),
                ),
                // Secondary liquid magenta backlight
                BoxShadow(
                  color: const Color(0xFFD946EF).withValues(alpha: isDark ? 0.35 : 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
                if (widget.isSelected || _isHovered)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.45),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Liquid Specular Highlight (Glossy curved meniscus sheen)
                  Positioned(
                    top: 2,
                    left: 6,
                    right: 6,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                          bottom: Radius.elliptical(26, 12),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.55),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Center Icon with soft optical shadow
                  const Icon(
                    Icons.add_rounded,
                    color: AppTheme.white,
                    size: 30,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (BottomNavigation.disableAnimationsForTest) {
      return content;
    }

    // One-shot slide from inside the nav bar — no repeat, no glow pulse
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        final slide = (1.0 - _slideAnim.value) * 64.0; // px offset from nav bar
        final opacity = _fadeAnim.value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, slide),
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: content,
    );
  }
}
