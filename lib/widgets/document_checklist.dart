import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/required_document.dart';
import '../app/theme.dart';

class DocumentChecklist extends StatelessWidget {
  final List<RequiredDocument> documents;
  final Function(int, bool) onToggle;

  const DocumentChecklist({
    super.key,
    required this.documents,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) return const SizedBox.shrink();

    final completed = documents.where((d) => d.isCompleted).length;
    final progress = documents.isEmpty ? 0.0 : completed / documents.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description_outlined, color: AppTheme.primaryYellow, size: 20),
            const SizedBox(width: 8),
            Text(
              'Documents',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$completed / ${documents.length}',
                style: const TextStyle(
                  color: AppTheme.primaryYellow,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation(
                  progress == 1.0 ? AppTheme.statusGreenText : AppTheme.primaryYellow,
                ),
                minHeight: 4,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(documents.length, (index) {
          final doc = documents[index];
          return GestureDetector(
            onTap: () => onToggle(index, !doc.isCompleted),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: doc.isCompleted
                    ? AppTheme.primaryYellow.withValues(alpha: 0.08)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: doc.isCompleted
                      ? AppTheme.primaryYellow.withValues(alpha: 0.3)
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: doc.isCompleted ? AppTheme.primaryYellow : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: doc.isCompleted
                          ? null
                          : Border.all(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, width: 1.5),
                    ),
                    child: doc.isCompleted
                        ? const Icon(Icons.check_rounded, color: AppTheme.accentBlack, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      doc.name,
                      style: TextStyle(
                        color: doc.isCompleted ? Theme.of(context).textTheme.bodyMedium?.color : Theme.of(context).textTheme.bodySmall?.color,
                        decoration: doc.isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 15,
                        fontWeight: doc.isCompleted ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.1, end: 0);
        }),
      ],
    );
  }
}
