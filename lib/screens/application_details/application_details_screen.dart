import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme.dart';
import '../../controllers/application_controller.dart';
import '../../controllers/ai_controller.dart';
import '../../controllers/reminder_controller.dart';
import '../../models/application.dart';
import '../../models/reminder.dart';
import '../../models/required_document.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/document_checklist.dart';
import '../../widgets/company_logo.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/gradient_button.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  final Application application;

  const ApplicationDetailsScreen({super.key, required this.application});

  @override
  State<ApplicationDetailsScreen> createState() => _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  late Application _app;
  bool _isGeneratingAI = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _app = widget.application;
    _notesController.text = _app.notes;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _updateStatus(ApplicationStatus newStatus) {
    if (_app.status == newStatus) return;
    setState(() {
      _app = _app.copyWith(status: newStatus);
    });
    context.read<ApplicationController>().updateApplication(_app);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Stage updated to ${_statusLabel(newStatus)}'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _statusLabel(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied:
        return _app.category == OpportunityCategory.hackathon
            ? 'Registered'
            : (_app.category == OpportunityCategory.event ? "RSVP'd" : 'Applied');
      case ApplicationStatus.actionRequired:
        return _app.category == OpportunityCategory.hackathon
            ? 'Building'
            : (_app.category == OpportunityCategory.event ? 'Waitlisted' : 'Action Required');
      case ApplicationStatus.interview:
        return _app.category == OpportunityCategory.hackathon
            ? 'Demo Day'
            : (_app.category == OpportunityCategory.event ? 'Attending' : 'Interview');
      case ApplicationStatus.waiting:
        return _app.category == OpportunityCategory.hackathon
            ? 'Results'
            : (_app.category == OpportunityCategory.event ? 'Completed' : 'Offer / Waiting');
    }
  }

  void _toggleDocument(int index, bool isCompleted) {
    final docs = List<RequiredDocument>.from(_app.requiredDocuments);
    docs[index] = docs[index].copyWith(isCompleted: isCompleted);
    setState(() {
      _app = _app.copyWith(requiredDocuments: docs);
    });
    context.read<ApplicationController>().updateApplication(_app);
  }

  void _addDeliverableDialog() {
    final docController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkCard
            : AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.borderDark
                : AppTheme.borderLight,
          ),
        ),
        title: const Text('Add Deliverable / Requirement', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: docController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. System Design Slides, Video Demo',
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF151C2A)
                : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final text = docController.text.trim();
              if (text.isNotEmpty) {
                final docs = List<RequiredDocument>.from(_app.requiredDocuments)
                  ..add(RequiredDocument(name: text, isCompleted: false));
                setState(() {
                  _app = _app.copyWith(requiredDocuments: docs);
                });
                context.read<ApplicationController>().updateApplication(_app);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _saveNotes() {
    setState(() {
      _app = _app.copyWith(notes: _notesController.text.trim());
    });
    context.read<ApplicationController>().updateApplication(_app);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Notes saved successfully!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareApplication() {
    final shareText = '''
OPPORTUNITY SUMMARY
Company: ${_app.company}
Role: ${_app.role}
Category: ${_app.category.label}
Status: ${_app.status.name.toUpperCase()}
${_app.interviewDate.isNotEmpty ? "Interview: ${_app.interviewDate} at ${_app.interviewTime}\n" : ""}${_app.deadline.isNotEmpty ? "Deadline: ${_app.deadline}\n" : ""}${_app.stipend.isNotEmpty ? "Compensation: ${_app.stipend}\n" : ""}${_app.location.isNotEmpty ? "Location: ${_app.location} (${_app.workMode})\n" : ""}
Tracked with Career Copilot
''';

    Clipboard.setData(ClipboardData(text: shareText.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Opportunity summary copied to clipboard!'),
          ],
        ),
        backgroundColor: AppTheme.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkCard
            : AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.borderDark
                : AppTheme.borderLight,
          ),
        ),
        title: Text('Delete Opportunity?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove ${_app.company} (${_app.role}) from your pipeline?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: Theme.of(context).textTheme.bodyMedium),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.vibrantRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ApplicationController>().deleteApplication(_app.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // --- Set Alarm / Reminder Sheet ---
  void _openSetAlarmSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime alarmDate = DateTime.now().add(const Duration(hours: 3));
    TimeOfDay alarmTime = TimeOfDay.fromDateTime(alarmDate);
    final titleController = TextEditingController(
      text: '${_app.company} ${_app.role} Prep & Attendance',
    );
    bool soundEnabled = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Material(
            color: isDark ? AppTheme.darkCard : AppTheme.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.alarm_add_rounded, color: AppTheme.orange, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set Opportunity Alarm',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Linked to ${_app.company}',
                              style: TextStyle(fontSize: 12, color: _app.category.color, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Alarm Purpose / Title',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF151C2A) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.calendar_month_rounded, size: 18),
                          label: Text(DateFormat('MMM d, yyyy').format(alarmDate), style: const TextStyle(fontSize: 12.5)),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: alarmDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 730)),
                            );
                            if (picked != null) {
                              setSheetState(() => alarmDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.schedule_rounded, size: 18),
                          label: Text(alarmTime.format(ctx), style: const TextStyle(fontSize: 12.5)),
                          onPressed: () async {
                            final picked = await showTimePicker(context: ctx, initialTime: alarmTime);
                            if (picked != null) {
                              setSheetState(() => alarmTime = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sound & Notification Alarm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      soundEnabled ? 'Alarm ringtone & system notification' : 'Silent banner notification',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                    secondary: Icon(
                      soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: soundEnabled ? AppTheme.orange : Colors.grey,
                    ),
                    value: soundEnabled,
                    onChanged: (val) => setSheetState(() => soundEnabled = val),
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    label: 'Schedule Alarm',
                    icon: Icons.notifications_active_rounded,
                    onPressed: () {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;

                      final targetDateTime = DateTime(
                        alarmDate.year,
                        alarmDate.month,
                        alarmDate.day,
                        alarmTime.hour,
                        alarmTime.minute,
                      );

                      final reminder = Reminder(
                        id: const Uuid().v4(),
                        title: title,
                        company: _app.company,
                        dateTime: targetDateTime,
                        type: ReminderType.interviewAlarm,
                        isEnabled: true,
                        isSoundEnabled: soundEnabled,
                        applicationId: _app.id,
                      );

                      context.read<ReminderController>().addReminder(reminder);
                      Navigator.pop(sheetCtx);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text('Alarm scheduled for ${DateFormat('hh:mm a, MMM d').format(targetDateTime)}!'),
                            ],
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- AI Reasoning Action Runner ---
  Future<void> _runAIAction(String actionTitle, String prompt) async {
    setState(() => _isGeneratingAI = true);

    final aiController = context.read<AIController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      final result = await aiController.chatWithCareerCoach(prompt, [_app]);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => Material(
          color: isDark ? AppTheme.darkCard : AppTheme.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: AppTheme.orange, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        actionTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF151C2A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      result,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6, fontSize: 13.5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.orange,
                          side: const BorderSide(color: AppTheme.orange),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: result));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('AI result copied to clipboard!'),
                              backgroundColor: AppTheme.orange,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy Output', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _app.category.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dateLabel = _app.category == OpportunityCategory.hackathon
        ? 'Demo Day / Pitch Date'
        : (_app.category == OpportunityCategory.event
            ? 'Event Date'
            : (_app.category == OpportunityCategory.contest ? 'Contest Date' : 'Interview Date'));
    final deadlineLabel = _app.category == OpportunityCategory.hackathon
        ? 'Submission Deadline'
        : (_app.category == OpportunityCategory.event ? 'RSVP Deadline' : 'Application Deadline');

    // Pipeline step labels
    final step1Label = _app.category == OpportunityCategory.hackathon
        ? 'Registered'
        : (_app.category == OpportunityCategory.event ? "RSVP'd" : 'Applied');
    final step2Label = _app.category == OpportunityCategory.hackathon
        ? 'Building'
        : (_app.category == OpportunityCategory.event ? 'Waitlisted' : 'Action Req');
    final step3Label = _app.category == OpportunityCategory.hackathon
        ? 'Demo Day'
        : (_app.category == OpportunityCategory.event ? 'Attending' : 'Interview');
    final step4Label = _app.category == OpportunityCategory.hackathon
        ? 'Results'
        : (_app.category == OpportunityCategory.event ? 'Completed' : 'Offer');

    // Active reminders linked to this opportunity
    final appReminders = context.watch<ReminderController>().reminders.where(
      (r) => r.applicationId == _app.id,
    ).toList();

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: AppTheme.cardDecoration(context, borderRadius: 12),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).iconTheme.color, size: 18),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const AppLogo(size: 38, emblemOnly: true),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: AppTheme.cardDecoration(context, borderRadius: 12),
                          child: IconButton(
                            icon: Icon(
                              appReminders.isNotEmpty ? Icons.alarm_on_rounded : Icons.alarm_add_rounded,
                              color: appReminders.isNotEmpty ? const Color(0xFF10B981) : AppTheme.orange,
                              size: 20,
                            ),
                            tooltip: 'Set Alarm / Reminder',
                            onPressed: _openSetAlarmSheet,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: AppTheme.cardDecoration(context, borderRadius: 12),
                          child: IconButton(
                            icon: const Icon(Icons.share_rounded, color: AppTheme.orange, size: 20),
                            tooltip: 'Share / Copy Summary',
                            onPressed: _shareApplication,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: AppTheme.cardDecoration(context, borderRadius: 12),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.statusRedText, size: 20),
                            tooltip: 'Delete',
                            onPressed: _confirmDelete,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Body Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Glass Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: AppTheme.cardDecoration(
                        context,
                        borderRadius: 24,
                        borderColor: catColor.withValues(alpha: 0.35),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CompanyLogoWidget(
                                company: _app.company,
                                category: _app.category,
                                size: 54,
                                borderRadius: 18,
                                showCategoryBadge: true,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: catColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: catColor.withValues(alpha: 0.35)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(_app.category.icon, size: 12, color: catColor),
                                            const SizedBox(width: 5),
                                            Text(
                                              _app.category.label.toUpperCase(),
                                              style: TextStyle(
                                                color: catColor,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusChip(status: _app.status),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _app.company,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _app.role,
                            style: TextStyle(
                              color: catColor,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Badges Row
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_app.stipend.isNotEmpty)
                                _buildBadgePill(
                                  context,
                                  icon: _app.category == OpportunityCategory.hackathon || _app.category == OpportunityCategory.contest
                                      ? Icons.emoji_events_rounded
                                      : Icons.payments_outlined,
                                  text: _app.stipend,
                                  color: catColor,
                                ),
                              if (_app.location.isNotEmpty)
                                _buildBadgePill(
                                  context,
                                  icon: Icons.location_on_rounded,
                                  text: _app.location,
                                  color: AppTheme.vibrantBlue,
                                ),
                              if (_app.workMode.isNotEmpty)
                                _buildBadgePill(
                                  context,
                                  icon: Icons.laptop_mac_rounded,
                                  text: _app.workMode,
                                  color: AppTheme.vibrantPurple,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0),

                    const SizedBox(height: 24),

                    // Connected Pipeline Progress Stepper
                    Text(
                      _app.category == OpportunityCategory.hackathon
                          ? 'Hackathon Progress Stage'
                          : (_app.category == OpportunityCategory.event
                              ? 'Event Attendance Stage'
                              : 'Pipeline Progress Stage'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: AppTheme.cardDecoration(context, borderRadius: 20),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildConnectedStep(
                              context,
                              label: step1Label,
                              status: ApplicationStatus.applied,
                              icon: Icons.send_rounded,
                              stepNumber: 1,
                            ),
                          ),
                          _buildConnectorLine(context, isCompleted: _isStepPassed(1)),
                          Expanded(
                            child: _buildConnectedStep(
                              context,
                              label: step2Label,
                              status: ApplicationStatus.actionRequired,
                              icon: Icons.assignment_late_rounded,
                              stepNumber: 2,
                            ),
                          ),
                          _buildConnectorLine(context, isCompleted: _isStepPassed(2)),
                          Expanded(
                            child: _buildConnectedStep(
                              context,
                              label: step3Label,
                              status: ApplicationStatus.interview,
                              icon: Icons.video_call_rounded,
                              stepNumber: 3,
                            ),
                          ),
                          _buildConnectorLine(context, isCompleted: _isStepPassed(3)),
                          Expanded(
                            child: _buildConnectedStep(
                              context,
                              label: step4Label,
                              status: ApplicationStatus.waiting,
                              icon: Icons.emoji_events_rounded,
                              stepNumber: 4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Timeline & Alarms Card
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Timeline & Key Dates',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        GestureDetector(
                          onTap: _openSetAlarmSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.alarm_add_rounded, size: 14, color: AppTheme.orange),
                                SizedBox(width: 4),
                                Text(
                                  'Add Alarm',
                                  style: TextStyle(color: AppTheme.orange, fontSize: 11.5, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: AppTheme.cardDecoration(context, borderRadius: 20),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            context,
                            Icons.calendar_month_rounded,
                            dateLabel,
                            _app.interviewDate.isNotEmpty
                                ? '${_app.interviewDate}${_app.interviewTime.isNotEmpty ? ' at ${_app.interviewTime}' : ''}'
                                : 'Not yet scheduled',
                            catColor,
                          ),
                          Divider(color: Theme.of(context).dividerColor, height: 24),
                          _buildInfoRow(
                            context,
                            Icons.access_time_rounded,
                            deadlineLabel,
                            _app.deadline.isNotEmpty ? _app.deadline : 'No deadline provided',
                            AppTheme.orange,
                          ),
                          Divider(color: Theme.of(context).dividerColor, height: 24),
                          _buildInfoRow(
                            context,
                            Icons.location_on_rounded,
                            'Location / Format',
                            _app.location.isNotEmpty ? '${_app.location} (${_app.workMode})' : 'Remote / Global',
                            AppTheme.vibrantBlue,
                          ),
                          if (appReminders.isNotEmpty) ...[
                            Divider(color: Theme.of(context).dividerColor, height: 24),
                            ...appReminders.map(
                              (rem) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.alarm_on_rounded, color: Color(0xFF10B981), size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Alarm: ${DateFormat('hh:mm a, MMM d').format(rem.dateTime)}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                                      onPressed: () => context.read<ReminderController>().deleteReminder(rem.id),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Deliverables / Documents Checklist
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _app.category == OpportunityCategory.hackathon
                              ? 'Deliverables & Checklist'
                              : 'Required Documents',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        GestureDetector(
                          onTap: _addDeliverableDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_rounded, size: 15, color: catColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Add Item',
                                  style: TextStyle(color: catColor, fontSize: 11.5, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: AppTheme.cardDecoration(context, borderRadius: 20),
                      padding: const EdgeInsets.all(16),
                      child: _app.requiredDocuments.isNotEmpty
                          ? DocumentChecklist(
                              documents: _app.requiredDocuments,
                              onToggle: _toggleDocument,
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No deliverables added. Tap "+ Add Item" above.',
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45),
                                ),
                              ),
                            ),
                    ),

                    // AI Copilot Live Tools
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: AppTheme.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'AI Copilot Tools',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (_isGeneratingAI) ...[
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.orange),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAiActionCard(
                            context,
                            title: _app.category == OpportunityCategory.hackathon
                                ? 'Pitch & Strategy'
                                : (_app.category == OpportunityCategory.event
                                    ? 'Networking Plan'
                                    : (_app.category == OpportunityCategory.contest ? 'Contest Tactics' : 'Interview Q&A')),
                            desc: _app.category == OpportunityCategory.hackathon
                                ? 'Pitch hook, USP & demo script'
                                : (_app.category == OpportunityCategory.event
                                    ? 'Questions & networking guide'
                                    : (_app.category == OpportunityCategory.contest ? 'Speed tactics & debug steps' : 'Role-specific prep & questions')),
                            icon: _app.category == OpportunityCategory.hackathon
                                ? Icons.lightbulb_rounded
                                : (_app.category == OpportunityCategory.event
                                    ? Icons.groups_rounded
                                    : (_app.category == OpportunityCategory.contest ? Icons.speed_rounded : Icons.quiz_rounded)),
                            color: catColor,
                            onTap: () {
                              final prompt = 'Generate comprehensive interview questions, behavioral guidance, and technical focus areas for ${_app.company} (${_app.role}).';
                              _runAIAction('Interview Prep for ${_app.company}', prompt);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAiActionCard(
                            context,
                            title: _app.category == OpportunityCategory.hackathon
                                ? 'Mentor Outreach'
                                : (_app.category == OpportunityCategory.event
                                    ? 'Speaker Connect'
                                    : (_app.category == OpportunityCategory.contest ? 'Team Brief' : 'Follow-up Draft')),
                            desc: _app.category == OpportunityCategory.hackathon
                                ? 'Sponsor & mentor email'
                                : (_app.category == OpportunityCategory.event
                                    ? 'Speaker inquiry message'
                                    : (_app.category == OpportunityCategory.contest ? 'Team division message' : 'Confirmation & thank you note')),
                            icon: _app.category == OpportunityCategory.hackathon
                                ? Icons.handshake_rounded
                                : (_app.category == OpportunityCategory.event
                                    ? Icons.connect_without_contact_rounded
                                    : (_app.category == OpportunityCategory.contest ? Icons.diversity_3_rounded : Icons.mark_email_read_rounded)),
                            color: catColor,
                            onTap: () {
                              final prompt = 'Draft a professional, concise email confirmation and thank you message for the ${_app.role} opportunity at ${_app.company}.';
                              _runAIAction('Outreach Draft for ${_app.company}', prompt);
                            },
                          ),
                        ),
                      ],
                    ),

                    // Personal Notes
                    const SizedBox(height: 24),
                    Text(
                      'Personal Notes & Recruiter Contacts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: AppTheme.cardDecoration(context, borderRadius: 20),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          TextField(
                            controller: _notesController,
                            maxLines: 4,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                            decoration: InputDecoration(
                              hintText: 'Add recruiter contacts, salary negotiations, or interview notes...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.orange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                              ),
                              onPressed: _saveNotes,
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text('Save Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isStepPassed(int stepIndex) {
    final currentVal = _stepValue(_app.status);
    return currentVal > stepIndex;
  }

  int _stepValue(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied:
        return 1;
      case ApplicationStatus.actionRequired:
        return 2;
      case ApplicationStatus.interview:
        return 3;
      case ApplicationStatus.waiting:
        return 4;
    }
  }

  Widget _buildConnectedStep(
    BuildContext context, {
    required String label,
    required ApplicationStatus status,
    required IconData icon,
    required int stepNumber,
  }) {
    final isCurrent = _app.status == status;
    final isPassed = _isStepPassed(stepNumber);
    final catColor = _app.category.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _updateStatus(status),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent
                  ? catColor
                  : (isPassed ? catColor.withValues(alpha: 0.25) : (isDark ? const Color(0xFF1E2332) : const Color(0xFFE2E8F0))),
              border: Border.all(
                color: isCurrent
                    ? Colors.white.withValues(alpha: 0.6)
                    : (isPassed ? catColor : (isDark ? AppTheme.borderDark : AppTheme.borderLight)),
                width: isCurrent ? 2 : 1,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: catColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isPassed ? Icons.check_rounded : icon,
              size: 16,
              color: isCurrent
                  ? Colors.white
                  : (isPassed ? catColor : (isDark ? Colors.white54 : Colors.black54)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isCurrent
                  ? catColor
                  : (isDark ? Colors.white70 : Colors.black87),
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectorLine(BuildContext context, {required bool isCompleted}) {
    final catColor = _app.category.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        height: 2.5,
        margin: const EdgeInsets.only(bottom: 22),
        decoration: BoxDecoration(
          color: isCompleted
              ? catColor
              : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildBadgePill(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, Color accentColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accentColor, size: 19),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.5)),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiActionCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _isGeneratingAI ? null : onTap,
      child: Container(
        decoration: AppTheme.cardDecoration(context, borderRadius: 18),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
