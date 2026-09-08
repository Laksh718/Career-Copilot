import '../models/application.dart';
import '../models/career_extraction.dart';
import 'career_ai_service.dart';

class MockCareerAIService implements CareerAIService {
  static const List<String> _popularCompanies = [
    'Google', 'Microsoft', 'Amazon', 'Meta', 'Apple', 'Netflix',
    'Uber', 'Stripe', 'Spotify', 'Salesforce', 'LinkedIn',
    'Goldman Sachs', 'JPMorgan', 'Oracle', 'Cisco', 'Adobe',
    'Nvidia', 'OpenAI', 'Anthropic', 'Figma', 'Notion',
    'XYZ Technologies', 'Devpost', 'Codeforces', 'Unstop',
    'Airbnb', 'Atlassian', 'Coinbase', 'Polygon', 'Solana',
  ];

  static const List<String> _popularRoles = [
    'Software Engineering Intern',
    'Software Engineer',
    'SDE Intern',
    'AI Engineering Intern',
    'Machine Learning Intern',
    'Frontend Developer Intern',
    'Backend Developer Intern',
    'Full Stack Developer Intern',
    'Data Science Intern',
    'Product Management Intern',
    'DevOps Engineer Intern',
  ];

  @override
  Future<CareerExtraction> analyzeMessage(String message) async {
    // Fast simulated analysis
    await Future.delayed(const Duration(milliseconds: 600));

    final lower = message.toLowerCase();

    // 1. Company Extraction
    String? company;
    for (final comp in _popularCompanies) {
      if (lower.contains(comp.toLowerCase())) {
        company = comp;
        break;
      }
    }
    if (company == null) {
      final atMatch = RegExp(r'\b(?:at|with|from)\s+([A-Z][A-Za-z0-9&.\s]{1,24}?)(?=\s+(?:for|on|before|by|is|team|campus|,|\.|\n|$))').firstMatch(message);
      if (atMatch != null) {
        company = atMatch.group(1)?.trim();
      } else {
        final hiringMatch = RegExp(r'([A-Z][A-Za-z0-9&.\s]{1,24}?)\s+is hiring').firstMatch(message);
        if (hiringMatch != null) {
          company = hiringMatch.group(1)?.trim();
        }
      }
    }

    // 2. Role Extraction
    String? role;
    for (final r in _popularRoles) {
      if (lower.contains(r.toLowerCase())) {
        role = r;
        break;
      }
    }
    if (role == null) {
      final roleMatch = RegExp(r'(?:hiring|role of|position of|as an?)\s+([A-Z][A-Za-z0-9\s]{2,30}?)(?=\s+(?:intern|at|for|,|\.|\n|$))', caseSensitive: false).firstMatch(message);
      if (roleMatch != null) {
        final rawRole = roleMatch.group(1)?.trim();
        if (rawRole != null && rawRole.isNotEmpty) {
          role = '$rawRole${lower.contains('intern') && !rawRole.toLowerCase().contains('intern') ? ' Intern' : ''}';
        }
      }
    }
    if (role == null) {
      if (lower.contains('sde')) {
        role = 'SDE Intern';
      } else if (lower.contains('backend')) {
        role = 'Backend Engineer Intern';
      } else if (lower.contains('frontend')) {
        role = 'Frontend Engineer Intern';
      } else if (lower.contains('ai') || lower.contains('ml')) {
        role = 'AI Engineering Intern';
      } else if (lower.contains('intern')) {
        role = 'Software Engineering Intern';
      }
    }

    // 3. Time Extraction
    String? interviewTime;
    final timeMatch = RegExp(r'\b(\d{1,2}(?::\d{2})?\s*(?:am|pm|AM|PM))\b').firstMatch(message);
    if (timeMatch != null) {
      interviewTime = timeMatch.group(1)?.trim();
    }

    // 4. Date Extraction (Interview vs Deadline)
    String? interviewDate;
    String? deadline;

    final daysRegex = RegExp(r'\b(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|Tomorrow|Today)\b', caseSensitive: false);
    final monthRegex = RegExp(r'\b((?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+\d{1,2}(?:st|nd|rd|th)?)\b', caseSensitive: false);

    final allMatches = <String>[];
    for (final m in daysRegex.allMatches(message)) {
      final s = m.group(1);
      if (s != null && !allMatches.contains(s)) allMatches.add(s);
    }
    for (final m in monthRegex.allMatches(message)) {
      final s = m.group(1);
      if (s != null && !allMatches.contains(s)) allMatches.add(s);
    }

    for (final dateStr in allMatches) {
      final dateIndex = message.indexOf(dateStr);
      final precedingText = message.substring(dateIndex > 50 ? dateIndex - 50 : 0, dateIndex).toLowerCase();
      final followingText = message.substring(dateIndex, (dateIndex + 50) < message.length ? dateIndex + 50 : message.length).toLowerCase();
      final surrounding = '$precedingText $followingText';

      if (surrounding.contains('interview') || surrounding.contains('round') || surrounding.contains('discussion') || surrounding.contains('meet')) {
        interviewDate ??= dateStr;
      } else if (surrounding.contains('deadline') || surrounding.contains('close') || surrounding.contains('apply before') || surrounding.contains('last date') || surrounding.contains('cutoff')) {
        deadline ??= dateStr;
      } else if (interviewDate == null) {
        interviewDate = dateStr;
      } else {
        deadline ??= dateStr;
      }
    }

    // 5. Documents Extraction
    final List<String> requiredDocuments = [];
    if (lower.contains('resume') || lower.contains('cv')) requiredDocuments.add('Resume');
    if (lower.contains('college id') || lower.contains('id card') || lower.contains('student id')) requiredDocuments.add('College ID');
    if (lower.contains('portfolio') || lower.contains('github')) requiredDocuments.add('Portfolio');
    if (lower.contains('transcript') || lower.contains('grade')) requiredDocuments.add('Transcript');

    // 6. Work Mode & Compensation
    String? workMode;
    if (lower.contains('remote')) {
      workMode = 'Remote';
    } else if (lower.contains('hybrid')) {
      workMode = 'Hybrid';
    } else if (lower.contains('on-site') || lower.contains('onsite') || lower.contains('in-office')) {
      workMode = 'On-site';
    }

    String? stipend;
    final stipendMatch = RegExp(r'(₹[\d,]+(?:\s*(?:k|\/month|per month|lpa))?|\$[\d,]+(?:\s*(?:k|\/hr|\/month))?)').firstMatch(message);
    if (stipendMatch != null) {
      stipend = stipendMatch.group(1);
    } else if (lower.contains('25k') || lower.contains('25,000')) {
      stipend = '₹25,000/month';
    }

    // Determine status & next action
    String status = 'Applied';
    String nextAction = 'Review details';
    if (interviewDate != null && interviewDate.isNotEmpty) {
      status = 'Interview';
      nextAction = 'Prepare for interview';
    } else if (deadline != null && deadline.isNotEmpty) {
      status = 'Action Required';
      nextAction = 'Submit application before deadline';
    }

    return CareerExtraction(
      company: company ?? 'Tech Opportunity',
      role: role ?? 'Software Engineering Intern',
      interviewDate: interviewDate,
      interviewTime: interviewTime,
      deadline: deadline,
      requiredDocuments: requiredDocuments.isNotEmpty ? requiredDocuments : null,
      workMode: workMode,
      stipend: stipend,
      status: status,
      nextAction: nextAction,
    );
  }

