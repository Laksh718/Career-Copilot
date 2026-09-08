import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme.dart';
import '../../controllers/application_controller.dart';
import '../../models/application.dart';
import '../../models/career_extraction.dart';
import '../../models/required_document.dart';
import '../../widgets/animated_bg.dart';
import '../../widgets/gradient_button.dart';
import '../home/home_screen.dart';

class AnalysisResultScreen extends StatefulWidget {
  final CareerExtraction extraction;

  const AnalysisResultScreen({super.key, required this.extraction});

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  final _companyController = TextEditingController();
  final _roleController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _interviewDateController = TextEditingController();
  final _interviewTimeController = TextEditingController();
  late OpportunityCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _companyController.text = widget.extraction.company ?? '';
    _roleController.text = widget.extraction.role ?? '';
    _deadlineController.text = widget.extraction.deadline ?? '';
    _interviewDateController.text = widget.extraction.interviewDate ?? '';
    _interviewTimeController.text = widget.extraction.interviewTime ?? '';

    // Auto-detect category from parsed content
    final combinedText = '${widget.extraction.company ?? ''} ${widget.extraction.role ?? ''} ${widget.extraction.eligibility ?? ''}'.toLowerCase();
    if (combinedText.contains('hackathon') || combinedText.contains('hack') || combinedText.contains('bounty') || combinedText.contains('devpost') || combinedText.contains('mlh')) {
      _selectedCategory = OpportunityCategory.hackathon;
    } else if (combinedText.contains('summit') || combinedText.contains('conference') || combinedText.contains('webinar') || combinedText.contains('workshop') || combinedText.contains('meetup') || combinedText.contains('event')) {
      _selectedCategory = OpportunityCategory.event;
    } else if (combinedText.contains('contest') || combinedText.contains('codeforces') || combinedText.contains('leetcode') || combinedText.contains('icpc') || combinedText.contains('olympiad')) {
      _selectedCategory = OpportunityCategory.contest;
    } else {
      _selectedCategory = OpportunityCategory.job;
    }
  }

  void _save() {
    if (_companyController.text.isEmpty || _roleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Company / Organizer and Title are required.'),
          backgroundColor: AppTheme.statusRedText.withValues(alpha: 0.9),
        ),
      );
      return;
    }

    ApplicationStatus status = ApplicationStatus.applied;
    if (widget.extraction.status == 'Interview') status = ApplicationStatus.interview;
    if (widget.extraction.status == 'Action Required') status = ApplicationStatus.actionRequired;
    if (widget.extraction.status == 'Waiting') status = ApplicationStatus.waiting;

    final List<RequiredDocument> docs = widget.extraction.requiredDocuments
            ?.map((doc) => RequiredDocument(name: doc))
            .toList() ??
        [];

    final app = Application(
      id: const Uuid().v4(),
      category: _selectedCategory,
      company: _companyController.text,
      role: _roleController.text,
      deadline: _deadlineController.text,
      interviewDate: _interviewDateController.text,
      interviewTime: _interviewTimeController.text,
      requiredDocuments: docs,
      status: status,
      createdAt: DateTime.now(),
      location: widget.extraction.location ?? '',
      workMode: widget.extraction.workMode ?? '',
      stipend: widget.extraction.stipend ?? widget.extraction.salary ?? '',
    );

    context.read<ApplicationController>().addApplication(app);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _selectedCategory.color;
    final companyLabel = _selectedCategory == OpportunityCategory.hackathon
        ? 'Organizer / Hackathon Platform'
        : (_selectedCategory == OpportunityCategory.event
            ? 'Organizer / Host'
            : (_selectedCategory == OpportunityCategory.contest ? 'Platform / Host' : 'Company / Organization'));
    final roleLabel = _selectedCategory == OpportunityCategory.hackathon
        ? 'Project / Track / Role'
        : (_selectedCategory == OpportunityCategory.event
            ? 'Event / Session Title'
            : (_selectedCategory == OpportunityCategory.contest ? 'Contest / Division' : 'Role / Position'));
    final dateLabel = _selectedCategory == OpportunityCategory.hackathon
        ? 'Demo Day / Pitch Date'
        : (_selectedCategory == OpportunityCategory.event
            ? 'Event / Session Date'
            : (_selectedCategory == OpportunityCategory.contest ? 'Contest Date' : 'Interview Date'));
    final timeLabel = _selectedCategory == OpportunityCategory.hackathon
        ? 'Demo Time'
        : (_selectedCategory == OpportunityCategory.event
            ? 'Start Time'
            : (_selectedCategory == OpportunityCategory.contest ? 'Start Time' : 'Interview Time'));
    final deadlineLabel = _selectedCategory == OpportunityCategory.hackathon
        ? 'Registration / Submission Deadline'
        : (_selectedCategory == OpportunityCategory.event ? 'RSVP Deadline' : 'Application Deadline');

    final fields = <_FieldData>[
      _FieldData(icon: Icons.business_rounded, label: companyLabel, controller: _companyController, color: catColor),
      _FieldData(icon: _selectedCategory.icon, label: roleLabel, controller: _roleController, color: catColor),
      _FieldData(icon: Icons.event_rounded, label: dateLabel, controller: _interviewDateController, color: catColor),
      _FieldData(icon: Icons.schedule_rounded, label: timeLabel, controller: _interviewTimeController, color: catColor),
      _FieldData(icon: Icons.timer_rounded, label: deadlineLabel, controller: _deadlineController, color: AppTheme.vibrantRed),
    ];

    return Scaffold(
      extendBody: true,
      body: AnimatedBg(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.bodyMedium?.color),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Extraction',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Verify extracted details',
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Confidence indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'AI Parsed',
                            style: TextStyle(
                              color: AppTheme.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 16),

              // Fields list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    // Category Selector
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecoration(
                        context,
                        borderRadius: AppTheme.radiusLg,
                        borderColor: catColor.withValues(alpha: 0.35),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.category_rounded, size: 16, color: catColor),
                              const SizedBox(width: 8),
                              Text(
                                'OPPORTUNITY CATEGORY',
                                style: TextStyle(
                                  color: catColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: OpportunityCategory.values.map((cat) {
                                final isSel = _selectedCategory == cat;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedCategory = cat),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: isSel ? cat.color.withValues(alpha: 0.16) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSel ? cat.color : Theme.of(context).dividerColor,
                                          width: isSel ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(cat.icon, size: 14, color: isSel ? cat.color : Theme.of(context).textTheme.bodySmall?.color),
                                          const SizedBox(width: 6),
                                          Text(
                                            cat.label,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                                              color: isSel ? cat.color : Theme.of(context).textTheme.bodyMedium?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 350.ms),
                    ...fields.asMap().entries.map((entry) {
                      final f = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.cardDecoration(context, borderRadius: AppTheme.radiusLg, borderColor: f.color.withValues(alpha: 0.25)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: f.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(f.icon, color: f.color, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f.label,
                                      style: TextStyle(
                                        color: f.color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: f.controller,
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        fillColor: Colors.transparent,
                                        filled: true,
                                        hintText: 'Not detected',
                                        hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: (200 + entry.key * 100).ms).slideX(begin: 0.1, end: 0);
                    }),

                    // Required documents
                    if (widget.extraction.requiredDocuments != null &&
                        widget.extraction.requiredDocuments!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecoration(context, borderRadius: AppTheme.radiusLg, borderColor: AppTheme.orange.withValues(alpha: 0.25)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.orange.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.description_rounded, color: AppTheme.orange, size: 20),
                                ),
                                const SizedBox(width: 14),
                                const Text(
                                  'REQUIRED DOCUMENTS',
                                  style: TextStyle(
                                    color: AppTheme.orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ...widget.extraction.requiredDocuments!.map(
                              (d) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 44),
                                    const Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.orange),
                                    const SizedBox(width: 10),
                                    Text(d, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 700.ms),

                    const SizedBox(height: 24),

                    GradientButton(
                      label: 'Save Opportunity',
                      icon: Icons.save_rounded,
                      onPressed: _save,
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldData {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final Color color;

  const _FieldData({
    required this.icon,
    required this.label,
    required this.controller,
    required this.color,
  });
}
