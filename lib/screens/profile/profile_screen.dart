import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme.dart';
import '../../controllers/application_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/application.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/textured_background.dart';


import '../home/home_screen.dart';
import '../applications/applications_screen.dart';
import '../add_opportunity/add_opportunity_screen.dart';
import '../calendar/calendar_screen.dart';
import '../chat/chat_screen.dart';
import '../reminders/reminders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  void _onNavTap(int index) {
    if (index == 6) return;
    Widget nextScreen;
    if (index == 0) {
      nextScreen = const HomeScreen();
    } else if (index == 1) {
      nextScreen = const ApplicationsScreen();
    } else if (index == 2) {
      nextScreen = const RemindersScreen();
    } else if (index == 3) {
      nextScreen = const AddOpportunityScreen();
    } else if (index == 4) {
      nextScreen = const CalendarScreen();
    } else {
      nextScreen = const ChatScreen();
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

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        title: const Text('Clear All Data?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('This will permanently delete all tracked applications. Are you sure?',
            style: TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          GestureDetector(
            onTap: () async {
              Navigator.pop(ctx);
              final controller = context.read<ApplicationController>();
              final apps = List.of(controller.applications);
              for (final app in apps) {
                await controller.deleteApplication(app.id);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All data cleared'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: AppTheme.vibrantRed, borderRadius: BorderRadius.circular(100)),
              child: const Text('Clear All', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      body: Consumer2<ApplicationController, ThemeController>(
        builder: (context, appCtrl, themeCtrl, _) {
          final apps = appCtrl.applications;
          final total = apps.length;
          final interviews = apps.where((a) => a.status == ApplicationStatus.interview).length;
          final applied = apps.where((a) => a.status == ApplicationStatus.applied).length;
          final waiting = apps.where((a) => a.status == ApplicationStatus.waiting).length;

          final jobsCount = apps.where((a) => a.category == OpportunityCategory.job).length;
          final hacksCount = apps.where((a) => a.category == OpportunityCategory.hackathon).length;
          final eventsCount = apps.where((a) => a.category == OpportunityCategory.event).length;
          final contestsCount = apps.where((a) => a.category == OpportunityCategory.contest).length;

          return TexturedBackground(
            child: CustomScrollView(
              slivers: [
                // ── Dark Hero Header ──
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
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                            child: Column(
                              children: [
                                // Avatar
                                Container(
                                  width: 88, height: 88,
                                  decoration: BoxDecoration(
                                    color: AppTheme.orange,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white12, width: 3),
                                  ),
                                  child: const Center(
                                    child: Text('L', style: TextStyle(color: AppTheme.white, fontSize: 36, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text('Laksh', style: TextStyle(color: AppTheme.white, fontSize: 24, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                const Text('laksh@example.com', style: TextStyle(color: AppTheme.textMutedDark, fontSize: 13)),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.orange,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.verified_rounded, color: AppTheme.white, size: 14),
                                    SizedBox(width: 6),
                                    Text('AI Copilot Pro', style: TextStyle(color: AppTheme.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                  ]),
                                ),
                                const SizedBox(height: 28),
                                // Stats row
                                Row(children: [
                                  _StatCol(label: 'Total', value: '$total'),
                                  const _Divider(),
                                  _StatCol(label: 'Applied', value: '$applied'),
                                  const _Divider(),
                                  _StatCol(label: 'Interviews', value: '$interviews'),
                                  const _Divider(),
                                  _StatCol(label: 'Waiting', value: '$waiting'),
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

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Category Portfolio ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader('Opportunity Portfolio'),
                        const SizedBox(height: 10),
                        _SettingsCard(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  _CategoryMiniStat(
                                    label: 'Jobs',
                                    count: jobsCount,
                                    icon: Icons.work_rounded,
                                    color: AppTheme.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  _CategoryMiniStat(
                                    label: 'Hackathons',
                                    count: hacksCount,
                                    icon: Icons.terminal_rounded,
                                    color: const Color(0xFF8B5CF6),
                                  ),
                                  const SizedBox(width: 8),
                                  _CategoryMiniStat(
                                    label: 'Events',
                                    count: eventsCount,
                                    icon: Icons.event_note_rounded,
                                    color: const Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 8),
                                  _CategoryMiniStat(
                                    label: 'Contests',
                                    count: contestsCount,
                                    icon: Icons.emoji_events_rounded,
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(delay: 50.ms),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── General Settings ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader('General'),
                        const SizedBox(height: 10),
                        _SettingsCard(children: [
                          _SettingsRow(
                            icon: Icons.notifications_rounded,
                            iconColor: AppTheme.vibrantOrange,
                            title: 'Notifications',
                            trailing: Switch(
                              value: _notificationsEnabled,
                              onChanged: (v) => setState(() => _notificationsEnabled = v),
                              activeThumbColor: AppTheme.white,
                              activeTrackColor: AppTheme.orange,
                            ),
                          ),
                          const _Separator(),
                          _SettingsRow(
                            icon: Icons.dark_mode_rounded,
                            iconColor: AppTheme.vibrantPurple,
                            title: 'Dark Mode',
                            trailing: Switch(
                              value: isDark,
                              onChanged: (_) => themeCtrl.toggleTheme(),
                              activeThumbColor: AppTheme.white,
                              activeTrackColor: AppTheme.orange,
                            ),
                          ),
                          const _Separator(),
                          _SettingsRow(
                            icon: Icons.person_outline_rounded,
                            iconColor: AppTheme.vibrantBlue,
                            title: 'Personal Information',
                            onTap: () {},
                          ),
                          const _Separator(),
                          _SettingsRow(
                            icon: Icons.link_rounded,
                            iconColor: AppTheme.vibrantGreen,
                            title: 'Linked Accounts',
                            onTap: () {},
                          ),
                        ]),
                      ],
                    ).animate().fadeIn(delay: 100.ms),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Career Analytics ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader('Career Analytics'),
                        const SizedBox(height: 10),
                        _SettingsCard(children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: Text('Interview Conversion Rate',
                                      style: Theme.of(context).textTheme.titleMedium)),
                                  Text(total > 0 ? '${((interviews / total) * 100).round()}%' : '0%',
                                      style: const TextStyle(color: AppTheme.orange, fontSize: 18, fontWeight: FontWeight.w800)),
                                ]),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: LinearProgressIndicator(
                                    value: total > 0 ? interviews / total : 0,
                                    minHeight: 8,
                                    backgroundColor: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                                    valueColor: const AlwaysStoppedAnimation(AppTheme.orange),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  _MiniStat(label: 'Applied', value: '$applied', color: AppTheme.vibrantBlue),
                                  _MiniStat(label: 'Interviews', value: '$interviews', color: AppTheme.vibrantOrange),
                                  _MiniStat(label: 'Waiting', value: '$waiting', color: AppTheme.vibrantPurple),
                                ]),
                              ],
                            ),
                          ),
                        ]),
                      ],
                    ).animate().fadeIn(delay: 200.ms),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Security & Privacy ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader('Security & Privacy'),
                        const SizedBox(height: 10),
                        _SettingsCard(children: [
                          _SettingsRow(
                            icon: Icons.lock_rounded,
                            iconColor: AppTheme.vibrantRed,
                            title: 'Security Settings',
                            onTap: () {},
                          ),
                          const _Separator(),
                          _SettingsRow(
                            icon: Icons.delete_outline_rounded,
                            iconColor: AppTheme.vibrantRed,
                            title: 'Clear All Data',
                            titleColor: AppTheme.vibrantRed,
                            onTap: _confirmClearData,
                          ),
                        ]),
                      ],
                    ).animate().fadeIn(delay: 300.ms),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        );
      },

      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 6, onTap: _onNavTap),
    );
  }
}

// ─── Helpers ───

class _StatCol extends StatelessWidget {
  final String label, value;
  const _StatCol({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: const TextStyle(color: AppTheme.white, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
    ]),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: Colors.white10);
}

class _Separator extends StatelessWidget {
  const _Separator();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight);
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.titleLarge);
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: titleColor))),
          trailing ?? const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFADB5BD)),
        ]),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
    const SizedBox(height: 2),
    Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
  ]);
}

class _CategoryMiniStat extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _CategoryMiniStat({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.25 : 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
