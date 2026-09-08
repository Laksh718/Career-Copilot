import 'package:flutter/material.dart';
import '../app/theme.dart';


class GradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  final EdgeInsetsGeometry? padding;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.padding,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isLoading && widget.onPressed != null) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (!widget.isLoading && widget.onPressed != null) {
          setState(() => _isPressed = false);
          widget.onPressed!();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightSurface : AppTheme.darkCanvas,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            boxShadow: [
              if (!_isPressed)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isLoading) ...[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCanvas : AppTheme.lightSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCanvas : AppTheme.lightSurface,
                    ),
                  ),
                  if (!widget.isLoading) ...[
                    const SizedBox(width: 8),
                    Icon(
                      widget.icon ?? Icons.arrow_forward_rounded,
                      size: 18,
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCanvas : AppTheme.lightSurface,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
