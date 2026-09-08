import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../app/theme.dart';
import '../models/application.dart';
import '../models/career_extraction.dart';
import '../models/reminder.dart';
import '../models/required_document.dart';
import '../controllers/ai_controller.dart';
import '../controllers/application_controller.dart';
import '../controllers/reminder_controller.dart';
import '../screens/application_details/application_details_screen.dart';
import '../screens/splash_screen.dart';

class SharedIngestionService {
  static final SharedIngestionService _instance = SharedIngestionService._internal();
  factory SharedIngestionService() => _instance;
  SharedIngestionService._internal();

  /// Automatically parses shared text (from email, WhatsApp, or clipboard),
  /// creates an Application, saves it to the database, schedules alarms,
  /// Automatically parses shared text (from email, WhatsApp, or clipboard),
  /// creates an Application, saves it to the database, schedules alarms,
  /// and directly opens the ApplicationDetailsScreen (no splash screen, no intermediate modal).
  Future<Application?> processAndAutoAdd(
    BuildContext context,
    String rawText, {
    String sourceName = 'Shared Message / Email',
    bool replaceRoute = false,
  }) async {
    if (rawText.trim().isEmpty) return null;

    // Suppress any pending splash screen navigation
    SplashScreen.cancelNavigation = true;

    // Show parsing indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E2638) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        color: AppTheme.orange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Auto-Ingesting Opportunity',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Extracting company, role, deadline, and scheduling alarms...',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final aiController = context.read<AIController>();
      final extraction = await aiController.analyzeMessage(rawText);

      // Dismiss parsing dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      final app = _buildApplicationFromExtraction(extraction, rawText, sourceName);

      if (context.mounted) {
        // Automatically add to pipeline
        context.read<ApplicationController>().addApplication(app);

        // Automatically schedule an alarm/reminder if interview or deadline is present
        _autoScheduleAlarmIfApplicable(context, app);

        // Direct navigation to Application Details Screen (no splash, no modal)
        final route = MaterialPageRoute(
          builder: (_) => ApplicationDetailsScreen(application: app),
        );
        if (replaceRoute) {
          Navigator.pushReplacement(context, route);
        } else {
          Navigator.push(context, route);
        }

        // Show floating celebration snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Auto-ingested ${app.company} (${app.role}) into your pipeline!'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }

      return app;
    } catch (e) {
      debugPrint('Error auto-ingesting shared message: $e');
      if (context.mounted) {
        Navigator.pop(context); // Dismiss dialog on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not auto-ingest shared text: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  Application _buildApplicationFromExtraction(
    CareerExtraction extraction,
    String rawText,
    String sourceName,
  ) {
    final combined = '${extraction.company ?? ''} ${extraction.role ?? ''} ${extraction.eligibility ?? ''} $rawText'.toLowerCase();

    OpportunityCategory category = OpportunityCategory.job;
    if (combined.contains('hackathon') || combined.contains('hack') || combined.contains('devpost') || combined.contains('bounty')) {
      category = OpportunityCategory.hackathon;
    } else if (combined.contains('summit') || combined.contains('conference') || combined.contains('workshop') || combined.contains('webinar') || combined.contains('meetup')) {
      category = OpportunityCategory.event;
    } else if (combined.contains('contest') || combined.contains('codeforces') || combined.contains('icpc') || combined.contains('leetcode')) {
      category = OpportunityCategory.contest;
    }

    ApplicationStatus status = ApplicationStatus.applied;
    if ((extraction.interviewDate != null && extraction.interviewDate!.isNotEmpty) || extraction.status == 'Interview') {
      status = ApplicationStatus.interview;
    } else if (extraction.status == 'Action Required') {
      status = ApplicationStatus.actionRequired;
    } else if (extraction.status == 'Waiting') {
      status = ApplicationStatus.waiting;
    }

    final docs = extraction.requiredDocuments
            ?.map((name) => RequiredDocument(name: name))
            .toList() ??
        [];

    final company = (extraction.company != null && extraction.company!.trim().isNotEmpty)
        ? extraction.company!.trim()
        : _guessCompanyFromText(rawText);

    final role = (extraction.role != null && extraction.role!.trim().isNotEmpty)
        ? extraction.role!.trim()
        : (category == OpportunityCategory.hackathon ? 'Hackathon Participant' : 'Candidate');

    return Application(
      id: const Uuid().v4(),
      category: category,
      company: company,
      role: role,
      deadline: extraction.deadline ?? '',
      interviewDate: extraction.interviewDate ?? '',
      interviewTime: extraction.interviewTime ?? '',
      requiredDocuments: docs,
      status: status,
      createdAt: DateTime.now(),
      location: extraction.location ?? '',
      workMode: extraction.workMode ?? '',
      stipend: extraction.stipend ?? extraction.salary ?? '',
      notes: 'Auto-ingested via $sourceName on ${DateTime.now().toString().split('.').first}',
      source: sourceName,
    );
  }

  String _guessCompanyFromText(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('google')) return 'Google';
    if (lower.contains('amazon')) return 'Amazon';
    if (lower.contains('microsoft')) return 'Microsoft';
    if (lower.contains('meta') || lower.contains('facebook')) return 'Meta';
    if (lower.contains('apple')) return 'Apple';
    if (lower.contains('uber')) return 'Uber';
    if (lower.contains('stripe')) return 'Stripe';
    if (lower.contains('ethglobal')) return 'ETHGlobal';
    if (lower.contains('codeforces')) return 'Codeforces';
    if (lower.contains('devpost')) return 'Devpost';
    if (lower.contains('hacker')) return 'HackerRank';
    return 'Shared Opportunity';
  }

  void _autoScheduleAlarmIfApplicable(BuildContext context, Application app) {
    final reminderController = context.read<ReminderController>();
    final now = DateTime.now();

    DateTime? targetDate;
    ReminderType reminderType = ReminderType.custom;
    String title = '${app.company} - ${app.role}';

    if (app.interviewDate.isNotEmpty) {
      targetDate = _parseDateString(app.interviewDate, app.interviewTime);
      reminderType = ReminderType.interviewAlarm;
      title = '${app.company} Interview Alarm';
    } else if (app.deadline.isNotEmpty) {
      targetDate = _parseDateString(app.deadline, '');
      reminderType = ReminderType.deadlineAlert;
      title = '${app.company} Application Deadline';
    }

    if (targetDate != null && targetDate.isAfter(now)) {
      final reminder = Reminder(
        id: const Uuid().v4(),
        title: title,
        company: app.company,
        dateTime: targetDate,
        type: reminderType,
        isEnabled: true,
        isSoundEnabled: true,
        applicationId: app.id,
      );
      reminderController.addReminder(reminder);
    }
  }

  DateTime? _parseDateString(String dateStr, String timeStr) {
    final now = DateTime.now();
    final lower = dateStr.toLowerCase();

    if (lower.contains('tomorrow')) {
      return DateTime(now.year, now.month, now.day + 1, 9, 30);
    }
    if (lower.contains('today')) {
      return DateTime(now.year, now.month, now.day, 18, 0);
    }

    // Attempt simple regex for dates like "Sep 12", "Sept 12", "12/09", etc.
    final match = RegExp(r'(\d{1,2})').firstMatch(dateStr);
    if (match != null) {
      final day = int.tryParse(match.group(1) ?? '');
      if (day != null && day >= 1 && day <= 31) {
        int month = now.month;
        if (lower.contains('jan')) month = 1;
        if (lower.contains('feb')) month = 2;
        if (lower.contains('mar')) month = 3;
        if (lower.contains('apr')) month = 4;
        if (lower.contains('may')) month = 5;
        if (lower.contains('jun')) month = 6;
        if (lower.contains('jul')) month = 7;
        if (lower.contains('aug')) month = 8;
        if (lower.contains('sep')) month = 9;
        if (lower.contains('oct')) month = 10;
        if (lower.contains('nov')) month = 11;
        if (lower.contains('dec')) month = 12;

        var year = now.year;
        var parsed = DateTime(year, month, day, 9, 30);
        if (parsed.isBefore(now)) {
          parsed = DateTime(year + 1, month, day, 9, 30);
        }
        return parsed;
      }
    }

    // Default fallback: 3 days in future
    return now.add(const Duration(days: 3));
  }
}

