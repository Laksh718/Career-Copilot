import '../models/application.dart';
import '../models/career_extraction.dart';
import 'career_ai_service.dart';

class MockCareerAIService implements CareerAIService {
  @override
  Future<CareerExtraction> analyzeMessage(String message) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    final String lowerMsg = message.toLowerCase();

    // Mock extraction logic based on the required demo flow
    // "Hi Laksh, XYZ Technologies is hiring Software Engineering Interns. Your interview is scheduled Monday at 8 PM. Please submit your resume and college ID. Applications close September 12."
    
    String? company;
    if (lowerMsg.contains('xyz technologies')) company = 'XYZ Technologies';
    if (lowerMsg.contains('microsoft')) company = 'Microsoft';
    if (lowerMsg.contains('google')) company = 'Google';
    if (lowerMsg.contains('amazon')) company = 'Amazon';

    String? role;
    if (lowerMsg.contains('software engineering intern')) role = 'Software Engineering Intern';
    if (lowerMsg.contains('sde intern')) role = 'SDE Intern';
    if (lowerMsg.contains('ai engineering intern')) role = 'AI Engineering Intern';

    String? interviewDate;
    String? interviewTime;
    if (lowerMsg.contains('monday')) interviewDate = 'Monday';
    if (lowerMsg.contains('8 pm')) interviewTime = '8:00 PM';
    
    String? deadline;
    if (lowerMsg.contains('september 12')) deadline = 'September 12';
    
    List<String> requiredDocuments = [];
    if (lowerMsg.contains('resume')) requiredDocuments.add('Resume');
    if (lowerMsg.contains('college id')) requiredDocuments.add('College ID');
    if (lowerMsg.contains('portfolio')) requiredDocuments.add('Portfolio');

    String? workMode;
    if (lowerMsg.contains('remote')) workMode = 'Remote';

    String? stipend;
    if (lowerMsg.contains('₹25,000') || lowerMsg.contains('25k')) stipend = '₹25,000/month';

