import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';
import '../models/application.dart';

class UpcomingEventCard extends StatefulWidget {
  final Application application;
  final VoidCallback onTap;

  const UpcomingEventCard({
    super.key,
    required this.application,
    required this.onTap,
  });

  @override
  State<UpcomingEventCard> createState() => _UpcomingEventCardState();
}

class _UpcomingEventCardState extends State<UpcomingEventCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInterview = widget.application.status == ApplicationStatus.interview;
    final isActionRequired = widget.application.status == ApplicationStatus.actionRequired;
    final dateStr = isInterview ? widget.application.interviewDate : widget.application.deadline;
    final timeStr = isInterview ? widget.application.interviewTime : '';
    final accent = isInterview
        ? AppTheme.vibrantOrange
        : (isActionRequired ? AppTheme.vibrantRed : AppTheme.vibrantBlue);


    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              // Colored icon
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isInterview ? Icons.event_rounded : Icons.timer_rounded,
                  color: AppTheme.white, size: 22,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.05, duration: 1800.ms, curve: Curves.easeInOut),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isInterview ? 'INTERVIEW' : 'ACTION REQUIRED',
                      style: TextStyle(
                        color: accent, fontSize: 10,
                        fontWeight: FontWeight.w800, letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.application.company,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$dateStr${timeStr.isNotEmpty ? ' at $timeStr' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Orange arrow button
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_forward_ios_rounded, color: accent, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
