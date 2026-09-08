import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme.dart';
import '../../controllers/application_controller.dart';
import '../../controllers/ai_controller.dart';
import '../../models/application.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/application_card.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/app_logo.dart';

import '../add_opportunity/add_opportunity_screen.dart';
import '../add_opportunity/analysis_result_screen.dart';
import '../applications/applications_screen.dart';
import '../calendar/calendar_screen.dart';
import '../profile/profile_screen.dart';
import '../application_details/application_details_screen.dart';
import '../chat/chat_screen.dart';
import '../reminders/reminders_screen.dart';
import '../../widgets/company_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _currentIndex = 0;
  OpportunityCategory? _selectedCategory;

  void _onNavTap(int index) {
    if (index == 0) return;
    Widget nextScreen;
    if (index == 1) {
      nextScreen = const ApplicationsScreen();
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

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showPasteSheet() {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkCard
                  : AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.orange,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_link_rounded, color: AppTheme.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('New Opportunity', style: Theme.of(context).textTheme.titleLarge),
                    Text('Job, Hackathon, or Event announcement', style: Theme.of(context).textTheme.bodySmall),
                  ]),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.borderDark
                            : AppTheme.lightBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkCanvas
                        : AppTheme.lightBg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.borderDark : AppTheme.borderLight),
                  ),
                  child: TextField(
                    controller: textController,
                    maxLines: null, expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'Paste job posting, hackathon invite, summit brochure...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChipButton(
                      icon: Icons.content_paste_rounded,
                      label: 'Paste',
                      onTap: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null && data!.text!.isNotEmpty) {
                          textController.text = data.text!;
                        }
                      },
                    ),
                    _ChipButton(
                      icon: Icons.work_outline_rounded,
                      label: 'Job Demo',
                      onTap: () {
                        textController.text =
                            'Hi Laksh, XYZ Technologies is hiring Software Engineering Interns. '
                            'Your interview is scheduled Monday at 8 PM. '
                            'Please submit your resume and college ID. '
                            'Applications close September 12.';
                      },
                    ),
                    _ChipButton(
                      icon: Icons.terminal_rounded,
                      label: 'Hackathon Demo',
                      onTap: () {
                        textController.text =
                            'ETHGlobal AI Hackathon 2026 registration is live! '
                            '48-hour global virtual hackathon on September 10-12. '
                            'Tracks: Autonomous AI Agents, Web3 & Zero Knowledge. '
                            'Total prize pool: \$45,000. Team submissions deadline Sept 10.';
                      },
                    ),
                    _ChipButton(
                      icon: Icons.event_note_rounded,
                      label: 'Tech Event Demo',
                      onTap: () {
                        textController.text =
                            'Confirmed RSVP: Google Cloud Summit 2026 on September 14 at 10:00 AM. '
                            'Keynote on Generative AI on Mobile & Cloud Architecture. '
                            'Location: San Francisco Convention Center & Online.';
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Consumer<AIController>(builder: (context, ai, _) {
                  return GestureDetector(
                    onTap: ai.isAnalyzing ? null : () async {
                      if (textController.text.trim().isEmpty) return;
                      final result = await ai.analyzeMessage(textController.text);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => AnalysisResultScreen(extraction: result),
                        ));
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.orange, Color(0xFFFF8C42)],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        boxShadow: const [
                          BoxShadow(color: AppTheme.orangeGlow, blurRadius: 10, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Center(
                        child: ai.isAnalyzing
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.white))
                            : Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.bolt_rounded, color: AppTheme.white, size: 20),
                                const SizedBox(width: 8),
                                Text('Extract Opportunity', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.white, fontWeight: FontWeight.w800)),
                              ]),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
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
          final allApps = controller.applications;
          final total = allApps.length;
          final jobsCount = allApps.where((a) => a.category == OpportunityCategory.job).length;
          final hackathonsCount = allApps.where((a) => a.category == OpportunityCategory.hackathon).length;
          final eventsCount = allApps.where((a) => a.category == OpportunityCategory.event).length;
          final contestsCount = allApps.where((a) => a.category == OpportunityCategory.contest).length;

          // Urgent items for Attention / Radar
          final urgent = allApps.where((a) =>
              (a.status == ApplicationStatus.interview || a.status == ApplicationStatus.actionRequired) &&
              (a.interviewDate.isNotEmpty || a.deadline.isNotEmpty)).toList();

          // Filtered list by category selection
          var displayApps = _selectedCategory == null
              ? allApps
              : allApps.where((a) => a.category == _selectedCategory).toList();

          // Top spotlight opportunity
          final Application? spotlightApp = urgent.isNotEmpty ? urgent.first : (allApps.isNotEmpty ? allApps.first : null);

          return TexturedBackground(
            child: CustomScrollView(
              slivers: [
                // ── Hero Header with Bold Multi-Color Gradient Typography ──
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
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Bar: Eyebrow Tag + Avatar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Logo badge instead of text pill
                                const AppLogo(size: 38, onDark: true),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => _onNavTap(5),
                                  child: Container(
                                    width: 40,
                                    height: 40,
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
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Greeting
                            Text(
                              '${_getGreeting()}, Laksh 👋',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Bold Multi-Color Gradient Headline
                            const Text(
                              'Supercharge Your',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                                height: 1.15,
                              ),
                            ),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFFF6B35), // Solar Orange
                                  Color(0xFFF59E0B), // Neon Amber
                                  Color(0xFFA855F7), // Neon Violet
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'Career & Events.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Track jobs, tech events, hackathons & ace interviews.',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Interactive Category Stat Counter Pills
                            Row(
                              children: [
                                _CategoryStatPill(
                                  label: 'Jobs',
                                  value: '$jobsCount',
                                  color: AppTheme.orange,
                                  icon: Icons.work_rounded,
                                  isSelected: _selectedCategory == OpportunityCategory.job,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = _selectedCategory == OpportunityCategory.job
                                          ? null
                                          : OpportunityCategory.job;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                _CategoryStatPill(
                                  label: 'Hacks',
                                  value: '$hackathonsCount',
                                  color: const Color(0xFF8B5CF6),
                                  icon: Icons.terminal_rounded,
                                  isSelected: _selectedCategory == OpportunityCategory.hackathon,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = _selectedCategory == OpportunityCategory.hackathon
                                          ? null
                                          : OpportunityCategory.hackathon;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                _CategoryStatPill(
                                  label: 'Events',
                                  value: '$eventsCount',
                                  color: const Color(0xFF10B981),
                                  icon: Icons.event_note_rounded,
                                  isSelected: _selectedCategory == OpportunityCategory.event,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = _selectedCategory == OpportunityCategory.event
                                          ? null
                                          : OpportunityCategory.event;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                _CategoryStatPill(
                                  label: 'Contests',
                                  value: '$contestsCount',
                                  color: const Color(0xFF3B82F6),
                                  icon: Icons.emoji_events_rounded,
                                  isSelected: _selectedCategory == OpportunityCategory.contest,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = _selectedCategory == OpportunityCategory.contest
                                          ? null
                                          : OpportunityCategory.contest;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

                const SliverToBoxAdapter(child: SizedBox(height: 22)),

                // ── Copilot Action Radar Spotlight Card ──
                if (spotlightApp != null)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF1E1B4B), const Color(0xFF172554)]
                                : [const Color(0xFFEEF2FF), const Color(0xFFF0FDF4)],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(
                            color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.2 : 0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CompanyLogoWidget(
                                  company: spotlightApp.company,
                                  category: spotlightApp.category,
                                  size: 34,
                                  borderRadius: 10,
                                  showCategoryBadge: true,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'SPOTLIGHT • ${spotlightApp.category.shortLabel.toUpperCase()}',
                                    style: TextStyle(
                                      color: spotlightApp.category.color,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.orange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      spotlightApp.interviewDate.isNotEmpty
                                          ? spotlightApp.interviewDate
                                          : spotlightApp.deadline,
                                      style: const TextStyle(
                                        color: AppTheme.orange,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              spotlightApp.company,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                            ),
                            Text(
                              spotlightApp.role,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 12.5,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ApplicationDetailsScreen(application: spotlightApp),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppTheme.darkCard : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'View Opportunity',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _onNavTap(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      decoration: BoxDecoration(
                                        color: spotlightApp.category.color,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.psychology_rounded, color: Colors.white, size: 16),
                                          SizedBox(width: 6),
                                          Text(
                                            'Action Prep',
                                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 150.ms, duration: 350.ms),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Quick Actions ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick Launch', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _QuickActionCard(
                            icon: Icons.add_circle_outline_rounded,
                            label: '+ Track Opp',
                            color: AppTheme.orange,
                            onTap: _showPasteSheet,
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: _QuickActionCard(
                            icon: Icons.calendar_month_rounded,
                            label: 'Calendar',
                            color: AppTheme.vibrantBlue,
                            onTap: () => _onNavTap(4),
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: _QuickActionCard(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Copilot Chat',
                            color: const Color(0xFF8B5CF6),
                            onTap: () => _onNavTap(5),
                          )),
                        ]),
                      ],
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),

                // ── Category Filter Bar for Opportunities ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Tracked Opportunities',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _onNavTap(1),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View All',
                                    style: TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppTheme.orange),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Category Filter Pills
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _FilterPill(
                                label: 'All',
                                icon: Icons.grid_view_rounded,
                                isSelected: _selectedCategory == null,
                                count: total,
                                activeColor: AppTheme.orange,
                                onTap: () => setState(() => _selectedCategory = null),
                              ),
                              const SizedBox(width: 8),
                              _FilterPill(
                                label: 'Jobs',
                                icon: Icons.work_rounded,
                                isSelected: _selectedCategory == OpportunityCategory.job,
                                count: jobsCount,
                                activeColor: AppTheme.orange,
                                onTap: () => setState(() => _selectedCategory = OpportunityCategory.job),
                              ),
                              const SizedBox(width: 8),
                              _FilterPill(
                                label: 'Hackathons',
                                icon: Icons.terminal_rounded,
                                isSelected: _selectedCategory == OpportunityCategory.hackathon,
                                count: hackathonsCount,
                                activeColor: const Color(0xFF8B5CF6),
                                onTap: () => setState(() => _selectedCategory = OpportunityCategory.hackathon),
                              ),
                              const SizedBox(width: 8),
                              _FilterPill(
                                label: 'Events',
                                icon: Icons.event_note_rounded,
                                isSelected: _selectedCategory == OpportunityCategory.event,
                                count: eventsCount,
                                activeColor: const Color(0xFF10B981),
                                onTap: () => setState(() => _selectedCategory = OpportunityCategory.event),
                              ),
                              const SizedBox(width: 8),
                              _FilterPill(
                                label: 'Contests',
                                icon: Icons.emoji_events_rounded,
                                isSelected: _selectedCategory == OpportunityCategory.contest,
                                count: contestsCount,
                                activeColor: const Color(0xFF3B82F6),
                                onTap: () => setState(() => _selectedCategory = OpportunityCategory.contest),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // ── Opportunity Cards List ──
                if (displayApps.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: AppTheme.cardDecoration(context),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 36, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                            const SizedBox(height: 10),
                            Text(
                              'No ${_selectedCategory?.label ?? 'opportunities'} tracked yet',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap "+ Track Opp" above to paste an invite or posting.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final app = displayApps[i];
                          return ApplicationCard(
                            application: app,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ApplicationDetailsScreen(application: app),
                              ),
                            ),
                          ).animate().fadeIn(duration: 200.ms, delay: (i * 30).ms).slideY(begin: 0.05, end: 0);
                        },
                        childCount: displayApps.length > 5 ? 5 : displayApps.length,
                      ),
                    ),
                  ),

                // ── Pro Tip Card ──
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.vibrantGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.lightbulb_rounded, color: AppTheme.vibrantGreen, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pro Career & Event Tip',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: AppTheme.vibrantGreen,
                                        letterSpacing: 0.3,
                                      ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Tech events, hackathons and coding projects are proven accelerators for top engineering careers.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: _currentIndex, onTap: _onNavTap),
    );
  }
}

// ── Category Stat Pill ──
class _CategoryStatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryStatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.22)
                : color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.25),
              width: isSelected ? 1.5 : 0.8,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter Pill ──
class _FilterPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final int? count;
  final Color activeColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    this.color = AppTheme.orange,
    this.icon,
    this.count,
    Color? activeColor,
    required this.isSelected,
    required this.onTap,
  }) : activeColor = activeColor ?? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? AppTheme.darkCard : AppTheme.white),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? AppTheme.textLight : AppTheme.textDark),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Quick Action Card ──
class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: AppTheme.cardDecoration(context),
          child: Column(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(14)),
              child: Icon(widget.icon, color: AppTheme.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(widget.label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700, fontSize: 11),
                textAlign: TextAlign.center, maxLines: 2),
          ]),
        ),
      ),
    );
  }
}

// ── Chip Button ──
class _ChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ChipButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCanvas : AppTheme.lightBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.borderDark : AppTheme.borderLight),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: AppTheme.orange),
          const SizedBox(width: 5),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
        ]),
      ),
    );
  }
}
