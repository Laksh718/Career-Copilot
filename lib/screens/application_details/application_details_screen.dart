import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme.dart';
import '../../controllers/application_controller.dart';
import '../../models/application.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/document_checklist.dart';
import '../../widgets/company_logo.dart';
import '../../widgets/app_logo.dart';

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
    setState(() {
      _app = _app.copyWith(status: newStatus);
    });
    context.read<ApplicationController>().updateApplication(_app);
  }

  void _toggleDocument(int index, bool isCompleted) {
    final docs = List.of(_app.requiredDocuments);
    docs[index] = docs[index].copyWith(isCompleted: isCompleted);
    setState(() {
      _app = _app.copyWith(requiredDocuments: docs);
    });
    context.read<ApplicationController>().updateApplication(_app);
  }

  void _saveNotes() {
    setState(() {
      _app = _app.copyWith(notes: _notesController.text);
    });
    context.read<ApplicationController>().updateApplication(_app);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notes saved successfully'),
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
Status: ${_app.status.name.toUpperCase()}
${_app.interviewDate.isNotEmpty ? "Interview: ${_app.interviewDate} at ${_app.interviewTime}\n" : ""}${_app.deadline.isNotEmpty ? "Deadline: ${_app.deadline}\n" : ""}${_app.stipend.isNotEmpty ? "Compensation: ${_app.stipend}\n" : ""}
Tracked with Career Copilot
''';

    Clipboard.setData(ClipboardData(text: shareText.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.primaryYellow, size: 20),
            SizedBox(width: 10),
            Text('Application summary copied!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        title: Text('Delete Opportunity?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove ${_app.company} (${_app.role}) from your tracking list?',
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
              foregroundColor: Colors.white,  // white text on red
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

  Future<void> _runAIAction(String actionTitle, String result) async {
    setState(() => _isGeneratingAI = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isGeneratingAI = false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.flatDecoration(context, borderRadius: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppTheme.primaryYellow, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    actionTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: Theme.of(context).textTheme.bodySmall?.color),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: SelectableText(
                result,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryYellow,
                      side: const BorderSide(color: AppTheme.primaryYellow),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: result));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('AI result copied to clipboard!'),
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
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: AppTheme.accentBlack,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _app.category.color;

    // Tailor labels based on category
    final dateLabel = _app.category == OpportunityCategory.hackathon
        ? 'Demo Day / Pitch Date'
        : (_app.category == OpportunityCategory.event
            ? 'Event Date'
            : (_app.category == OpportunityCategory.contest ? 'Contest Date' : 'Interview Date'));
    final deadlineLabel = _app.category == OpportunityCategory.hackathon
        ? 'Submission Deadline'
        : (_app.category == OpportunityCategory.event ? 'RSVP Deadline' : 'Application Deadline');

    // Tailored pipeline step labels
    final step1Label = _app.category == OpportunityCategory.hackathon
        ? 'Registered'
        : (_app.category == OpportunityCategory.event ? 'RSVP\'d' : (_app.category == OpportunityCategory.contest ? 'Signed Up' : 'Applied'));
    final step2Label = _app.category == OpportunityCategory.hackathon
        ? 'Building'
        : (_app.category == OpportunityCategory.event ? 'Waitlisted' : (_app.category == OpportunityCategory.contest ? 'Active' : 'Action Req'));
    final step3Label = _app.category == OpportunityCategory.hackathon
        ? 'Demo Day'
        : (_app.category == OpportunityCategory.event ? 'Attending' : (_app.category == OpportunityCategory.contest ? 'Finals' : 'Interview'));
    final step4Label = _app.category == OpportunityCategory.hackathon
        ? 'Results'
        : (_app.category == OpportunityCategory.event ? 'Completed' : (_app.category == OpportunityCategory.contest ? 'Ranked' : 'Waiting'));

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Custom App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: AppTheme.flatDecoration(context, borderRadius: 14),
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
                          decoration: AppTheme.flatDecoration(context, borderRadius: 14),
                          child: IconButton(
                            icon: const Icon(Icons.share_rounded, color: AppTheme.orange, size: 20),
                            tooltip: 'Share / Copy Summary',
                            onPressed: _shareApplication,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: AppTheme.flatDecoration(context, borderRadius: 14),
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
                    // Flat Header Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: AppTheme.flatDecoration(
                        context,
                        borderRadius: 28,
                        borderColor: catColor.withValues(alpha: 0.3),
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
                                size: 52,
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
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: catColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: catColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          _app.category.label.toUpperCase(),
                                          style: TextStyle(
                                            color: catColor,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_app.stipend.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: catColor.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _app.category == OpportunityCategory.hackathon || _app.category == OpportunityCategory.contest
                                        ? Icons.emoji_events_rounded
                                        : Icons.payments_outlined,
                                    size: 14,
                                    color: catColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _app.stipend,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: catColor,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 24),

                    // Pipeline Status Switcher
                    Text(
                      _app.category == OpportunityCategory.hackathon
                          ? 'Hackathon Progress Stage'
                          : (_app.category == OpportunityCategory.event
                              ? 'Event Registration Stage'
                              : (_app.category == OpportunityCategory.contest
                                  ? 'Contest Status'
                                  : 'Application Pipeline Stage')),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: AppTheme.flatDecoration(context),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPipelineStep(context, step1Label, ApplicationStatus.applied, Icons.send_rounded),
                          _buildPipelineStep(context, step2Label, ApplicationStatus.actionRequired, Icons.assignment_late_rounded),
                          _buildPipelineStep(context, step3Label, ApplicationStatus.interview, Icons.video_call_rounded),
                          _buildPipelineStep(context, step4Label, ApplicationStatus.waiting, Icons.hourglass_top_rounded),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Key Dates & Logistics Card
                    Text(
                      'Timeline & Key Dates',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: AppTheme.flatDecoration(context),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            context,
                            Icons.calendar_month_rounded,
                            dateLabel,
                            _app.interviewDate.isNotEmpty
                                ? '${_app.interviewDate} at ${_app.interviewTime}'
                                : 'Not yet scheduled',
                            catColor,
                          ),
                          Divider(color: Theme.of(context).dividerColor, height: 24),
                          _buildInfoRow(
                            context,
                            Icons.access_time_rounded,
                            deadlineLabel,
                            _app.deadline.isNotEmpty ? _app.deadline : 'No hard deadline provided',
                            AppTheme.statusAmberText,
                          ),
                          Divider(color: Theme.of(context).dividerColor, height: 24),
                          _buildInfoRow(
                            context,
                            Icons.location_on_rounded,
                            'Location / Format',
                            _app.location.isNotEmpty ? _app.location : 'Remote / Global',
                            AppTheme.orange,
                          ),
                        ],
                      ),
                    ),

                    // Document Checklist
                    if (_app.requiredDocuments.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        _app.category == OpportunityCategory.hackathon
                            ? 'Submission Deliverables'
                            : 'Required Documents',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: AppTheme.flatDecoration(context),
                        padding: const EdgeInsets.all(16),
                        child: DocumentChecklist(
                          documents: _app.requiredDocuments,
                          onToggle: _toggleDocument,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // AI Copilot Actions
                    Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: catColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'AI Copilot Tools',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
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
                                    ? 'Networking Guide'
                                    : (_app.category == OpportunityCategory.contest ? 'Contest Tactics' : 'Interview Prep')),
                            desc: _app.category == OpportunityCategory.hackathon
                                ? 'Pitch hook, USP & demo script'
                                : (_app.category == OpportunityCategory.event
                                    ? 'Questions & networking plan'
                                    : (_app.category == OpportunityCategory.contest ? 'Time split & debug checklist' : 'Top 5 questions & answers')),
                            icon: _app.category == OpportunityCategory.hackathon
                                ? Icons.lightbulb_rounded
                                : (_app.category == OpportunityCategory.event
                                    ? Icons.groups_rounded
                                    : (_app.category == OpportunityCategory.contest ? Icons.speed_rounded : Icons.quiz_rounded)),
                            color: catColor,
                            onTap: () {
                              if (_app.category == OpportunityCategory.hackathon) {
                                _runAIAction(
                                  'Hackathon Strategy for ${_app.company}',
                                  '''Hackathon Pitch & Architecture Strategy for ${_app.company} (${_app.role}):

1. Problem Hook (30 sec):
   - "Developers and teams face massive friction in collaboration and manual tracking across modern platforms."

2. Unique Value Proposition & Tech Stack:
   - "Our project provides an autonomous, real-time sync pipeline that slashes latency by 80% with offline-first support."
   - Target Tech: Flutter + Offline Engine + WebSocket streaming.

3. 3-Minute Live Demo Outline:
   - Minute 1: The real-world problem and workflow failure.
   - Minute 2: Live execution showing the breakthrough feature in action.
   - Minute 3: Scalability, architecture diagram, and judge Q&A prep.
''',
                                );
                              } else if (_app.category == OpportunityCategory.event) {
                                _runAIAction(
                                  'Networking & Keynote Plan for ${_app.company}',
                                  '''Event Networking & Insights Plan for ${_app.company} (${_app.role}):

1. Target Topics & Questions to Ask:
   - "What are the biggest production hurdles your engineering team faced while scaling this year?"
   - "Where do you see the intersection of open-source tooling and proprietary AI agents heading in the next 12 months?"

2. 30-Second Introduction Hook:
   - "Hi! I'm Laksh, a software engineer passionate about building high-performance tooling and developer platforms."

3. Post-Event Follow-up Plan:
   - Connect on LinkedIn within 24 hours citing the specific discussion point.
''',
                                );
                              } else if (_app.category == OpportunityCategory.contest) {
                                _runAIAction(
                                  'Contest Strategy for ${_app.company}',
                                  '''Competitive Programming Strategy for ${_app.company} (${_app.role}):

1. Time Allocation Budget:
   - First 5 mins: Read all problems, rank by difficulty and familiarity.
   - Problem A/B: Rapid implementation (< 15 mins total).
   - Problem C/D: Core algorithmic focus (Graphs, DP, Trees). Spend 35-45 mins.

2. Pre-Submission Edge-Case Checklist:
   - Integer overflow (use 64-bit int / BigInt).
   - Empty input or N = 1 boundaries.
   - Worst-case time complexity vs constraints: 10^5 -> O(N log N).

3. Debugging Protocol:
   - If TLE: Check redundant loops and fast I/O.
   - If WA: Print intermediate state on a mini counter-example.
''',
                                );
                              } else {
                                _runAIAction(
                                  'Interview Questions for ${_app.role}',
                                  '''Tailored Interview Questions for ${_app.company} (${_app.role}):

1. Technical Focus:
   - "How would you design a scalable system that handles high concurrency and prevents deadlocks?"
   - "Explain a time when you optimized a slow query or bottleneck in your application."

2. Behavioral & Cultural:
   - "Why do you want to join ${_app.company} specifically over other top companies in this space?"
   - "Describe an ambiguous problem where you took initiative without waiting for explicit instructions."

3. Role Specific:
   - "What technologies would you choose for modern production web/mobile architecture and why?"
''',
                                );
                              }
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
                                    ? 'Speaker Message'
                                    : (_app.category == OpportunityCategory.contest ? 'Teammate Brief' : 'Email Draft')),
                            desc: _app.category == OpportunityCategory.hackathon
                                ? 'Sponsor & mentor inquiry'
                                : (_app.category == OpportunityCategory.event
                                    ? 'Host / speaker conversation'
                                    : (_app.category == OpportunityCategory.contest ? 'Team assignment message' : 'Interview confirmation draft')),
                            icon: _app.category == OpportunityCategory.hackathon
                                ? Icons.handshake_rounded
                                : (_app.category == OpportunityCategory.event
                                    ? Icons.connect_without_contact_rounded
                                    : (_app.category == OpportunityCategory.contest ? Icons.diversity_3_rounded : Icons.mark_email_read_rounded)),
                            color: catColor,
                            onTap: () {
                              if (_app.category == OpportunityCategory.hackathon) {
                                _runAIAction(
                                  'Mentor Outreach Draft',
                                  '''Subject: Mentorship Request: Project for ${_app.role} - ${_app.company}

Hi ${_app.company} Mentors,

Our team is actively building an ambitious project for the ${_app.role} track at ${_app.company}. We are incorporating your APIs and would love 5 minutes of your feedback on our data pipeline architecture and edge deployment.

Could we connect briefly at the mentoring lounge or via the hackathon Discord?

Best regards,
Laksh
''',
                                );
                              } else if (_app.category == OpportunityCategory.event) {
                                _runAIAction(
                                  'Speaker / Organizer Connect Draft',
                                  '''Subject: Attending ${_app.company} (${_app.role}) - Quick Question

Hi ${_app.company} Team,

I'm looking forward to attending ${_app.company}'s session on ${_app.role}. I've been actively exploring your tooling in high-performance architectures and hope to connect during the networking breakout!

Best,
Laksh
''',
                                );
                              } else if (_app.category == OpportunityCategory.contest) {
                                _runAIAction(
                                  'Teammate Briefing Draft',
                                  '''Subject: ${_app.company} ${_app.role} Strategy & Topic Split

Team,

Here is our division for the upcoming ${_app.company} (${_app.role}):
- Teammate 1: Implementation & fast math / geometry problems
- Teammate 2: Graph theory & Dynamic Programming
- Teammate 3: Edge testing, Stress testing, and fast debugging

Let's do a 20-minute sync beforehand to verify all templates and compiler environments!
''',
                                );
                              } else {
                                _runAIAction(
                                  'Interview Confirmation Draft',
                                  '''Subject: Confirmation: Interview for ${_app.role} - ${_app.company}

Dear Hiring Team at ${_app.company},

Thank you very much for inviting me to interview for the ${_app.role} position. 

I am excited to confirm my availability for our upcoming conversation ${_app.interviewDate.isNotEmpty ? "on ${_app.interviewDate}" : ""}. I look forward to learning more about the team's upcoming initiatives and demonstrating how my technical background aligns with your engineering goals.

Please let me know if you need any additional portfolio links or documents prior to our call.

Sincerely,
Laksh
''',
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Personal Notes Section
                    Text(
                      'Personal Notes & Prep',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: AppTheme.flatDecoration(context),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _notesController,
                            maxLines: 4,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                            decoration: InputDecoration(
                              hintText: 'Add recruiter contacts, salary negotiations, or round notes...',
                              hintStyle: Theme.of(context).textTheme.bodySmall,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              fillColor: Colors.transparent,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _app.category.color.withValues(alpha: 0.18),
                                foregroundColor: _app.category.color,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: _saveNotes,
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text('Save Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

  Widget _buildPipelineStep(BuildContext context, String label, ApplicationStatus status, IconData icon) {
    final isCurrent = _app.status == status;
    final catColor = _app.category.color;
    return GestureDetector(
      onTap: () => _updateStatus(status),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent ? catColor : Theme.of(context).dividerColor,
              border: Border.all(
                color: isCurrent ? Colors.transparent : Theme.of(context).dividerColor,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isCurrent ? AppTheme.accentBlack : Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: isCurrent ? catColor : Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              ),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
    return GestureDetector(
      onTap: _isGeneratingAI ? null : onTap,
      child: Container(
        decoration: AppTheme.flatDecoration(context),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.accentBlack, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
