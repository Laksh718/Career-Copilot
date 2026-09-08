import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme.dart';
import '../../controllers/ai_controller.dart';
import '../../widgets/animated_bg.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/bottom_navigation.dart';

import '../../services/shared_ingestion_service.dart';
import '../home/home_screen.dart';
import '../applications/applications_screen.dart';
import '../calendar/calendar_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_screen.dart';
import '../reminders/reminders_screen.dart';
import 'analysis_result_screen.dart';

class AddOpportunityScreen extends StatefulWidget {
  const AddOpportunityScreen({super.key});

  @override
  State<AddOpportunityScreen> createState() => _AddOpportunityScreenState();
}

class _AddOpportunityScreenState extends State<AddOpportunityScreen> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 3) return;

    Widget nextScreen;
    if (index == 0) {
      nextScreen = const HomeScreen();
    } else if (index == 1) {
      nextScreen = const ApplicationsScreen();
    } else if (index == 2) {
      nextScreen = const RemindersScreen();
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

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      _controller.text = data.text!;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  void _insertGoogleEmail() {
    _controller.text =
        'Google Recruiting: Hi Laksh, We are excited to invite you to interview for the Software Engineer Intern role. '
        'Your technical interview is scheduled for tomorrow at 2:00 PM. '
        'Please review the attached guide and have your code editor ready. '
        'Stipend: \$9,500/month. '
        'Deadline to confirm: Sep 15.';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  void _insertAmazonWhatsApp() {
    _controller.text =
        'Amazon Student Programs: Congratulations! Your application for SDE Intern has progressed. '
        'Interview round scheduled Monday at 10 AM. '
        'Stipend: ₹85,000/month. '
        'Please bring your college ID & resume. Applications close September 25.';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  void _insertEthGlobalHackathon() {
    _controller.text =
        'ETHGlobal Hackathon: Official Invitation to participate in the global Web3 hackathon! '
        'Event Dates: Nov 15-17. \$500,000 in sponsor bounties. '
        'Submission deadline: Nov 10. Register on Devpost.';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  Future<void> _autoAddShared() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste or enter a shared email/message first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await SharedIngestionService().processAndAutoAdd(
      context,
      text,
      sourceName: 'Quick Auto-Add',
    );
  }

  Future<void> _analyze() async {
    if (_controller.text.trim().isEmpty) return;

    final aiController = context.read<AIController>();
    final result = await aiController.analyzeMessage(_controller.text);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisResultScreen(extraction: result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedBg(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: AppTheme.primaryYellow, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Opportunity',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Paste or type the message you received',
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 20),

                // Quick action chips & Sample mail forwards
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ActionChip(
                        icon: Icons.content_paste_rounded,
                        label: 'Paste Clipboard',
                        onTap: _pasteFromClipboard,
                      ),
                      const SizedBox(width: 8),
                      _ActionChip(
                        icon: Icons.mail_outline_rounded,
                        label: 'Google Email Sample',
                        onTap: _insertGoogleEmail,
                      ),
                      const SizedBox(width: 8),
                      _ActionChip(
                        icon: Icons.mark_chat_unread_outlined,
                        label: 'Amazon WhatsApp Sample',
                        onTap: _insertAmazonWhatsApp,
                      ),
                      const SizedBox(width: 8),
                      _ActionChip(
                        icon: Icons.terminal_rounded,
                        label: 'ETHGlobal Sample',
                        onTap: _insertEthGlobalHackathon,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 14),

                // Text input area
                Expanded(
                  child: Container(
                    decoration: AppTheme.flatDecoration(context, borderRadius: AppTheme.radiusLg),
                    child: Stack(
                      children: [
                        TextField(
                          controller: _controller,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Forward or paste any job offer, interview email, or WhatsApp message here...',
                            hintMaxLines: 4,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                            fillColor: Colors.transparent,
                            filled: true,
                            hintStyle: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        // Clear button
                        if (_hasText)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _controller.clear(),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).dividerColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.close_rounded, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 14),

                // Dual-Action Buttons (Auto-Add 1-Tap vs Review & Customize)
                Consumer<AIController>(
                  builder: (context, ai, child) {
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: GradientButton(
                            label: 'Auto-Add to Pipeline',
                            icon: Icons.bolt_rounded,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                            isLoading: ai.isAnalyzing,
                            onPressed: ai.isAnalyzing ? null : _autoAddShared,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                            ),
                            icon: const Icon(Icons.tune_rounded, size: 18),
                            label: const Text(
                              'Review',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onPressed: ai.isAnalyzing ? null : _analyze,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 3, onTap: _onNavTap),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: AppTheme.flatDecoration(context, borderRadius: AppTheme.radiusMd),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryYellow),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.primaryYellow,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
