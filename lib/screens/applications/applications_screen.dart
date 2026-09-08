import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme.dart';
import '../../controllers/application_controller.dart';
import '../../models/application.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/application_card.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/app_logo.dart';


import '../home/home_screen.dart';
import '../add_opportunity/add_opportunity_screen.dart';
import '../calendar/calendar_screen.dart';
import '../profile/profile_screen.dart';
import '../application_details/application_details_screen.dart';
import '../chat/chat_screen.dart';
import '../reminders/reminders_screen.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  OpportunityCategory? _filterCategory;
  ApplicationStatus? _filterStatus;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 1) return;
    Widget nextScreen;
    if (index == 0) {
      nextScreen = const HomeScreen();
    } else if (index == 2) {
      nextScreen = const RemindersScreen();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      body: Consumer<ApplicationController>(
        builder: (context, controller, _) {
          var apps = controller.applications;
          if (_searchQuery.isNotEmpty) {
            apps = apps.where((a) =>
                a.company.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                a.role.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          }
          if (_filterCategory != null) {
            apps = apps.where((a) => a.category == _filterCategory).toList();
          }
          if (_filterStatus != null) {
            apps = apps.where((a) => a.status == _filterStatus).toList();
          }

          final totalCount = controller.applications.length;
          final jobsCount = controller.applications.where((a) => a.category == OpportunityCategory.job).length;
          final hackathonsCount = controller.applications.where((a) => a.category == OpportunityCategory.hackathon).length;
          final eventsCount = controller.applications.where((a) => a.category == OpportunityCategory.event).length;
          final contestsCount = controller.applications.where((a) => a.category == OpportunityCategory.contest).length;

          return TexturedBackground(
            child: Column(
              children: [
                // ── Dark Hero Header ──
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
                        Row(children: [
                          const AppLogo(size: 46, emblemOnly: true),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Opportunities',
                                    style: TextStyle(color: AppTheme.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$totalCount tracked across career & events',
                                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                  style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        // Search bar
                        Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppTheme.darkCard,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: const TextStyle(color: AppTheme.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search company, event, or role...',
                              hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280), size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280), size: 18),
                                      onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

              // ── Category Filter Chips (Horizontal) ──
              Container(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: 'All Categories',
                      count: totalCount,
                      selected: _filterCategory == null,
                      onTap: () => setState(() => _filterCategory = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Jobs',
                      icon: Icons.work_outline_rounded,
                      count: jobsCount,
                      selected: _filterCategory == OpportunityCategory.job,
                      color: AppTheme.orange,
                      onTap: () => setState(() => _filterCategory = OpportunityCategory.job),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Hackathons',
                      icon: Icons.terminal_rounded,
                      count: hackathonsCount,
                      selected: _filterCategory == OpportunityCategory.hackathon,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => setState(() => _filterCategory = OpportunityCategory.hackathon),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Tech Events',
                      icon: Icons.event_note_rounded,
                      count: eventsCount,
                      selected: _filterCategory == OpportunityCategory.event,
                      color: const Color(0xFF10B981),
                      onTap: () => setState(() => _filterCategory = OpportunityCategory.event),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Contests',
                      icon: Icons.emoji_events_outlined,
                      count: contestsCount,
                      selected: _filterCategory == OpportunityCategory.contest,
                      color: const Color(0xFF3B82F6),
                      onTap: () => setState(() => _filterCategory = OpportunityCategory.contest),
                    ),
                  ],
                ),
              ),

              // ── Status Filter Chips (Sub-filter) ──
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  children: [
                    _StatusSmallChip(
                      label: 'All Statuses',
                      selected: _filterStatus == null,
                      onTap: () => setState(() => _filterStatus = null),
                    ),
                    const SizedBox(width: 6),
                    _StatusSmallChip(
                      label: 'Interviews',
                      selected: _filterStatus == ApplicationStatus.interview,
                      color: AppTheme.orange,
                      onTap: () => setState(() => _filterStatus = ApplicationStatus.interview),
                    ),
                    const SizedBox(width: 6),
                    _StatusSmallChip(
                      label: 'Action Req',
                      selected: _filterStatus == ApplicationStatus.actionRequired,
                      color: AppTheme.vibrantRed,
                      onTap: () => setState(() => _filterStatus = ApplicationStatus.actionRequired),
                    ),
                    const SizedBox(width: 6),
                    _StatusSmallChip(
                      label: 'Applied',
                      selected: _filterStatus == ApplicationStatus.applied,
                      color: AppTheme.vibrantBlue,
                      onTap: () => setState(() => _filterStatus = ApplicationStatus.applied),
                    ),
                    const SizedBox(width: 6),
                    _StatusSmallChip(
                      label: 'Waiting',
                      selected: _filterStatus == ApplicationStatus.waiting,
                      color: AppTheme.vibrantPurple,
                      onTap: () => setState(() => _filterStatus = ApplicationStatus.waiting),
                    ),
                  ],
                ),
              ),

              // ── List ──
              Expanded(
                child: apps.isEmpty
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkCard : AppTheme.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                            ),
                            child: Icon(Icons.search_off_rounded, size: 36,
                                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                          ),
                          const SizedBox(height: 16),
                          Text('No applications found', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 6),
                          Text(_searchQuery.isNotEmpty ? 'Try a different search' : 'Paste a message to get started',
                              style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                          if (_searchQuery.isNotEmpty || _filterStatus != null || _filterCategory != null) ...[
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _filterStatus = null;
                                  _filterCategory = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: AppTheme.orange.withValues(alpha: 0.3)),
                                ),
                                child: const Text('Clear All Filters', style: TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ]),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: apps.length,
                        itemBuilder: (_, i) {
                          final app = apps[i];
                          return Dismissible(
                            key: Key(app.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.vibrantRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: AppTheme.vibrantRed),
                            ),
                            confirmDismiss: (_) => showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: isDark ? AppTheme.darkCard : AppTheme.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
                                title: const Text('Delete?', style: TextStyle(fontWeight: FontWeight.w800)),
                                content: Text('Remove ${app.company} — ${app.role}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete', style: TextStyle(color: AppTheme.vibrantRed))),
                                ],
                              ),
                            ),
                            onDismissed: (_) {
                              controller.deleteApplication(app.id);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Removed ${app.company}'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  textColor: AppTheme.orange,
                                  onPressed: () => controller.addApplication(app),
                                ),
                              ));
                            },
                            child: ApplicationCard(
                              application: app,
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ApplicationDetailsScreen(application: app),
                              )),
                            ).animate().fadeIn(duration: 250.ms, delay: (i * 40).ms).slideY(begin: 0.05, end: 0),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },

      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 1, onTap: _onNavTap),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.color = AppTheme.orange,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : (isDark ? AppTheme.darkCard : AppTheme.white),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? Colors.transparent : (isDark ? AppTheme.borderDark : AppTheme.borderLight)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: selected ? AppTheme.white : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
            ),
            const SizedBox(width: 5),
          ],
          Text(label, style: TextStyle(
            color: selected ? AppTheme.white : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12.5,
          )),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: selected ? Colors.white24 : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count', style: TextStyle(
              color: selected ? AppTheme.white : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
              fontSize: 10, fontWeight: FontWeight.w700,
            )),
          ),
        ]),
      ),
    );
  }
}

class _StatusSmallChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusSmallChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : (isDark ? AppTheme.darkCanvas : AppTheme.lightBg),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? color : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
            width: selected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? color
                : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