    return CareerExtraction(
      company: company,
      role: role,
      interviewDate: interviewDate,
      interviewTime: interviewTime,
      deadline: deadline,
      requiredDocuments: requiredDocuments.isNotEmpty ? requiredDocuments : null,
      workMode: workMode,
      stipend: stipend,
      status: interviewDate != null ? 'Interview' : (deadline != null ? 'Action Required' : 'Applied'),
      nextAction: requiredDocuments.isNotEmpty ? 'Submit documents' : 'Prepare for interview',
    );
  }

  @override
  Future<String> draftReply(Application application) async {
    await Future.delayed(const Duration(seconds: 1));
    return "Hi Hiring Team,\n\nThank you for this opportunity! I would like to confirm my interview for ${application.role} at ${application.company}.\n\nBest regards,\nLaksh";
  }

  @override
  Future<String> explainRequirements(Application application) async {
    await Future.delayed(const Duration(seconds: 1));
    return "You need to submit the following documents: ${application.requiredDocuments.map((e) => e.name).join(', ')}.";
  }

  @override
  Future<List<String>> generateInterviewQuestions(Application application) async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      "Tell me about a time you overcame a technical challenge.",
      "What are the core concepts of Object-Oriented Programming?",
      "Why do you want to intern at ${application.company}?"
    ];
  }

  @override
  Future<String> summarizeOpportunity(Application application) async {
    await Future.delayed(const Duration(seconds: 1));
    return "This is a ${application.role} position at ${application.company}. Ensure you track the deadline on ${application.deadline}.";
  }

  @override
  Future<String> chatWithCareerCoach(String userMessage, List<Application> applications) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final lower = userMessage.toLowerCase();

    // 1. Interviews
    if (lower.contains('interview') || lower.contains('when is') || lower.contains('schedule')) {
      final interviews = applications.where((a) => a.interviewDate.isNotEmpty).toList();
      if (interviews.isEmpty) {
        return "### SUMMARY\n"
            "You currently have no interviews scheduled on your calendar.\n\n"
            "### HIGHLIGHTS\n"
            "• Keep applying to 3-5 roles daily to maintain a strong pipeline.\n"
            "• Target warm referrals via college alumni on LinkedIn.\n\n"
            "### ACTION PLAN\n"
            "1. Review applications marked 'Waiting for Response'.\n"
            "2. Send polite follow-ups to companies applied > 5 days ago.\n\n"
            "### PRO TIP\n"
            "Candidates who follow up with hiring teams have a 30% higher response rate.";
      }
      final buffer = StringBuffer("### SUMMARY\n");
      buffer.writeln("You have ${interviews.length} upcoming interview round(s) scheduled!\n");
      buffer.writeln("### HIGHLIGHTS");
      for (final app in interviews) {
        buffer.writeln("• ${app.company} (${app.role}) on ${app.interviewDate}${app.interviewTime.isNotEmpty ? ' at ${app.interviewTime}' : ''}");
      }
      buffer.writeln("\n### ACTION PLAN");
      buffer.writeln("1. Review company values and recent news for each organization.");
      buffer.writeln("2. Prepare 3 stories in STAR format detailing your top technical projects.");
      buffer.writeln("\n### PRO TIP");
      buffer.writeln("Always have 2 tailored questions ready for your interviewer at the end of the round.");
      return buffer.toString();
    }

    // 2. Deadlines
    if (lower.contains('deadline') || lower.contains('due') || lower.contains('closing')) {
      final deadlines = applications.where((a) => a.deadline.isNotEmpty).toList();
      if (deadlines.isEmpty) {
        return "### SUMMARY\n"
            "No urgent deadlines are currently pending on your calendar.\n\n"
            "### HIGHLIGHTS\n"
            "• All tracked opportunities are up to date.\n"
            "• You can add new application deadlines directly from the Calendar screen.\n\n"
            "### ACTION PLAN\n"
            "1. Explore new internship openings on campus portals.\n"
            "2. Track new applications using the '+' button.";
      }
      final buffer = StringBuffer("### SUMMARY\n");
      buffer.writeln("You have ${deadlines.length} upcoming deadline(s) to monitor.\n");
      buffer.writeln("### HIGHLIGHTS");
      for (final app in deadlines) {
        buffer.writeln("• ${app.company} (${app.role}) — Closing: ${app.deadline}");
      }
      buffer.writeln("\n### ACTION PLAN");
      buffer.writeln("1. Prepare your resume, transcripts, and portfolio before the cutoff.");
      buffer.writeln("2. Submit at least 24 hours ahead to avoid server traffic.");
      return buffer.toString();
    }

    // 3. Draft email / follow-up
    if (lower.contains('draft') || lower.contains('email') || lower.contains('follow up') || lower.contains('follow-up')) {
      final app = applications.isNotEmpty ? applications.first : null;
      final company = app?.company ?? "the company";
      final role = app?.role ?? "Software Engineer Intern";
      return "### SUMMARY\n"
          "Here is a tailored follow-up email ready to send to the hiring team at $company.\n\n"
          "### TEMPLATE\n"
          "Subject: Following Up on My Application - $role\n\n"
          "Dear Hiring Team,\n\n"
          "I hope you are having a wonderful week. I am writing to reiterate my strong interest in the $role position at $company.\n\n"
          "Given my background and passion for developing scalable, high-impact products, I am confident I would be a dedicated contributor to your engineering initiatives. Please let me know if any additional documents are needed.\n\n"
          "Thank you for your time and consideration!\n\n"
          "Best regards,\n"
          "Laksh\n\n"
          "### ACTION PLAN\n"
          "1. Copy the template above and personalize the greeting.\n"
          "2. Send via email or message the recruiter on LinkedIn.\n\n"
          "### PRO TIP\n"
          "Send emails on Tuesday or Thursday mornings between 9:00 AM - 10:30 AM for the highest open rates.";
    }

    // 4. Summarize applications
    if (lower.contains('status') || lower.contains('how many') || lower.contains('summary') || lower.contains('apps')) {
      final total = applications.length;
      final interviews = applications.where((a) => a.status == ApplicationStatus.interview).length;
      final actionReq = applications.where((a) => a.status == ApplicationStatus.actionRequired).length;
      final waiting = applications.where((a) => a.status == ApplicationStatus.waiting).length;
      return "### SUMMARY\n"
          "You are tracking a total of $total applications across all hiring stages.\n\n"
          "### HIGHLIGHTS\n"
          "• Interviews Scheduled: $interviews\n"
          "• Action Required / Deadlines: $actionReq\n"
          "• Waiting for Recruiter Response: $waiting\n\n"
          "### ACTION PLAN\n"
          "1. Focus today on applications marked 'Action Required'.\n"
          "2. Set interview reminders on your Calendar screen.\n\n"
          "### PRO TIP\n"
          "Aim for a 15-20% interview conversion rate by tailoring resume keywords to each job description.";
    }

    // 5. Preparation / Tips
    if (lower.contains('prep') || lower.contains('tip') || lower.contains('advice') || lower.contains('stand out')) {
      return "### SUMMARY\n"
          "Here are 3 battle-tested strategies to outperform other applicants in technical rounds.\n\n"
          "### HIGHLIGHTS\n"
          "• STAR Framework: Master 4 structured stories for behavioral questions.\n"
          "• System Architecture: Be ready to explain tradeoffs in your personal projects.\n"
          "• Reverse Interviewing: Ask questions that reveal team engineering culture.\n\n"
          "### ACTION PLAN\n"
          "1. Write down 3 key achievements with quantifiable metrics.\n"
          "2. Practice answering: 'Tell me about a technical setback you resolved.'\n\n"
          "### PRO TIP\n"
          "Focus on the *why* behind your technical decisions, not just the code syntax.";
    }

    // 6. Default Coach response
    return "### SUMMARY\n"
        "I'm your dedicated Career Copilot! I can help you prepare for interviews, track deadlines, or draft outreach emails.\n\n"
        "### HIGHLIGHTS\n"
        "• Ask me: 'Show my upcoming interviews'\n"
        "• Ask me: 'Draft a follow-up email'\n"
        "• Ask me: 'What deadlines are coming up?'\n"
        "• Ask me: 'Give me interview prep questions'\n\n"
        "### ACTION PLAN\n"
        "Tap any prompt suggestion or type your question below!";

  }
}
