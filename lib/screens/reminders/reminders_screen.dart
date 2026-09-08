import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../controllers/reminder_controller.dart';
import '../../controllers/application_controller.dart';
import '../../models/reminder.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/company_logo.dart';
import '../../widgets/app_logo.dart';
import '../home/home_screen.dart';
import '../applications/applications_screen.dart';
import '../add_opportunity/add_opportunity_screen.dart';
import '../calendar/calendar_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  ReminderType? _selectedFilter;

  void _onNavTap(int index) {
    if (index == 2) return;
    Widget nextScreen;
    if (index == 0) {
      nextScreen = const HomeScreen();
    } else if (index == 1) {
      nextScreen = const ApplicationsScreen();
    } else if (index == 3) {
      nextScreen = const AddOpportunityScreen();
    } else if (index == 4) {
      nextScreen = const CalendarScreen();
    } else if (index == 5) {
      nextScreen = const ChatScreen();
    } else {
      nextScreen = const ProfileScreen();
    }

    Navigator.pushReplacement(
      context,
      AppTheme.morphPageRoute(screen: nextScreen),
    );
  }

  static Widget _flightShuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: AppTheme.heroDropDecoration(flightContext),
      ),
    );
  }

  void _showAddOrEditModal([Reminder? existing]) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    ReminderType selectedType = existing?.type ?? ReminderType.interviewAlarm;
    DateTime selectedDate = existing?.dateTime ?? DateTime.now().add(const Duration(hours: 2));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    bool soundEnabled = existing?.isSoundEnabled ?? true;
    String? selectedCompany = existing?.company;
    String? linkedAppId = existing?.applicationId;
    bool hasTitleError = false;

    final apps = context.read<ApplicationController>().applications;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2638) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.alarm_add_rounded,
                                  color: AppTheme.orange,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                existing == null ? 'Set Alarm / Reminder' : 'Edit Alarm',
                                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title field
                      TextField(
                        controller: titleController,
                        onChanged: (_) {
                          if (hasTitleError) {
                            setModalState(() => hasTitleError = false);
                          }
                        },
                        style: TextStyle(
                          color: isDark ? Colors.white : AppTheme.accentBlack,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Alarm Title / Purpose *',
                          hintText: 'e.g. Amazon Interview Prep',
                          errorText: hasTitleError ? 'Please enter a title for your alarm' : null,
                          prefixIcon: const Icon(Icons.edit_note_rounded),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF151C2A)
                              : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Selector
                      Text(
                        'Category',
                        style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ReminderType.values.map((type) {
                          final isSelected = selectedType == type;
                          return ChoiceChip(
                            avatar: Icon(
                              type.icon,
                              size: 16,
                              color: isSelected ? Colors.white : type.color,
                            ),
                            label: Text(type.label),
                            selected: isSelected,
                            selectedColor: type.color,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => selectedType = type);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Link to Application (using String id for dropdown stability)
                      if (apps.isNotEmpty) ...[
                        Text(
                          'Link to Tracked Opportunity (Optional)',
                          style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF151C2A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: apps.any((a) => a.id == linkedAppId) ? linkedAppId : null,
                              hint: const Text('None (General Alarm)'),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('None (General Alarm)'),
                                ),
                                ...apps.map(
                                  (app) => DropdownMenuItem<String?>(
                                    value: app.id,
                                    child: Row(
                                      children: [
                                        CompanyLogoWidget(
                                          company: app.company,
                                          category: app.category,
                                          size: 24,
                                          borderRadius: 6,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '${app.company} - ${app.role}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (selectedId) {
                                setModalState(() {
                                  linkedAppId = selectedId;
                                  if (selectedId != null) {
                                    final app = apps.firstWhere((a) => a.id == selectedId);
                                    selectedCompany = app.company;
                                    if (titleController.text.trim().isEmpty) {
                                      titleController.text =
                                          '${app.company} ${selectedType.label}';
                                    }
                                  } else {
                                    selectedCompany = null;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Date & Time pickers (robust against assertion exceptions)
                      Text(
                        'Date & Time',
                        style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.calendar_month_rounded, size: 18),
                              label: Text(
                                DateFormat('MMM d, yyyy').format(selectedDate),
                                style: const TextStyle(fontSize: 12.5),
                              ),
                              onPressed: () async {
                                final now = DateTime.now();
                                final firstAllowedDate = selectedDate.isBefore(now)
                                    ? selectedDate.subtract(const Duration(days: 30))
                                    : now.subtract(const Duration(days: 365));

                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: selectedDate,
                                  firstDate: firstAllowedDate,
                                  lastDate: now.add(const Duration(days: 730)),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    selectedDate = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                      selectedTime.hour,
                                      selectedTime.minute,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.schedule_rounded, size: 18),
                              label: Text(
                                selectedTime.format(ctx),
                                style: const TextStyle(fontSize: 12.5),
                              ),
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: ctx,
                                  initialTime: selectedTime,
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    selectedTime = picked;
                                    selectedDate = DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      picked.hour,
                                      picked.minute,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Sound toggle
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sound & Notification Alarm'),
                        subtitle: Text(
                          soundEnabled ? 'Alarm ringtone & system notification' : 'Silent banner notification',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        secondary: Icon(
                          soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          color: soundEnabled ? AppTheme.orange : Colors.grey,
                        ),
                        value: soundEnabled,
                        onChanged: (val) => setModalState(() => soundEnabled = val),
                      ),
                      const SizedBox(height: 20),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () {
                            final title = titleController.text.trim();
                            if (title.isEmpty) {
                              setModalState(() => hasTitleError = true);
                              return;
                            }

                            final reminderController = context.read<ReminderController>();
                            final finalDateTime = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );

                            if (existing == null) {
                              final newReminder = Reminder(
                                id: const Uuid().v4(),
                                title: title,
                                company: selectedCompany,
                                dateTime: finalDateTime,
                                type: selectedType,
                                isEnabled: true,
                                isSoundEnabled: soundEnabled,
                                applicationId: linkedAppId,
                              );
                              reminderController.addReminder(newReminder);
                            } else {
                              final updated = existing.copyWith(
                                title: title,
                                company: selectedCompany,
                                dateTime: finalDateTime,
                                type: selectedType,
                                isSoundEnabled: soundEnabled,
                                applicationId: linkedAppId,
                              );
                              reminderController.updateReminder(updated);
                            }

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      existing == null
                                          ? 'Alarm scheduled for ${DateFormat('hh:mm a, MMM d').format(finalDateTime)}!'
                                          : 'Alarm updated successfully!',
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          child: Text(
                            existing == null ? 'Set Alarm' : 'Save Changes',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimeRemaining(DateTime target) {
    final now = DateTime.now();
    final difference = target.difference(now);

    if (difference.isNegative) {
      return 'Past due';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return mins <= 1 ? 'In 1 minute' : 'In $mins minutes';
    } else if (difference.inHours < 24 && target.day == now.day) {
      return 'Today in ${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inHours < 48 && target.day == now.add(const Duration(days: 1)).day) {
      return 'Tomorrow at ${DateFormat('hh:mm a').format(target)}';
    } else {
      return 'In ${difference.inDays} days (${DateFormat('MMM d').format(target)})';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: TexturedBackground(
        child: SafeArea(
          bottom: false,
          child: Consumer<ReminderController>(
            builder: (context, controller, child) {
              final allReminders = controller.reminders;
              final filtered = _selectedFilter == null
                  ? allReminders
                  : allReminders.where((r) => r.type == _selectedFilter).toList();

              final activeCount = controller.activeReminders.length;
              final notifEnabled = controller.notificationsEnabled;

              // Find next active upcoming alarm
              Reminder? nextAlarm;
              final now = DateTime.now();
              for (final r in controller.activeReminders) {
                if (r.dateTime.isAfter(now)) {
                  nextAlarm = r;
                  break;
                }
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Hero Black Drop Header (Morphs smoothly between tabs) ──
                  SliverToBoxAdapter(
                    child: Hero(
                      tag: 'hero_black_drop',
                      flightShuttleBuilder: _flightShuttleBuilder,
                      child: Material(
                        type: MaterialType.transparency,
                        child: Container(
                          decoration: AppTheme.heroDropDecoration(context),
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const AppLogo(height: 44, width: 116),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.orange,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          elevation: 3,
                                        ),
                                        icon: const Icon(Icons.add_alarm_rounded, size: 17),
                                        label: const Text('Set Alarm', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                        onPressed: () => _showAddOrEditModal(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Reminders & Alarms',
                                    style: TextStyle(
                                      color: AppTheme.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 26,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$activeCount active alarm${activeCount == 1 ? '' : 's'} scheduled for your pipeline',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // Notifications Enablement & Permission Banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isDark ? const Color(0xFF1B2333) : Colors.white,
                          border: Border.all(
                            color: notifEnabled
                                ? (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08))
                                : AppTheme.orange.withValues(alpha: 0.5),
                            width: notifEnabled ? 1 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (notifEnabled ? const Color(0xFF10B981) : AppTheme.orange)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                notifEnabled
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_paused_rounded,
                                color: notifEnabled ? const Color(0xFF10B981) : AppTheme.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notifEnabled ? 'Notifications Active' : 'Notifications Disabled',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: isDark ? Colors.white : AppTheme.accentBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    notifEnabled
                                        ? 'Alarms & sound alerts enabled for deadlines'
                                        : 'Tap enable to sound alarms for interviews',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!notifEnabled)
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: AppTheme.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () async {
                                  await controller.requestAndEnableNotifications();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Notifications & alarms enabled!'),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Enable',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                ),
                              )
                            else
                              IconButton(
                                tooltip: 'Test Alarm Sound & Banner',
                                icon: const Icon(Icons.volume_up_rounded, size: 20, color: AppTheme.orange),
                                onPressed: () async {
                                  await controller.testAlarmNotification();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(Icons.volume_up_rounded, color: Colors.white, size: 18),
                                            SizedBox(width: 8),
                                            Text('Playing test alarm sound & notification...'),
                                          ],
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Next Alarm Spotlight Card
                  if (nextAlarm != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? const [Color(0xEE2A1E1E), Color(0xD81E2638)]
                                  : const [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
                            ),
                            border: Border.all(
                              color: AppTheme.orange.withValues(alpha: isDark ? 0.40 : 0.50),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.orange.withValues(alpha: isDark ? 0.20 : 0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.orange.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.orange.withValues(alpha: 0.3)),
                                ),
                                child: const Icon(
                                  Icons.alarm_on_rounded,
                                  color: AppTheme.orange,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.orange,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'NEXT UPCOMING',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('hh:mm a').format(nextAlarm.dateTime),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: AppTheme.orange,
                                          ),
                                        ),
                                        const Spacer(),
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _formatTimeRemaining(nextAlarm.dateTime),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 10,
                                                color: isDark ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      nextAlarm.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      DateFormat('EEEE, MMM d, yyyy').format(nextAlarm.dateTime),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white60 : Colors.black54,
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

                  // Filter Chips Row
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _FilterPill(
                            label: 'All (${allReminders.length})',
                            icon: Icons.tune_rounded,
                            isSelected: _selectedFilter == null,
                            color: AppTheme.orange,
                            onTap: () => setState(() => _selectedFilter = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterPill(
                            label: 'Alarms',
                            icon: Icons.alarm_rounded,
                            isSelected: _selectedFilter == ReminderType.interviewAlarm,
                            color: ReminderType.interviewAlarm.color,
                            onTap: () => setState(() => _selectedFilter = ReminderType.interviewAlarm),
                          ),
                          const SizedBox(width: 8),
                          _FilterPill(
                            label: 'Deadlines',
                            icon: Icons.hourglass_top_rounded,
                            isSelected: _selectedFilter == ReminderType.deadlineAlert,
                            color: ReminderType.deadlineAlert.color,
                            onTap: () => setState(() => _selectedFilter = ReminderType.deadlineAlert),
                          ),
                          const SizedBox(width: 8),
                          _FilterPill(
                            label: 'Prep Drills',
                            icon: Icons.timer_outlined,
                            isSelected: _selectedFilter == ReminderType.prepNotification,
                            color: ReminderType.prepNotification.color,
                            onTap: () => setState(() => _selectedFilter = ReminderType.prepNotification),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  // List of Reminders
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.alarm_off_rounded,
                                size: 56,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No reminders in this category',
                                style: TextStyle(
                                  color: isDark ? Colors.white60 : Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add your first alarm'),
                                onPressed: () => _showAddOrEditModal(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = filtered[index];
                            return _ReminderCard(
                              reminder: item,
                              onToggle: () {
                                controller.toggleReminder(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      item.isEnabled
                                          ? 'Alarm silenced'
                                          : 'Alarm activated for ${DateFormat('hh:mm a').format(item.dateTime)}',
                                    ),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              onEdit: () => _showAddOrEditModal(item),
                              onDelete: () => controller.deleteReminder(item.id),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 2,
        onTap: _onNavTap,
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.25 : 0.15)
              : (isDark ? const Color(0xFF1E2638) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? color : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('hh:mm a').format(reminder.dateTime);
    final dateStr = DateFormat('MMM d, yyyy').format(reminder.dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Logo or Category Icon
              if (reminder.company != null && reminder.company!.isNotEmpty)
                CompanyLogoWidget(
                  company: reminder.company!,
                  size: 46,
                  borderRadius: 14,
                )
              else
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: reminder.type.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: reminder.type.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    reminder.type.icon,
                    color: reminder.type.color,
                    size: 22,
                  ),
                ),
              const SizedBox(width: 14),

              // Time, Date & Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: reminder.isEnabled
                                ? (isDark ? Colors.white : AppTheme.accentBlack)
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: reminder.type.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              reminder.type.label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: reminder.type.color,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      reminder.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: reminder.isEnabled
                            ? (isDark ? Colors.white.withValues(alpha: 0.90) : const Color(0xFF334155))
                            : Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            dateStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ),
                        if (reminder.isSoundEnabled) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.volume_up_rounded,
                            size: 12,
                            color: AppTheme.orange.withValues(alpha: 0.8),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Switch toggle
              Switch.adaptive(
                value: reminder.isEnabled,
                activeTrackColor: AppTheme.orange.withValues(alpha: 0.6),
                activeThumbColor: AppTheme.orange,
                onChanged: (_) => onToggle(),
              ),

              // More options
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                onSelected: (action) {
                  if (action == 'edit') onEdit();
                  if (action == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
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
