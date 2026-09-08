import 'package:flutter/material.dart';
import '../app/theme.dart';

class StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final String? subtitle;
  final Color? color;
  final bool isHero;

  const StatisticCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.subtitle,
    this.color,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = color ?? AppTheme.orange;

    if (isHero) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: const BoxDecoration(
          color: AppTheme.black,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: const TextStyle(color: AppTheme.white, fontSize: 56, fontWeight: FontWeight.w800, letterSpacing: -2)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          if (subtitle != null) ...[
            const SizedBox(height: 16),
            Text(subtitle!, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          ],
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark,
            fontSize: 26, fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: accent)),
        ],
      ]),
    );
  }
}
