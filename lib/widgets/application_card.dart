import 'package:flutter/material.dart';
import '../models/application.dart';
import '../app/theme.dart';
import 'company_logo.dart';

class ApplicationCard extends StatefulWidget {
  final Application application;
  final VoidCallback onTap;

  const ApplicationCard({
    super.key,
    required this.application,
    required this.onTap,
  });

  @override
  State<ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<ApplicationCard> {
  bool _pressed = false;

  Color get _statusColor => switch (widget.application.status) {
    ApplicationStatus.applied => AppTheme.vibrantBlue,
    ApplicationStatus.interview => AppTheme.orange,
    ApplicationStatus.actionRequired => AppTheme.vibrantRed,
    ApplicationStatus.waiting => AppTheme.vibrantPurple,
  };

  String get _statusLabel => switch (widget.application.status) {
    ApplicationStatus.applied => 'Applied',
    ApplicationStatus.interview => 'Interview',
    ApplicationStatus.actionRequired => 'Action Required',
    ApplicationStatus.waiting => 'Waiting',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = widget.application.category;
    final catColor = category.color;

    // Date info calculation
    final dateStr = widget.application.interviewDate.isNotEmpty
        ? widget.application.interviewDate
        : widget.application.deadline;
    final hasDate = dateStr.isNotEmpty;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xEE222A3B), Color(0xD8171E2D)]
                  : const [Color(0xFAFFFFFF), Color(0xEEF8FAFC)],
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.85),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: catColor.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company / Platform Logo with Category Badge
              CompanyLogoWidget(
                company: widget.application.company,
                category: category,
                size: 48,
                borderRadius: 15,
                showCategoryBadge: true,
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Tag & Badges Row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: catColor.withValues(alpha: 0.25), width: 0.8),
                          ),
                          child: Text(
                            category.shortLabel.toUpperCase(),
                            style: TextStyle(
                              color: catColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _statusLabel,
                            style: TextStyle(
                              color: _statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Organization / Company Name
                    Text(
                      widget.application.company,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Role / Track / Challenge Name
                    Text(
                      widget.application.role,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12.5,
                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (widget.application.stipend.isNotEmpty || widget.application.location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (widget.application.stipend.isNotEmpty) ...[
                            Icon(Icons.monetization_on_outlined, size: 12, color: catColor),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                widget.application.stipend,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: catColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (widget.application.location.isNotEmpty) ...[
                            Icon(Icons.location_on_outlined,
                                size: 12,
                                color: isDark ? AppTheme.textSubtleDark : AppTheme.textSubtleLight),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                widget.application.location,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppTheme.textSubtleDark : AppTheme.textSubtleLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Date info + arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasDate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCanvas : AppTheme.lightBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.application.interviewDate.isNotEmpty
                                ? Icons.event_rounded
                                : Icons.hourglass_top_rounded,
                            size: 11,
                            color: widget.application.interviewDate.isNotEmpty
                                ? AppTheme.orange
                                : AppTheme.vibrantBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateStr.length > 12 ? dateStr.substring(0, 12) : dateStr,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