  @override
  Future<String> draftReply(Application application) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return "Hi Hiring Team,\n\nThank you for this opportunity! I would like to confirm my interview for ${application.role} at ${application.company}.\n\nBest regards,\nLaksh";
  }

  @override
  Future<String> explainRequirements(Application application) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return "You need to submit the following documents: ${application.requiredDocuments.map((e) => e.name).join(', ')}.";
  }

  @override
  Future<List<String>> generateInterviewQuestions(Application application) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      "Tell me about a time you overcame a technical challenge.",
      "What are the core concepts of Object-Oriented Programming?",
      "Why do you want to intern at ${application.company}?"
    ];
  }

  @override
  Future<String> summarizeOpportunity(Application application) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return "This is a ${application.role} position at ${application.company}. Ensure you track the deadline on ${application.deadline}.";
  }

  @override
  Future<String> chatWithCareerCoach(String userMessage, List<Application> applications) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final lower = userMessage.toLowerCase().trim();

    // 1. Greetings & Introductory
    if (lower == 'hi' || lower == 'hello' || lower == 'hey' || lower.startsWith('good morning') || lower.startsWith('good evening')) {
      return "### SUMMARY\n"
          "Hello! I am Career Copilot, your AI executive career strategist and application tracker.\n\n"
          "### HIGHLIGHTS\n"
          "• Tracked Applications: ${applications.length}\n"
          "• Interviews Active: ${applications.where((a) => a.interviewDate.isNotEmpty).length}\n"
          "• Action Items Pending: ${applications.where((a) => a.status == ApplicationStatus.actionRequired).length}\n\n"
          "### ACTION PLAN\n"
          "1. Ask me to 'prep for interviews' to rehearse technical or behavioral questions.\n"
          "2. Ask me to 'draft a follow-up email' for any recruiter.\n"
          "3. Ask about upcoming deadlines or tracking new opportunities.\n\n"
          "### PRO TIP\n"
          "Consistency wins: Aim to submit 3-5 thoughtful, tailored applications daily for top tech roles.";
    }

    // 2. Coding Interview & DSA Prep (Check before general interview schedule queries)
    if (lower.contains('dsa') || lower.contains('leetcode') || lower.contains('coding') || lower.contains('technical') || lower.contains('system design') || (lower.contains('prep') && !lower.contains('when'))) {
      return "### SUMMARY\n"
          "Technical interview success relies on pattern recognition rather than memorizing individual problems.\n\n"
          "### HIGHLIGHTS\n"
          "• Core Patterns: Two Pointers, Sliding Window, BFS/DFS, Binary Search, Dynamic Programming.\n"
          "• Communication: Think out loud. State brute force first before optimizing time/space complexity.\n"
          "• Edge Cases: Test null, single element, negative numbers, and duplicates before running code.\n\n"
          "### ACTION PLAN\n"
          "1. Solve 2 medium problems daily categorized by pattern (e.g. Blind 75 / NeetCode 150).\n"
          "2. Practice 20-minute mock whiteboard sessions under timed constraints.\n\n"
          "### PRO TIP\n"
          "Interviewers value how you respond to hints even more than getting an immediate perfect answer.";
    }

    // 2. Interviews & Schedules
    if (lower.contains('interview') || lower.contains('when is') || lower.contains('schedule') || lower.contains('meeting')) {
      final interviews = applications.where((a) => a.interviewDate.isNotEmpty).toList();
      if (interviews.isEmpty) {
        return "### SUMMARY\n"
            "You currently have no interview rounds scheduled on your calendar.\n\n"
            "### HIGHLIGHTS\n"
            "• Keep expanding your pipeline across early-career openings.\n"
            "• Reach out to college alumni on LinkedIn for warm internal referrals.\n\n"
            "### ACTION PLAN\n"
            "1. Review applications marked 'Waiting for Response'.\n"
            "2. Send polite check-in notes to roles applied > 7 business days ago.\n\n"
            "### PRO TIP\n"
            "Candidates with internal employee referrals are 4x more likely to be called for an interview.";
      }
      final buffer = StringBuffer("### SUMMARY\n");
      buffer.writeln("You have ${interviews.length} upcoming interview round(s) scheduled!\n");
      buffer.writeln("### HIGHLIGHTS");
      for (final app in interviews) {
        buffer.writeln("• ${app.company} (${app.role}) on ${app.interviewDate}${app.interviewTime.isNotEmpty ? ' at ${app.interviewTime}' : ''}");
      }
      buffer.writeln("\n### ACTION PLAN");
      buffer.writeln("1. Review company engineering values, architecture, and recent product launches.");
      buffer.writeln("2. Prepare 3 stories in STAR format (Situation, Task, Action, Result) showcasing leadership.");
      buffer.writeln("\n### PRO TIP");
      buffer.writeln("Always prepare 2 thoughtful reverse-interview questions about team challenges for your interviewer.");
      return buffer.toString();
    }

    // 3. Deadlines & Closing dates
    if (lower.contains('deadline') || lower.contains('due') || lower.contains('closing') || lower.contains('cutoff')) {
      final deadlines = applications.where((a) => a.deadline.isNotEmpty).toList();
      if (deadlines.isEmpty) {
        return "### SUMMARY\n"
            "No urgent deadlines are currently pending across your tracked opportunities.\n\n"
            "### HIGHLIGHTS\n"
            "• All tracked applications are up to date.\n"
            "• You can add application deadlines directly from the Calendar or Ingestion tab.\n\n"
            "### ACTION PLAN\n"
            "1. Check university placement portals or Devpost hackathons for upcoming deadlines.\n"
            "2. Tap the '+' button in the navigation bar to add new roles.\n\n"
            "### PRO TIP\n"
            "Submit applications within the first 48 hours of posting for maximum recruiter visibility.";
      }
      final buffer = StringBuffer("### SUMMARY\n");
      buffer.writeln("You have ${deadlines.length} upcoming application cutoff(s) to monitor.\n");
      buffer.writeln("### HIGHLIGHTS");
      for (final app in deadlines) {
        buffer.writeln("• ${app.company} (${app.role}) — Closing: ${app.deadline}");
      }
      buffer.writeln("\n### ACTION PLAN");
      buffer.writeln("1. Ensure your resume, transcripts, and personal project links are finalized.");
      buffer.writeln("2. Submit early to prevent last-minute server congestion on portal cutoffs.");
      return buffer.toString();
    }

    // 4. Draft Email / Follow-up Template
    if (lower.contains('draft') || lower.contains('email') || lower.contains('follow up') || lower.contains('follow-up') || lower.contains('outreach')) {
      final app = applications.isNotEmpty ? applications.first : null;
      final company = app?.company ?? "the company";
      final role = app?.role ?? "Software Engineer Intern";
      return "### SUMMARY\n"
          "Here is an executive-ready follow-up template tailored for the hiring team at $company.\n\n"
          "### TEMPLATE\n"
          "Subject: Following Up on My Application - $role - Laksh\n\n"
          "Dear $company Hiring Team,\n\n"
          "I hope this week is treating you well. I recently submitted my application for the $role position at $company and wanted to reiterate my strong enthusiasm for joining the team.\n\n"
          "With hands-on experience building scalable applications and solving complex algorithmic challenges, I am eager to contribute immediately to your engineering goals. Please let me know if any additional details or portfolio links would be helpful.\n\n"
          "Thank you for your time and continued consideration!\n\n"
          "Sincerely,\n"
          "Laksh\n\n"
          "### ACTION PLAN\n"
          "1. Personalize the recipient name if known from LinkedIn.\n"
          "2. Send Tuesday or Thursday morning between 9:00 AM - 10:30 AM for peak response rates.\n\n"
          "### PRO TIP\n"
          "Keep follow-ups under 100 words. Recruiters read emails on mobile in under 15 seconds.";
    }

    // 5. Resume & Portfolio Tips
    if (lower.contains('resume') || lower.contains('cv') || lower.contains('portfolio') || lower.contains('ats')) {
      return "### SUMMARY\n"
          "High-impact resumes quantify outcomes rather than listing daily responsibilities.\n\n"
          "### HIGHLIGHTS\n"
          "• Formula: Accomplished [X] as measured by [Y], by doing [Z].\n"
          "• Keep to strict 1 page with clean single-column ATS-friendly hierarchy.\n"
          "• Include live deployed links and GitHub repositories for all personal projects.\n\n"
          "### ACTION PLAN\n"
          "1. Run your resume through an ATS keyword matcher against target job descriptions.\n"
          "2. Replace passive verbs ('assisted with') with impact verbs ('engineered', 'spearheaded', 'reduced latency by 40%').\n\n"
          "### PRO TIP\n"
          "Link your top 2 GitHub repos directly in the header—hiring managers love viewing clean code commits.";
    }

    // 6. Coding Interview & DSA Prep
    if (lower.contains('prep') || lower.contains('dsa') || lower.contains('leetcode') || lower.contains('coding') || lower.contains('technical') || lower.contains('system design')) {
      return "### SUMMARY\n"
          "Technical interview success relies on pattern recognition rather than memorizing individual problems.\n\n"
          "### HIGHLIGHTS\n"
          "• Core Patterns: Two Pointers, Sliding Window, BFS/DFS, Binary Search, Dynamic Programming.\n"
          "• Communication: Think out loud. State brute force first before optimizing time/space complexity.\n"
          "• Edge Cases: Test null, single element, negative numbers, and duplicates before running code.\n\n"
          "### ACTION PLAN\n"
          "1. Solve 2 medium problems daily categorized by pattern (e.g. Blind 75 / NeetCode 150).\n"
          "2. Practice 20-minute mock whiteboard sessions under timed constraints.\n\n"
          "### PRO TIP\n"
          "Interviewers value how you respond to hints even more than getting an immediate perfect answer.";
    }

    // 7. Salary & Stipend Negotiation
    if (lower.contains('salary') || lower.contains('stipend') || lower.contains('negotiat') || lower.contains('compensation') || lower.contains('offer')) {
      return "### SUMMARY\n"
          "Always express genuine enthusiasm before asking for compensation adjustments.\n\n"
          "### HIGHLIGHTS\n"
          "• Market Data: Check Levels.fyi and Glassdoor for peer benchmark bands.\n"
          "• Leverage: Competing offers or specialized technical skills provide the highest leverage.\n"
          "• Non-Monetary: Sign-on bonuses, relocation assistance, and mentorship can also be negotiated.\n\n"
          "### ACTION PLAN\n"
          "1. Ask for 48 hours to review any formal offer package before accepting.\n"
          "2. Frame inquiries collaboratively: 'Is there flexibility in the base stipend for top performers?'\n\n"
          "### PRO TIP\n"
          "Never initiate negotiation until you have a written offer in hand.";
    }

    // 8. Application Status & Pipeline Overview
    if (lower.contains('status') || lower.contains('how many') || lower.contains('apps') || lower.contains('summary') || lower.contains('tracker')) {
      final total = applications.length;
      final interviews = applications.where((a) => a.status == ApplicationStatus.interview).length;
      final actionReq = applications.where((a) => a.status == ApplicationStatus.actionRequired).length;
      final waiting = applications.where((a) => a.status == ApplicationStatus.waiting).length;
      return "### SUMMARY\n"
          "You are currently tracking $total opportunity(ies) across all recruitment stages.\n\n"
          "### HIGHLIGHTS\n"
          "• Interviews Scheduled: $interviews\n"
          "• Action Items Required: $actionReq\n"
          "• Awaiting Response: $waiting\n\n"
          "### ACTION PLAN\n"
          "1. Prioritize applications requiring documentation or deadline submission.\n"
          "2. Review your Calendar tab to set reminders for upcoming dates.\n\n"
          "### PRO TIP\n"
          "Maintain a healthy pipeline of at least 15 active opportunities to maximize conversion chances.";
    }

    // 9. Intelligent General Coaching Fallback
    return "### SUMMARY\n"
        "I'm analyzing your career pipeline of ${applications.length} tracked application(s).\n\n"
        "### HIGHLIGHTS\n"
        "• Ask me: 'When is my next interview?'\n"
        "• Ask me: 'Draft a follow-up email'\n"
        "• Ask me: 'Give me technical interview tips'\n"
        "• Ask me: 'Review resume keywords for software roles'\n\n"
        "### ACTION PLAN\n"
        "1. Tap any suggested quick prompt below or type your career question.\n"
        "2. Connect your Google Gemini API key via Profile or header chip for live generative reasoning!";
  }
}

