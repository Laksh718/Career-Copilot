import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme.dart';
import '../../controllers/application_controller.dart';
import '../../controllers/ai_controller.dart';
import '../../models/application.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/gemini_api_key_sheet.dart';

import '../home/home_screen.dart';
import '../applications/applications_screen.dart';
import '../add_opportunity/add_opportunity_screen.dart';
import '../calendar/calendar_screen.dart';
import '../profile/profile_screen.dart';
import '../application_details/application_details_screen.dart';
import '../reminders/reminders_screen.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<Application>? linkedApplications;

  _ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.linkedApplications,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int)? onNavigate;

  const ChatScreen({
    super.key,
    this.selectedIndex = 3,
    this.onNavigate,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool? _showGeminiBanner = true;
  int _tab = 0;

  final List<Map<String, dynamic>> _promptCategories = [
    {
      "label": "Upcoming Interviews",
      "query": "Show my upcoming interviews and preparation tips",
      "icon": Icons.calendar_today_rounded,
    },
    {
      "label": "Application Summary",
      "query": "Summarize the status of all my applications",
      "icon": Icons.bar_chart_rounded,
    },
    {
      "label": "Draft Follow-up",
      "query": "Draft a professional follow-up email for my latest application",
      "icon": Icons.mail_outline_rounded,
    },
    {
      "label": "Check Deadlines",
      "query": "What deadlines do I have coming up soon?",
      "icon": Icons.hourglass_top_rounded,
    },
    {
      "label": "Interview Prep Q&A",
      "query": "Give me common interview questions and the STAR method",
      "icon": Icons.quiz_outlined,
    },
    {
      "label": "Standout Tips",
      "query": "How can I make my tech application stand out to recruiters?",
      "icon": Icons.lightbulb_outline_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _showGeminiBanner = true;
    _messages.add(
      _ChatMessage(
        text: "Hello Laksh! I'm your **Career Copilot** intelligence assistant.\n\n"
            "I'm synchronized with your tracked applications, upcoming interviews, and deadlines. "
            "Ask me anything, or tap a suggestion below to get started!",
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 5) return;
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: query, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    final apps = context.read<ApplicationController>().applications;
    String reply;

    try {
      final aiController = context.read<AIController>();
      reply = await aiController.chatWithCareerCoach(query, apps);
    } catch (e) {
      reply = "Here's a quick update on your applications:\n\n"
          "• Total tracked: ${apps.length}\n"
          "• Interviews: ${apps.where((a) => a.interviewDate.isNotEmpty).length}\n\n"
          "Ask me about any specific company or interview prep!";
    }

    // Identify if any tracked application is mentioned
    final lower = '$query $reply'.toLowerCase();
    final mentionedApps = apps.where((a) {
      final comp = a.company.toLowerCase();
      return comp.isNotEmpty && lower.contains(comp);
    }).toList();

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(
            text: reply,
            isUser: false,
            linkedApplications: mentionedApps.isNotEmpty ? mentionedApps : null,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _showQuickPromptsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(width: 12),
                  Text(
                    'Quick Career Prompts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._promptCategories.map(
                (item) => ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item["icon"] as IconData, size: 18, color: AppTheme.orange),
                  ),
                  title: Text(item["label"] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(item["query"] as String, style: Theme.of(context).textTheme.bodySmall),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.orange),
                  onTap: () {
                    Navigator.pop(ctx);
                    _send(item["query"] as String);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        title: const Text('Clear Conversation?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('This will reset your current chat history with your Career Copilot.', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.vibrantRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _messages.add(
                  _ChatMessage(
                    text: "Conversation reset! What can I help you prepare or research today?",
                    isUser: false,
                  ),
                );
              });
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: TexturedBackground(
        child: Column(
          children: [
            // ── Modern Glassmorphic Top Header ──
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
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Back button, Title & Clear Chat Action
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _onNavTap(0),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Icon(Icons.arrow_back_rounded, color: AppTheme.white, size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const AppLogo(size: 42, emblemOnly: true),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Flexible(
                                      child: Text(
                                        'Career Copilot',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: AppTheme.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [AppTheme.orange, Color(0xFFFF8A5C)],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.verified_rounded, color: Colors.white, size: 10),
                                          SizedBox(width: 3),
                                          Text(
                                            'PRO',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Consumer<AIController>(
                                  builder: (context, aiCtrl, _) {
                                    final isGemini = aiCtrl.isGeminiActive;
                                    return GestureDetector(
                                      onTap: () => showGeminiApiKeySheet(context),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: isGemini ? AppTheme.vibrantGreen : AppTheme.orange,
                                              shape: BoxShape.circle,
                                            ),
                                          ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.8, end: 1.3, duration: 1200.ms),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              isGemini ? 'Gemini 2.5 Active' : 'Offline AI • Tap to connect',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(
                                                color: isGemini ? const Color(0xFF6EE7B7) : const Color(0xFFFDBA74),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                            tooltip: 'Reset Conversation',
                            onPressed: _clearChat,
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _onNavTap(5),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppTheme.orange,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.orange.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'L',
                                  style: TextStyle(
                                    color: AppTheme.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Segmented Tabs: Copilot AI | Saved Tips | Prompts
                      Container(
                        height: 40,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          children: [
                            _Tab(label: 'Copilot Coach', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                            _Tab(label: 'Tips & Guides', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
                            _Tab(label: 'Archived', selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
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
            // ── Gemini Activation Quick Banner (Offline Mode) ──
            if (_tab == 0)
              Consumer<AIController>(
                builder: (context, aiCtrl, _) {
                  final showBanner = _showGeminiBanner ?? true;
                  if (aiCtrl.isGeminiActive || !showBanner) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.orange.withValues(alpha: isDark ? 0.20 : 0.12),
                          const Color(0xFFFF8A5C).withValues(alpha: isDark ? 0.10 : 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.orange.withValues(alpha: isDark ? 0.35 : 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.orange.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bolt_rounded, color: AppTheme.orange, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Local AI Mode',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                              Text(
                                'Connect Gemini API Key for live AI reasoning.',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => showGeminiApiKeySheet(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Connect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _showGeminiBanner = false),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // ── Main Body ──
            Expanded(
              child: _tab == 1
                  ? _TipsGuideView(onSelectPrompt: (p) {
                      setState(() => _tab = 0);
                      _send(p);
                    })
                  : _tab == 2
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.archive_outlined, size: 48, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                              const SizedBox(height: 12),
                              Text('No archived chats', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text('Saved conversations will show here.', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          itemCount: _messages.length,
                          itemBuilder: (ctx, i) => _Bubble(
                            msg: _messages[i],
                            onQuickPrompt: _send,
                          ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.08, end: 0),
                        ),
            ),

            // ── Typing Indicator ──
            if (_isTyping && _tab == 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.psychology_rounded, color: AppTheme.orange, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Copilot is thinking',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const _TypingDot(delay: 0),
                        const SizedBox(width: 3),
                        const _TypingDot(delay: 150),
                        const SizedBox(width: 3),
                        const _TypingDot(delay: 300),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Suggestion Carousel ──
            if (_tab == 0)
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _promptCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final item = _promptCategories[i];
                    return GestureDetector(
                      onTap: () => _send(item["query"] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : AppTheme.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppTheme.orange.withValues(alpha: isDark ? 0.35 : 0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.orange.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item["icon"] != null) ...[
                              Icon(
                                item["icon"] as IconData,
                                size: 13,
                                color: AppTheme.orange,
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              item["label"] as String,
                              style: TextStyle(
                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // ── Input Area ──
            if (_tab == 0)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.white,
                  border: Border(top: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Quick prompts trigger
                      GestureDetector(
                        onTap: _showQuickPromptsSheet,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.orange.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.orange, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Text Field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : AppTheme.lightBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _textController,
                                  onSubmitted: _send,
                                  style: TextStyle(
                                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Ask Copilot anything...',
                                    hintStyle: TextStyle(
                                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Send Button
                      GestureDetector(
                        onTap: () => _send(_textController.text),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.orange, Color(0xFFFF8A5C)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.orange.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_upward_rounded, color: AppTheme.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 5, onTap: _onNavTap),
    );
  }
}

// ── Tab Widget ──
class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          decoration: BoxDecoration(
            color: selected ? Colors.white.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.white : const Color(0xFF94A3B8),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Rich Chat Bubble ──
class _Bubble extends StatelessWidget {
  final _ChatMessage msg;
  final Function(String) onQuickPrompt;

  const _Bubble({required this.msg, required this.onQuickPrompt});

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: msg.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Copied response to clipboard'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = msg.isUser;
    final timeStr = DateFormat.jm().format(msg.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI Avatar
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.orange, Color(0xFFFF8A5C)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.orange.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.bolt_rounded, color: AppTheme.white, size: 18),
            ),
          ],

          // Bubble Content
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.orange
                        : (isDark ? AppTheme.darkCard : AppTheme.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    boxShadow: [
                      if (!isUser)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Structured Message Rendering
                      if (isUser)
                        _UserMessageText(text: msg.text)
                      else
                        _StructuredAiResponse(text: msg.text),

                      // Linked Applications Mini Cards
                      if (msg.linkedApplications != null && msg.linkedApplications!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Text(
                          'Referenced Applications:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...msg.linkedApplications!.map(
                          (app) => GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ApplicationDetailsScreen(application: app),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurface : AppTheme.lightBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? AppTheme.borderDarkSubtle : AppTheme.borderLight),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          app.company,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                          ),
                                        ),
                                        Text(
                                          app.role,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusChip(status: app.status),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.orange),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Bottom actions (Timestamp & Copy)
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 10,
                              color: isUser
                                  ? Colors.white70
                                  : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                            ),
                          ),
                          if (!isUser) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _copy(context),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 13,
                                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
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
          ),

          // User Avatar
          if (isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, bottom: 4),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.borderLight,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
              ),
              child: Icon(
                Icons.person_rounded,
                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section Parsing Models ──
enum _AiSectionType {
  summary,
  highlights,
  actionPlan,
  template,
  proTip,
  general,
}

class _AiSection {
  final _AiSectionType type;
  final String title;
  final String content;

  _AiSection({required this.type, required this.title, required this.content});
}

List<_AiSection> _parseAiResponse(String rawText) {
  final sections = <_AiSection>[];
  final lines = rawText.split('\n');

  String? currentHeader;
  final currentLines = <String>[];

  void pushSection() {
    final content = currentLines.join('\n').trim();
    if (content.isNotEmpty) {
      if (currentHeader == null) {
        sections.add(_AiSection(
          type: _AiSectionType.general,
          title: 'Overview',
          content: content,
        ));
      } else {
        final lower = currentHeader.toLowerCase().trim();
        _AiSectionType type;
        if (lower.contains('summary') || lower.contains('overview') || lower.contains('tl;dr')) {
          type = _AiSectionType.summary;
        } else if (lower.contains('highlight') || lower.contains('takeaway') || lower.contains('key point') || lower.contains('insights')) {
          type = _AiSectionType.highlights;
        } else if (lower.contains('action') || lower.contains('step') || lower.contains('plan') || lower.contains('roadmap')) {
          type = _AiSectionType.actionPlan;
        } else if (lower.contains('template') || lower.contains('draft') || lower.contains('script') || lower.contains('email') || lower.contains('sample') || lower.contains('message')) {
          type = _AiSectionType.template;
        } else if (lower.contains('tip') || lower.contains('advice') || lower.contains('recommendation') || lower.contains('note')) {
          type = _AiSectionType.proTip;
        } else {
          type = _AiSectionType.general;
        }
        sections.add(_AiSection(
          type: type,
          title: currentHeader,
          content: content,
        ));
      }
    }
    currentLines.clear();
  }

  for (final line in lines) {
    final trimmed = line.trim();
    // Match headers starting with ### or ## or bolded headers **SECTION:**
    if (trimmed.startsWith('###') || trimmed.startsWith('##') || (trimmed.startsWith('**') && trimmed.endsWith('**') && trimmed.length < 35)) {
      final cleanHeader = trimmed
          .replaceAll(RegExp(r'^#{2,4}\s*'), '')
          .replaceAll('**', '')
          .replaceAll(':', '')
          .trim();
      if (cleanHeader.isNotEmpty) {
        pushSection();
        currentHeader = cleanHeader;
        continue;
      }
    }
    currentLines.add(line);
  }
  pushSection();

  if (sections.isEmpty && rawText.trim().isNotEmpty) {
    sections.add(_AiSection(
      type: _AiSectionType.general,
      title: 'Response',
      content: rawText.trim(),
    ));
  }

  return sections;
}

// ── Structured AI Response Widget ──
class _StructuredAiResponse extends StatelessWidget {
  final String text;

  const _StructuredAiResponse({required this.text});

  @override
  Widget build(BuildContext context) {
    final sections = _parseAiResponse(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildSectionWidget(context, sections[i]),
        ],
      ],
    );
  }

  Widget _buildSectionWidget(BuildContext context, _AiSection section) {
    switch (section.type) {
      case _AiSectionType.summary:
        return _SummaryCard(content: section.content);
      case _AiSectionType.highlights:
        return _HighlightsCard(content: section.content, title: section.title);
      case _AiSectionType.actionPlan:
        return _ActionPlanCard(content: section.content, title: section.title);
      case _AiSectionType.template:
        return _TemplateCard(content: section.content, title: section.title);
      case _AiSectionType.proTip:
        return _ProTipCard(content: section.content);
      case _AiSectionType.general:
        return _GeneralSectionCard(content: section.content, title: section.title);
    }
  }
}

// ── 1. Executive Summary Card ──
class _SummaryCard extends StatelessWidget {
  final String content;

  const _SummaryCard({required this.content});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191E2C) : const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppTheme.orange.withValues(alpha: isDark ? 0.35 : 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.orange, Color(0xFFFF8A5C)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insights_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'EXECUTIVE SUMMARY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _RichTextLines(
            text: content,
            defaultColor: isDark ? AppTheme.textLight : AppTheme.textDark,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            lineHeight: 1.45,
          ),
        ],
      ),
    );
  }
}

// ── 2. Highlights / Key Insights Card ──
class _HighlightsCard extends StatelessWidget {
  final String content;
  final String title;

  const _HighlightsCard({required this.content, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardElevated : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppTheme.vibrantBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insights_rounded, size: 13, color: AppTheme.vibrantBlue),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppTheme.vibrantBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final line in lines) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppTheme.vibrantBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: _RichTextLines(
                      text: line.replaceAll(RegExp(r'^[•\-\*]\s*'), ''),
                      defaultColor: isDark ? AppTheme.textLight : AppTheme.textDark,
                      fontSize: 13,
                      lineHeight: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 3. Action Plan / Steps Card ──
class _ActionPlanCard extends StatelessWidget {
  final String content;
  final String title;

  const _ActionPlanCard({required this.content, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardElevated : const Color(0xFFF9FDF9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppTheme.vibrantGreen.withValues(alpha: isDark ? 0.3 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppTheme.vibrantGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.checklist_rounded, size: 14, color: AppTheme.vibrantGreen),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppTheme.vibrantGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < lines.length; i++) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 10, top: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.vibrantGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.vibrantGreen.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: AppTheme.vibrantGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _RichTextLines(
                      text: lines[i].replaceAll(RegExp(r'^\d+[\.\)]\s*'), '').replaceAll(RegExp(r'^[•\-\*]\s*'), ''),
                      defaultColor: isDark ? AppTheme.textLight : AppTheme.textDark,
                      fontSize: 13,
                      lineHeight: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 4. Ready-to-Use Template Card ──
class _TemplateCard extends StatelessWidget {
  final String content;
  final String title;

  const _TemplateCard({required this.content, required this.title});

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Template copied to clipboard! Ready to paste & send.'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10131C) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppTheme.vibrantPurple.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.vibrantPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.mark_email_read_rounded, size: 13, color: AppTheme.vibrantPurple),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppTheme.vibrantPurple,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _copy(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.vibrantPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.vibrantPurple.withValues(alpha: 0.35)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 11, color: AppTheme.vibrantPurple),
                      SizedBox(width: 4),
                      Text(
                        'Copy Template',
                        style: TextStyle(
                          color: AppTheme.vibrantPurple,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCanvas : AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppTheme.borderDarkSubtle : AppTheme.borderLight),
            ),
            child: _RichTextLines(
              text: content,
              defaultColor: isDark ? AppTheme.textLight : AppTheme.textDark,
              fontSize: 12.5,
              lineHeight: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 5. Pro Tip Callout Banner ──
class _ProTipCard extends StatelessWidget {
  final String content;

  const _ProTipCard({required this.content});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const tipColor = Color(0xFFF59E0B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: tipColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: tipColor.withValues(alpha: isDark ? 0.35 : 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: tipColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_rounded, size: 14, color: tipColor),
              ),
              const SizedBox(width: 8),
              const Text(
                'PRO TIP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: tipColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _RichTextLines(
            text: content,
            defaultColor: isDark ? AppTheme.textLight : AppTheme.textDark,
            fontSize: 13,
            lineHeight: 1.4,
          ),
        ],
      ),
    );
  }
}

// ── 6. General / Fallback Section Card ──
class _GeneralSectionCard extends StatelessWidget {
  final String content;
  final String title;

  const _GeneralSectionCard({required this.content, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty && title.toLowerCase() != 'overview' && title.toLowerCase() != 'response') ...[
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.textLight : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
        ],
        _RichTextLines(
          text: content,
          defaultColor: isDark ? AppTheme.textLight : AppTheme.textDark,
          fontSize: 13.5,
          lineHeight: 1.45,
        ),
      ],
    );
  }
}

// ── 7. Rich Text Lines with Inline Bold (**text**) Parsing ──
class _RichTextLines extends StatelessWidget {
  final String text;
  final Color defaultColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double lineHeight;

  const _RichTextLines({
    required this.text,
    required this.defaultColor,
    this.fontSize = 13.5,
    this.fontWeight = FontWeight.normal,
    this.lineHeight = 1.45,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < lines.length; i++) ...[
          if (lines[i].trim().isEmpty)
            const SizedBox(height: 6)
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: _buildLine(lines[i]),
            ),
        ],
      ],
    );
  }

  Widget _buildLine(String line) {
    final spans = <TextSpan>[];
    final regExp = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regExp.allMatches(line)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: line.substring(lastIndex, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < line.length) {
      spans.add(TextSpan(text: line.substring(lastIndex)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: defaultColor,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: lineHeight,
          fontFamily: 'Inter',
        ),
        children: spans.isEmpty ? [TextSpan(text: line)] : spans,
      ),
    );
  }
}

// ── 8. User Message Text ──
class _UserMessageText extends StatelessWidget {
  final String text;

  const _UserMessageText({required this.text});

  @override
  Widget build(BuildContext context) {
    return _RichTextLines(
      text: text,
      defaultColor: Colors.white,
      fontSize: 14,
      lineHeight: 1.4,
    );
  }
}

// ── Tips & Guide Tab View ──
class _TipsGuideView extends StatelessWidget {
  final Function(String) onSelectPrompt;

  const _TipsGuideView({required this.onSelectPrompt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tips = [
      {
        "title": "Master the STAR Technique",
        "desc": "Structure responses: Situation, Task, Action, and Result for 2x stronger impact.",
        "prompt": "Explain how I can use the STAR technique for software engineer behavioral questions.",
        "icon": Icons.star_rounded,
        "color": AppTheme.orange,
      },
      {
        "title": "Follow Up Within 48 Hours",
        "desc": "A brief follow-up keeps you on top of recruiters' inboxes without being pushy.",
        "prompt": "Draft a short 3-sentence polite follow up email for an application.",
        "icon": Icons.mark_email_read_rounded,
        "color": AppTheme.vibrantBlue,
      },
      {
        "title": "Tailor Tech Keywords",
        "desc": "Applicant tracking systems filter by keywords directly mentioned in job descriptions.",
        "prompt": "How can I align my resume with technical job postings to beat ATS filters?",
        "icon": Icons.tune_rounded,
        "color": AppTheme.vibrantPurple,
      },
      {
        "title": "Closing Questions for Interviewers",
        "desc": "Ask insightful questions to demonstrate genuine curiosity and technical drive.",
        "prompt": "Give me 4 brilliant questions to ask a hiring manager at the end of an interview.",
        "icon": Icons.lightbulb_rounded,
        "color": AppTheme.vibrantGreen,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tips.length,
      itemBuilder: (ctx, i) {
        final t = tips[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (t["color"] as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(t["icon"] as IconData, color: t["color"] as Color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t["title"] as String,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                t["desc"] as String,
                style: TextStyle(
                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onSelectPrompt(t["prompt"] as String),
                  icon: const Icon(Icons.send_rounded, size: 14, color: AppTheme.orange),
                  label: const Text(
                    'Ask Copilot',
                    style: TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Typing Animated Dot ──
class _TypingDot extends StatelessWidget {
  final int delay;
  const _TypingDot({required this.delay});


  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: AppTheme.orange,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 0.5, end: 1.1, duration: 400.ms, delay: Duration(milliseconds: delay));
  }
}
