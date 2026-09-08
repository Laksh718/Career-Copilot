import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme.dart';
import '../../controllers/ai_controller.dart';
import '../../controllers/application_controller.dart';
import '../../models/application.dart';
import '../../models/required_document.dart';
import '../../widgets/animated_bg.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/company_logo.dart';

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
  int _selectedModeIndex = 0; // 0 = AI Smart Ingest, 1 = Manual Entry

  // --- AI Smart Ingest Mode ---
  final _aiTextController = TextEditingController();
  bool _hasAiText = false;

  // --- Manual Entry Mode Controllers ---
  final _companyController = TextEditingController();
  final _roleController = TextEditingController();
  final _locationController = TextEditingController();
  final _stipendController = TextEditingController();
  final _notesController = TextEditingController();

  OpportunityCategory _manualCategory = OpportunityCategory.job;
  ApplicationStatus _manualStatus = ApplicationStatus.applied;
  String _manualWorkMode = 'Remote';

  DateTime? _manualInterviewDate;
  TimeOfDay? _manualInterviewTime;
  DateTime? _manualDeadline;

  String _companyPreview = '';

  @override
  void initState() {
    super.initState();
    _aiTextController.addListener(() {
      final has = _aiTextController.text.trim().isNotEmpty;
      if (has != _hasAiText) setState(() => _hasAiText = has);
    });

    _companyController.addListener(() {
      if (_companyPreview != _companyController.text) {
        setState(() => _companyPreview = _companyController.text);
      }
    });
  }

  @override
  void dispose() {
    _aiTextController.dispose();
    _companyController.dispose();
    _roleController.dispose();
    _locationController.dispose();
    _stipendController.dispose();
    _notesController.dispose();
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

  // --- AI Mode Actions ---
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      _aiTextController.text = data.text!;
      _aiTextController.selection = TextSelection.fromPosition(
        TextPosition(offset: _aiTextController.text.length),
      );
    }
  }

  void _insertGoogleEmail() {
    _aiTextController.text =
        'Google Recruiting: Hi Laksh, We are excited to invite you to interview for the Software Engineer Intern role. '
        'Your technical interview is scheduled for tomorrow at 2:00 PM. '
        'Please review the attached guide and have your code editor ready. '
        'Stipend: \$9,500/month. Location: Sunnyvale, CA (Hybrid). '
        'Deadline to confirm: Sep 15.';
    _aiTextController.selection = TextSelection.fromPosition(
      TextPosition(offset: _aiTextController.text.length),
    );
  }

  void _insertAmazonWhatsApp() {
    _aiTextController.text =
        'Amazon Student Programs: Congratulations! Your application for SDE Intern has progressed. '
        'Interview round scheduled Monday at 10 AM. '
        'Stipend: ₹85,000/month. Location: Bengaluru, India (On-site). '
        'Please bring your college ID & resume. Applications close September 25.';
    _aiTextController.selection = TextSelection.fromPosition(
      TextPosition(offset: _aiTextController.text.length),
    );
  }

  void _insertEthGlobalHackathon() {
    _aiTextController.text =
        'ETHGlobal Hackathon: Official Invitation to participate in the global Web3 hackathon! '
        'Track: Autonomous Agents & Zero-Knowledge. Event Dates: Nov 15-17 at 11:00 AM. '
        'Prizes: \$500,000 in sponsor bounties. Location: Global Online. '
        'Submission deadline: Nov 10. Register on Devpost.';
    _aiTextController.selection = TextSelection.fromPosition(
      TextPosition(offset: _aiTextController.text.length),
    );
  }

  void _insertContestSample() {
    _aiTextController.text =
        'Codeforces Round 980 (Div. 1 + Div. 2): Registered successfully! '
        'Contest starts this Saturday at 8:05 PM IST. '
        'Duration: 2 hours. Rating changes apply for all participants. '
        'RSVP deadline: Saturday 7:30 PM.';
    _aiTextController.selection = TextSelection.fromPosition(
      TextPosition(offset: _aiTextController.text.length),
    );
  }

  Future<void> _autoAddShared() async {
    final text = _aiTextController.text.trim();
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
    if (_aiTextController.text.trim().isEmpty) return;

    final aiController = context.read<AIController>();
    final result = await aiController.analyzeMessage(_aiTextController.text);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisResultScreen(extraction: result),
        ),
      );
    }
  }

  // --- Manual Entry Actions ---
  Future<void> _pickInterviewDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _manualInterviewDate ?? now.add(const Duration(days: 3)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _manualInterviewDate = picked);
    }
  }

  Future<void> _pickInterviewTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _manualInterviewTime ?? const TimeOfDay(hour: 14, minute: 0),
    );
    if (picked != null) {
      setState(() => _manualInterviewTime = picked);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _manualDeadline ?? now.add(const Duration(days: 14)),
      firstDate: now.subtract(const Duration(days: 10)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _manualDeadline = picked);
    }
  }

  void _saveManualOpportunity() {
    final company = _companyController.text.trim();
    final role = _roleController.text.trim();

    if (company.isEmpty || role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Please enter both Company/Organizer and Role/Title.'),
            ],
          ),
          backgroundColor: AppTheme.vibrantRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final String interviewDateStr = _manualInterviewDate != null
        ? DateFormat('MMM d, yyyy').format(_manualInterviewDate!)
        : '';
    final String interviewTimeStr = _manualInterviewTime != null
        ? _manualInterviewTime!.format(context)
        : '';
    final String deadlineStr = _manualDeadline != null
        ? DateFormat('MMM d, yyyy').format(_manualDeadline!)
        : '';

    final app = Application(
      id: const Uuid().v4(),
      category: _manualCategory,
      company: company,
      role: role,
      deadline: deadlineStr,
      interviewDate: interviewDateStr,
      interviewTime: interviewTimeStr,
      requiredDocuments: [
        RequiredDocument(name: 'Resume / CV', isCompleted: true),
        if (_manualCategory == OpportunityCategory.hackathon)
          RequiredDocument(name: 'GitHub Repository & Demo Video', isCompleted: false)
        else if (_manualCategory == OpportunityCategory.job)
          RequiredDocument(name: 'Official Transcripts / Portfolio', isCompleted: false),
      ],
      status: _manualStatus,
      createdAt: DateTime.now(),
      location: _locationController.text.trim(),
      workMode: _manualWorkMode,
      stipend: _stipendController.text.trim(),
      notes: _notesController.text.trim(),
    );

    context.read<ApplicationController>().addApplication(app);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Added $company ($role) to your pipeline!')),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Navigator.pushReplacement(
      context,
      AppTheme.morphPageRoute(screen: const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: AnimatedBg(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const AppLogo(size: 42, emblemOnly: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Opportunity',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Track jobs, hackathons, contests, and events',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms),

              // Segmented Mode Switcher (AI Ingest vs Direct Form)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF151823) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildModeTab(
                          index: 0,
                          icon: Icons.auto_awesome_rounded,
                          label: 'AI Smart Ingest',
                          activeColor: AppTheme.orange,
                        ),
                      ),
                      Expanded(
                        child: _buildModeTab(
                          index: 1,
                          icon: Icons.edit_note_rounded,
                          label: 'Manual Form',
                          activeColor: AppTheme.vibrantBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 10),

              // Mode Body
              Expanded(
                child: _selectedModeIndex == 0
                    ? _buildAiIngestView(context, isDark)
                    : _buildManualFormView(context, isDark),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 3, onTap: _onNavTap),
    );
  }

  Widget _buildModeTab({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _selectedModeIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedModeIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF22283A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? activeColor : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13.5,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MODE 0: AI SMART INGEST
  // ===========================================================================
  Widget _buildAiIngestView(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sample Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ActionChip(
                  icon: Icons.content_paste_rounded,
                  label: 'Paste Clipboard',
                  color: AppTheme.orange,
                  onTap: _pasteFromClipboard,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.business_rounded,
                  label: 'Google Interview Mail',
                  color: AppTheme.vibrantBlue,
                  onTap: _insertGoogleEmail,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Amazon WhatsApp',
                  color: AppTheme.orange,
                  onTap: _insertAmazonWhatsApp,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.terminal_rounded,
                  label: 'ETHGlobal Hackathon',
                  color: AppTheme.vibrantPurple,
                  onTap: _insertEthGlobalHackathon,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.code_rounded,
                  label: 'Codeforces Contest',
                  color: AppTheme.vibrantYellow,
                  onTap: _insertContestSample,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 14),

          // Text Field Container
          Expanded(
            child: Container(
              decoration: AppTheme.cardDecoration(context, borderRadius: 20),
              child: Stack(
                children: [
                  TextField(
                    controller: _aiTextController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.6,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Paste any recruiter email, interview invitation, WhatsApp offer, or hackathon acceptance here...\n\nCareer Copilot will automatically extract company, role, deadline, interview dates, and documents.',
                      hintMaxLines: 6,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      fillColor: Colors.transparent,
                      filled: true,
                      hintStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  if (_hasAiText)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _aiTextController.clear(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.black12,
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

          // Dual Actions
          Consumer<AIController>(
            builder: (context, ai, child) {
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GradientButton(
                      label: 'Auto-Add to Pipeline',
                      icon: Icons.bolt_rounded,
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      isLoading: ai.isAnalyzing,
                      onPressed: ai.isAnalyzing ? null : _autoAddShared,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: BorderSide(
                          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                          width: 1.2,
                        ),
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
              ).animate().fadeIn(delay: 250.ms);
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODE 1: MANUAL ENTRY FORM
  // ===========================================================================
  Widget _buildManualFormView(BuildContext context, bool isDark) {
    final catColor = _manualCategory.color;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Selector
          Text(
            'Opportunity Category',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: OpportunityCategory.values.map((cat) {
                final isSelected = _manualCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected ? Colors.white : cat.color,
                    ),
                    label: Text(cat.label),
                    labelStyle: TextStyle(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontSize: 13,
                    ),
                    selected: isSelected,
                    selectedColor: cat.color,
                    backgroundColor: isDark ? const Color(0xFF181D2A) : const Color(0xFFEDF2F7),
                    side: BorderSide(
                      color: isSelected ? cat.color : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) {
                      if (val) setState(() => _manualCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 18),

          // Basics Card: Company & Role with live logo preview
          Container(
            decoration: AppTheme.cardDecoration(context, borderRadius: 20),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CompanyLogoWidget(
                      company: _companyPreview.isNotEmpty ? _companyPreview : 'Opportunity',
                      category: _manualCategory,
                      size: 46,
                      borderRadius: 14,
                      showCategoryBadge: true,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _companyPreview.isNotEmpty ? _companyPreview : 'Enter Company / Organizer',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _roleController.text.isNotEmpty ? _roleController.text : 'Specify Title / Position',
                            style: TextStyle(
                              color: catColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildStyledTextField(
                  context,
                  controller: _companyController,
                  labelText: _manualCategory == OpportunityCategory.hackathon
                      ? 'Hackathon / Organizer Name *'
                      : (_manualCategory == OpportunityCategory.event
                          ? 'Host / Organization *'
                          : (_manualCategory == OpportunityCategory.contest ? 'Platform / Host *' : 'Company / Organization *')),
                  hintText: 'e.g. Google, Amazon, ETHGlobal, Codeforces',
                  icon: Icons.business_rounded,
                ),
                const SizedBox(height: 12),
                _buildStyledTextField(
                  context,
                  controller: _roleController,
                  labelText: _manualCategory == OpportunityCategory.hackathon
                      ? 'Project Track / Role *'
                      : (_manualCategory == OpportunityCategory.event
                          ? 'Event / Session Title *'
                          : (_manualCategory == OpportunityCategory.contest ? 'Contest Division / Name *' : 'Role / Position *')),
                  hintText: 'e.g. Software Engineer Intern, AI Agent Track',
                  icon: _manualCategory.icon,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Pipeline Status Card
          Container(
            decoration: AppTheme.cardDecoration(context, borderRadius: 20),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag_rounded, color: catColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Pipeline Stage',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ApplicationStatus.values.map((status) {
                    final isSelected = _manualStatus == status;
                    return ChoiceChip(
                      label: Text(status.label),
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontSize: 12,
                      ),
                      selected: isSelected,
                      selectedColor: status.color,
                      backgroundColor: isDark ? const Color(0xFF151823) : const Color(0xFFEDF2F7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (val) {
                        if (val) setState(() => _manualStatus = status);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Timeline & Logistics Pickers Card
          Container(
            decoration: AppTheme.cardDecoration(context, borderRadius: 20),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: catColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Timeline & Deadlines',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildPickerButton(
                        context,
                        icon: Icons.event_rounded,
                        label: _manualInterviewDate != null
                            ? DateFormat('MMM d, yyyy').format(_manualInterviewDate!)
                            : 'Interview Date',
                        sublabel: _manualCategory == OpportunityCategory.hackathon
                            ? 'Pitch / Demo Day'
                            : (_manualCategory == OpportunityCategory.event ? 'Event Date' : 'Interview Date'),
                        isSet: _manualInterviewDate != null,
                        onTap: _pickInterviewDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPickerButton(
                        context,
                        icon: Icons.schedule_rounded,
                        label: _manualInterviewTime != null
                            ? _manualInterviewTime!.format(context)
                            : 'Set Time',
                        sublabel: 'Time of Day',
                        isSet: _manualInterviewTime != null,
                        onTap: _pickInterviewTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPickerButton(
                  context,
                  icon: Icons.timer_rounded,
                  label: _manualDeadline != null
                      ? DateFormat('MMM d, yyyy').format(_manualDeadline!)
                      : 'Application / Registration Deadline',
                  sublabel: 'Deadline to Submit',
                  isSet: _manualDeadline != null,
                  onTap: _pickDeadline,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Compensation & Logistics Card
          Container(
            decoration: AppTheme.cardDecoration(context, borderRadius: 20),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.payments_outlined, color: catColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Compensation & Location',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildStyledTextField(
                  context,
                  controller: _stipendController,
                  labelText: _manualCategory == OpportunityCategory.hackathon || _manualCategory == OpportunityCategory.contest
                      ? 'Prize Pool / Bounties'
                      : 'Stipend / Salary',
                  hintText: 'e.g. \$9,500/mo, ₹85,000/mo, or \$50,000 bounties',
                  icon: Icons.attach_money_rounded,
                ),
                const SizedBox(height: 12),
                _buildStyledTextField(
                  context,
                  controller: _locationController,
                  labelText: 'Location / City',
                  hintText: 'e.g. San Francisco, CA or Bengaluru',
                  icon: Icons.location_on_rounded,
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['Remote', 'Hybrid', 'On-Site'].map((mode) {
                    final isSelected = _manualWorkMode == mode;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(mode),
                        labelStyle: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.orange,
                        backgroundColor: isDark ? const Color(0xFF151823) : const Color(0xFFEDF2F7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (val) {
                          if (val) setState(() => _manualWorkMode = mode);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Notes
          Container(
            decoration: AppTheme.cardDecoration(context, borderRadius: 20),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notes_rounded, color: catColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Personal Notes & Recruiter Contacts',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Add recruiter contacts, referral notes, or portfolio links...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Big Save Button
          GradientButton(
            label: 'Save Opportunity to Pipeline',
            icon: Icons.check_circle_rounded,
            padding: const EdgeInsets.symmetric(vertical: 16),
            onPressed: _saveManualOpportunity,
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, size: 19, color: AppTheme.orange),
        filled: true,
        fillColor: isDark ? const Color(0xFF151C2A) : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.orange, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPickerButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String sublabel,
    required bool isSet,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151C2A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSet ? AppTheme.orange : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
            width: isSet ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSet ? AppTheme.orange : (isDark ? Colors.white54 : Colors.black45),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isSet
                          ? (isDark ? Colors.white : AppTheme.accentBlack)
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: AppTheme.cardDecoration(context, borderRadius: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
