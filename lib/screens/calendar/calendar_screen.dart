import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/application_controller.dart';
import '../../models/application.dart';
import '../../app/theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/textured_background.dart';

import '../home/home_screen.dart';
import '../add_opportunity/add_opportunity_screen.dart';
import '../applications/applications_screen.dart';
import '../profile/profile_screen.dart';
import '../application_details/application_details_screen.dart';
import '../chat/chat_screen.dart';
import '../reminders/reminders_screen.dart';
import '../../widgets/company_logo.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  int _selectedFilter = 0; // 0: All, 1: Interviews, 2: Hackathons, 3: Events, 4: Deadlines

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _onNavTap(int index) {
    if (index == 4) return;

    Widget nextScreen;
    if (index == 0) {
      nextScreen = const HomeScreen();
    } else if (index == 1) {
      nextScreen = const ApplicationsScreen();
    } else if (index == 2) {
      nextScreen = const RemindersScreen();
    } else if (index == 3) {
      nextScreen = const AddOpportunityScreen();
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

  DateTime? _parseDateString(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      final now = DateTime.now();
      final lower = dateStr.toLowerCase().trim();

      if (lower == 'today') {
        return DateTime(now.year, now.month, now.day);
      }
      if (lower == 'tomorrow') {
        final tomorrow = now.add(const Duration(days: 1));
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      }

      final parsedDirect = DateTime.tryParse(dateStr);
      if (parsedDirect != null) {
        return DateTime(parsedDirect.year, parsedDirect.month, parsedDirect.day);
      }

      const weekdays = {
        'monday': DateTime.monday,
        'tuesday': DateTime.tuesday,
        'wednesday': DateTime.wednesday,
        'thursday': DateTime.thursday,
        'friday': DateTime.friday,
        'saturday': DateTime.saturday,
        'sunday': DateTime.sunday,
      };
      for (final entry in weekdays.entries) {
        if (lower.contains(entry.key)) {
          int diff = entry.value - now.weekday;
          if (diff < 0) diff += 7;
          final target = now.add(Duration(days: diff));
          return DateTime(target.year, target.month, target.day);
        }
      }

      int? month;
      if (lower.contains('jan')) {
        month = 1;
      } else if (lower.contains('feb')) {
        month = 2;
      } else if (lower.contains('mar')) {
        month = 3;
      } else if (lower.contains('apr')) {
        month = 4;
      } else if (lower.contains('may')) {
        month = 5;
      } else if (lower.contains('jun')) {
        month = 6;
      } else if (lower.contains('jul')) {
        month = 7;
      } else if (lower.contains('aug')) {
        month = 8;
      } else if (lower.contains('sep')) {
        month = 9;
      } else if (lower.contains('oct')) {
        month = 10;
      } else if (lower.contains('nov')) {
        month = 11;
      } else if (lower.contains('dec')) {
        month = 12;
      }

      final match = RegExp(r'\b(\d{1,2})\b').firstMatch(lower);
      int? day = match != null ? int.tryParse(match.group(1)!) : null;

      final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(lower);
      int year = yearMatch != null ? int.parse(yearMatch.group(1)!) : now.year;

      if (month != null && day != null) {
        return DateTime(year, month, day);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  List<Application> _getEventsForDay(DateTime day, List<Application> allApps) {
    return allApps.where((app) {
      final interviewDate = _parseDateString(app.interviewDate);
      final deadlineDate = _parseDateString(app.deadline);

      final matchesInterview = interviewDate != null && isSameDay(interviewDate, day);
      final matchesDeadline = deadlineDate != null && isSameDay(deadlineDate, day);

      return matchesInterview || matchesDeadline;
    }).toList();
  }

  List<Application> _filterEvents(List<Application> events, DateTime selectedDay) {
    if (_selectedFilter == 1) {
      return events.where((app) {
        final d = _parseDateString(app.interviewDate);
        return d != null && isSameDay(d, selectedDay);
      }).toList();
    } else if (_selectedFilter == 2) {
      return events.where((app) => app.category == OpportunityCategory.hackathon).toList();
    } else if (_selectedFilter == 3) {
      return events.where((app) => app.category == OpportunityCategory.event).toList();
    } else if (_selectedFilter == 4) {
      return events.where((app) {
        final d = _parseDateString(app.deadline);
        return d != null && isSameDay(d, selectedDay);
      }).toList();
    }
    return events;
  }

  void _jumpToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = _focusedDay;
    });
  }

  void _showScheduleDialog(BuildContext context, List<Application> applications) {
    if (applications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Add an opportunity first before scheduling events.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedAppId = applications.first.id;
    String eventType = 'Interview';
    DateTime chosenDate = _selectedDay ?? DateTime.now();
    TimeOfDay chosenTime = const TimeOfDay(hour: 10, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final selectedApp = applications.firstWhere((a) => a.id == selectedAppId);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
              ),
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
                        child: const Icon(Icons.calendar_today_rounded, color: AppTheme.orange, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Schedule New Event',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text('Select Opportunity', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedAppId,
                        isExpanded: true,
                        dropdownColor: isDark ? AppTheme.darkCard : AppTheme.white,
                        items: applications.map((a) {
                          return DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              '[${a.category.shortLabel}] ${a.company} — ${a.role}',
                              style: TextStyle(
                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedAppId = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Event Category & Type', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _EventTypeChoice(
                        label: 'Interview',
                        isSelected: eventType == 'Interview',
                        color: AppTheme.orange,
                        onTap: () => setModalState(() => eventType = 'Interview'),
                      ),
                      _EventTypeChoice(
                        label: 'Hackathon',
                        isSelected: eventType == 'Hackathon',
                        color: const Color(0xFF8B5CF6),
                        onTap: () => setModalState(() => eventType = 'Hackathon'),
                      ),
                      _EventTypeChoice(
                        label: 'Tech Event',
                        isSelected: eventType == 'Tech Event',
                        color: const Color(0xFF10B981),
                        onTap: () => setModalState(() => eventType = 'Tech Event'),
                      ),
                      _EventTypeChoice(
                        label: 'Deadline',
                        isSelected: eventType == 'Deadline',
                        color: const Color(0xFF3B82F6),
                        onTap: () => setModalState(() => eventType = 'Deadline'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: chosenDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setModalState(() => chosenDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkSurface : AppTheme.lightBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(DateFormat('MMM dd, yyyy').format(chosenDate), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.orange),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (eventType == 'Interview' || eventType == 'Tech Event') ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Time', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showTimePicker(context: ctx, initialTime: chosenTime);
                                  if (picked != null) {
                                    setModalState(() => chosenTime = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkSurface : AppTheme.lightBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(chosenTime.format(ctx), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.orange),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: AppTheme.orangeButton,
                    onPressed: () async {
                      final formattedDate = DateFormat('MMMM dd, yyyy').format(chosenDate);
                      final formattedTime = chosenTime.format(ctx);

                      Application updatedApp;
                      if (eventType == 'Interview') {
                        updatedApp = selectedApp.copyWith(
                          category: OpportunityCategory.job,
                          interviewDate: formattedDate,
                          interviewTime: formattedTime,
                          status: ApplicationStatus.interview,
                          nextAction: 'Prepare for interview round',
                        );
                      } else if (eventType == 'Hackathon') {
                        updatedApp = selectedApp.copyWith(
                          category: OpportunityCategory.hackathon,
                          deadline: formattedDate,
                          status: ApplicationStatus.actionRequired,
                          nextAction: 'Team hackathon project milestone',
                        );
                      } else if (eventType == 'Tech Event') {
                        updatedApp = selectedApp.copyWith(
                          category: OpportunityCategory.event,
                          interviewDate: formattedDate,
                          interviewTime: formattedTime,
                          status: ApplicationStatus.interview,
                          nextAction: 'Attend summit / workshop session',
                        );
                      } else {
                        updatedApp = selectedApp.copyWith(
                          deadline: formattedDate,
                          status: ApplicationStatus.actionRequired,
                          nextAction: 'Complete and submit application',
                        );
                      }

                      await context.read<ApplicationController>().updateApplication(updatedApp);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        setState(() {
                          _selectedDay = chosenDate;
                          _focusedDay = chosenDate;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$eventType scheduled for ${selectedApp.company}!'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    child: const Text('Save Event to Calendar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: Consumer<ApplicationController>(
        builder: (context, controller, child) {
          final apps = controller.applications;
          final selectedEvents = _getEventsForDay(_selectedDay!, apps);
          final filteredEvents = _filterEvents(selectedEvents, _selectedDay!);

          // Monthly stats
          final monthInterviews = apps.where((a) {
            final d = _parseDateString(a.interviewDate);
            return d != null && d.month == _focusedDay.month && d.year == _focusedDay.year;
          }).length;
          final monthDeadlines = apps.where((a) {
            final d = _parseDateString(a.deadline);
            return d != null && d.month == _focusedDay.month && d.year == _focusedDay.year;
          }).length;

          return TexturedBackground(
            child: Column(
              children: [
                // ── Signature Dark Hero Header (Matches HomeScreen & ApplicationsScreen) ──
                Hero(
                  tag: 'hero_black_drop',
                  flightShuttleBuilder: _flightShuttleBuilder,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      decoration: AppTheme.heroDropDecoration(context),
                      child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Header Row: Title, Stats & Actions
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Calendar',
                                      style: TextStyle(
                                        color: AppTheme.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$monthInterviews interview${monthInterviews == 1 ? '' : 's'} • $monthDeadlines deadline${monthDeadlines == 1 ? '' : 's'} this month',
                                      style: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // "Today" Button
                              GestureDetector(
                                onTap: _jumpToToday,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.today_rounded, color: AppTheme.orange, size: 14),
                                      SizedBox(width: 5),
                                      Text(
                                        'Today',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // "+ Schedule" Button
                              GestureDetector(
                                onTap: () => _showScheduleDialog(context, apps),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.orange,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppTheme.orangeGlow,
                                        blurRadius: 10,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Profile Avatar button
                              GestureDetector(
                                onTap: () => _onNavTap(5),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppTheme.orange,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.orange.withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'L',
                                      style: TextStyle(
                                        color: AppTheme.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Segmented View Toggle: Month View | 2-Week View
                          Container(
                            height: 40,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _calendarFormat = CalendarFormat.month),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: _calendarFormat == CalendarFormat.month
                                            ? Colors.white.withValues(alpha: 0.2)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Month View',
                                          style: TextStyle(
                                            color: _calendarFormat == CalendarFormat.month ? AppTheme.white : const Color(0xFF94A3B8),
                                            fontWeight: _calendarFormat == CalendarFormat.month ? FontWeight.w700 : FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _calendarFormat = CalendarFormat.twoWeeks),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: _calendarFormat == CalendarFormat.twoWeeks
                                            ? Colors.white.withValues(alpha: 0.2)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '2-Week View',
                                          style: TextStyle(
                                            color: _calendarFormat == CalendarFormat.twoWeeks ? AppTheme.white : const Color(0xFF94A3B8),
                                            fontWeight: _calendarFormat == CalendarFormat.twoWeeks ? FontWeight.w700 : FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
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
            ),

                // ── Main Body Content (Smooth Scrollable View) ──
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    children: [
                      // Calendar Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: AppTheme.cardDecoration(context, borderRadius: AppTheme.radiusXl),
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                          child: TableCalendar<Application>(
                            firstDay: DateTime.now().subtract(const Duration(days: 365)),
                            lastDay: DateTime.now().add(const Duration(days: 365)),
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            onFormatChanged: (format) {
                              setState(() => _calendarFormat = format);
                            },
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            eventLoader: (day) => _getEventsForDay(day, apps),
                            calendarStyle: CalendarStyle(
                              outsideDaysVisible: false,
                              defaultTextStyle: TextStyle(
                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              weekendTextStyle: TextStyle(
                                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              todayDecoration: BoxDecoration(
                                color: AppTheme.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.orange, width: 1.5),
                              ),
                              todayTextStyle: const TextStyle(
                                color: AppTheme.orange,
                                fontWeight: FontWeight.w800,
                              ),
                              selectedDecoration: const BoxDecoration(
                                color: AppTheme.orange,
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.orangeGlow,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              selectedTextStyle: const TextStyle(
                                color: AppTheme.white,
                                fontWeight: FontWeight.w800,
                              ),
                              markersMaxCount: 3,
                            ),
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, day, events) {
                                if (events.isEmpty) return null;

                                bool hasInterview = false;
                                bool hasHackathon = false;
                                bool hasEvent = false;
                                bool hasDeadline = false;

                                for (final app in events) {
                                  if (app.category == OpportunityCategory.hackathon) {
                                    hasHackathon = true;
                                  } else if (app.category == OpportunityCategory.event) {
                                    hasEvent = true;
                                  }
                                  final iDate = _parseDateString(app.interviewDate);
                                  final dDate = _parseDateString(app.deadline);
                                  if (iDate != null && isSameDay(iDate, day)) {
                                    hasInterview = true;
                                  }
                                  if (dDate != null && isSameDay(dDate, day)) {
                                    hasDeadline = true;
                                  }
                                }

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (hasInterview)
                                      Container(
                                        width: 5,
                                        height: 5,
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.orange,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    if (hasHackathon)
                                      Container(
                                        width: 5,
                                        height: 5,
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF8B5CF6),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    if (hasEvent)
                                      Container(
                                        width: 5,
                                        height: 5,
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    if (hasDeadline)
                                      Container(
                                        width: 5,
                                        height: 5,
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF3B82F6),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            headerStyle: HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: TextStyle(
                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                              leftChevronIcon: Icon(
                                Icons.chevron_left_rounded,
                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right_rounded,
                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                              ),
                            ),
                            daysOfWeekStyle: DaysOfWeekStyle(
                              weekdayStyle: TextStyle(
                                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                              weekendStyle: TextStyle(
                                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 250.ms),

                      const SizedBox(height: 14),

                      // Filter Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All (${selectedEvents.length})',
                              selected: _selectedFilter == 0,
                              onTap: () => setState(() => _selectedFilter = 0),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Interviews',
                              selected: _selectedFilter == 1,
                              color: AppTheme.orange,
                              onTap: () => setState(() => _selectedFilter = 1),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Hackathons',
                              selected: _selectedFilter == 2,
                              color: const Color(0xFF8B5CF6),
                              onTap: () => setState(() => _selectedFilter = 2),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Events',
                              selected: _selectedFilter == 3,
                              color: const Color(0xFF10B981),
                              onTap: () => setState(() => _selectedFilter = 3),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Deadlines',
                              selected: _selectedFilter == 4,
                              color: const Color(0xFF3B82F6),
                              onTap: () => setState(() => _selectedFilter = 4),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Selected Day Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('EEEE, MMMM d').format(_selectedDay!),
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                            ),
                            Text(
                              '${filteredEvents.length} scheduled',
                              style: TextStyle(
                                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Agenda List Items or Empty State
                      if (filteredEvents.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkCard : AppTheme.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                                  ),
                                  child: Icon(
                                    Icons.event_available_rounded,
                                    size: 32,
                                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Clear schedule for this day',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap "+ Schedule" above to add an interview or deadline.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        for (int index = 0; index < filteredEvents.length; index++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _AgendaCard(
                              app: filteredEvents[index],
                              selectedDay: _selectedDay!,
                              parseDate: _parseDateString,
                              onOpenDetails: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ApplicationDetailsScreen(application: filteredEvents[index]),
                                  ),
                                );
                              },
                              onPrepChat: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                                );
                              },
                            ).animate().fadeIn(duration: 250.ms, delay: (index * 40).ms).slideY(begin: 0.08, end: 0),
                          ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 4,
        onTap: _onNavTap,
      ),
    );
  }
}

// ── Filter Chip Widget ──
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppTheme.orange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color
              : (isDark ? AppTheme.darkCard : AppTheme.white),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? color
                : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : (isDark ? AppTheme.textLight : AppTheme.textDark),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Event Type Choice Widget ──
class _EventTypeChoice extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _EventTypeChoice({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.16)
              : (isDark ? AppTheme.darkSurface : AppTheme.lightBg),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ── Enhanced Agenda Card ──
class _AgendaCard extends StatelessWidget {
  final Application app;
  final DateTime selectedDay;
  final DateTime? Function(String) parseDate;
  final VoidCallback onOpenDetails;
  final VoidCallback onPrepChat;

  const _AgendaCard({
    required this.app,
    required this.selectedDay,
    required this.parseDate,
    required this.onOpenDetails,
    required this.onPrepChat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = app.category;
    final catColor = category.color;

    final interviewDate = parseDate(app.interviewDate);
    final deadlineDate = parseDate(app.deadline);

    final bool isInterview = interviewDate != null && isSameDay(interviewDate, selectedDay);
    final String typeLabel = switch (category) {
      OpportunityCategory.hackathon => 'Hackathon',
      OpportunityCategory.event => 'Tech Event',
      OpportunityCategory.contest => 'Coding Contest',
      OpportunityCategory.job => isInterview ? 'Interview Round' : 'Application Deadline',
    };
    final Color typeColor = catColor;

    final targetDate = isInterview ? interviewDate : deadlineDate;
    String countdownStr = '';
    if (targetDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final diff = targetDate.difference(today).inDays;
      if (diff == 0) {
        countdownStr = 'Today!';
      } else if (diff == 1) {
        countdownStr = 'Tomorrow';
      } else if (diff > 1) {
        countdownStr = 'In $diff days';
      } else {
        countdownStr = 'Past';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration(context, borderRadius: AppTheme.radiusLg),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: onOpenDetails,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company / Platform Logo
                    CompanyLogoWidget(
                      company: app.company,
                      category: category,
                      size: 48,
                      borderRadius: 16,
                      showCategoryBadge: true,
                    ),
                    const SizedBox(width: 14),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  app.company,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (countdownStr.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (countdownStr == 'Today!' ? AppTheme.vibrantRed : AppTheme.orange).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    countdownStr,
                                    style: TextStyle(
                                      color: countdownStr == 'Today!' ? AppTheme.vibrantRed : AppTheme.orange,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            app.role,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
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
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: TextStyle(color: typeColor, fontSize: 10.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (isInterview && app.interviewTime.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkSurface : AppTheme.lightBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isDark ? AppTheme.borderDarkSubtle : AppTheme.borderLight),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 10, color: AppTheme.orange),
                                      const SizedBox(width: 3),
                                      Text(
                                        app.interviewTime,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: isDark ? AppTheme.borderDarkSubtle : AppTheme.borderLight),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: onPrepChat,
                      child: const Row(
                        children: [
                          Icon(Icons.psychology_rounded, size: 15, color: AppTheme.orange),
                          SizedBox(width: 5),
                          Text(
                            'Prep with Copilot',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.orange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
