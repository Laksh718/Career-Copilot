import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/application.dart';

class ApplicationRepository {
  static const String _key = 'career_copilot_applications';
  final SharedPreferences _prefs;

  ApplicationRepository(this._prefs);

  List<Application> getApplications() {
    final String? jsonStr = _prefs.getString(_key);
    if (jsonStr == null) {
      return _getSampleData();
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => Application.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error parsing applications: $e');
      return _getSampleData();
    }
  }

  Future<void> saveApplications(List<Application> applications) async {
    final String jsonStr = jsonEncode(applications.map((e) => e.toJson()).toList());
    await _prefs.setString(_key, jsonStr);
  }

  List<Application> _getSampleData() {
    final now = DateTime.now();
    return [
      Application(
        id: '1',
        company: 'Microsoft',
        role: 'Software Engineer Intern',
        category: OpportunityCategory.job,
        status: ApplicationStatus.interview,
        interviewDate: 'September 8, 2026',
        interviewTime: '8:00 PM',
        location: 'Redmond / Virtual',
        stipend: '\$9,500 / mo',
        createdAt: now.subtract(const Duration(days: 5)),
        notes: 'Final technical round focusing on system architecture and DSA.',
      ),
      Application(
        id: '2',
        company: 'ETHGlobal Hackathon',
        role: 'AI & Web3 Innovation Track',
        category: OpportunityCategory.hackathon,
        status: ApplicationStatus.actionRequired,
        deadline: 'September 10, 2026',
        location: 'Virtual / Global',
        stipend: '\$45,000 Prize Pool',
        createdAt: now.subtract(const Duration(days: 2)),
        notes: 'Submit team registration and architecture diagram before midnight.',
      ),
      Application(
        id: '3',
        company: 'Google Cloud Summit 2026',
        role: 'GenAI & Cloud Architecture Keynote',
        category: OpportunityCategory.event,
        status: ApplicationStatus.interview,
        interviewDate: 'September 14, 2026',
        interviewTime: '10:00 AM',
        location: 'San Francisco & Online',
        createdAt: now.subtract(const Duration(days: 4)),
        notes: 'Confirmed RSVP badge. Hands-on labs start at 11:30 AM.',
      ),
      Application(
        id: '4',
        company: 'ICPC Regional / Codeforces',
        role: 'Div 1 Competitive Programming Round',
        category: OpportunityCategory.contest,
        status: ApplicationStatus.actionRequired,
        deadline: 'September 16, 2026',
        location: 'Online Contest',
        stipend: 'Global Rank & Badges',
        createdAt: now.subtract(const Duration(days: 1)),
        notes: 'Brush up on graph algorithms, segment trees, and dynamic programming.',
      ),
      Application(
        id: '5',
        company: 'Amazon AWS',
        role: 'SDE Intern',
        category: OpportunityCategory.job,
        status: ApplicationStatus.waiting,
        deadline: 'September 18, 2026',
        location: 'Seattle, WA',
        stipend: '\$8,800 / mo',
        createdAt: now.subtract(const Duration(days: 6)),
        notes: 'Online assessment completed. Awaiting recruiter response.',
      ),
      Application(
        id: '6',
        company: 'Smart India Hackathon',
        role: 'Autonomous Drone Navigation Challenge',
        category: OpportunityCategory.hackathon,
        status: ApplicationStatus.applied,
        deadline: 'September 22, 2026',
        location: 'New Delhi',
        stipend: '₹1,00,000 Grand Prize',
        createdAt: now,
        notes: 'Phase 1 PPT proposal submitted with hardware specifications.',
      ),
    ];
  }
}
