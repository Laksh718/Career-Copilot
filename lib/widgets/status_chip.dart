import 'package:flutter/material.dart';
import '../models/application.dart';
import '../app/theme.dart';

class StatusChip extends StatelessWidget {
  final ApplicationStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color color, String label, IconData icon) = switch (status) {
      ApplicationStatus.applied => (AppTheme.vibrantBlue, 'Applied', Icons.send_rounded),
      ApplicationStatus.interview => (AppTheme.vibrantOrange, 'Interview', Icons.event_rounded),
      ApplicationStatus.actionRequired => (AppTheme.vibrantRed, 'Action Required', Icons.warning_rounded),
      ApplicationStatus.waiting => (AppTheme.vibrantPurple, 'Waiting', Icons.hourglass_empty_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}
