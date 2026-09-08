import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'required_document.dart';

enum ApplicationStatus { applied, interview, actionRequired, waiting }

extension ApplicationStatusX on ApplicationStatus {
  String get label => switch (this) {
        ApplicationStatus.applied => 'Applied',
        ApplicationStatus.actionRequired => 'Action Required',
        ApplicationStatus.interview => 'Interview',
        ApplicationStatus.waiting => 'Waiting',
      };

  Color get color => switch (this) {
        ApplicationStatus.applied => AppTheme.vibrantBlue,
        ApplicationStatus.actionRequired => AppTheme.vibrantRed,
        ApplicationStatus.interview => AppTheme.vibrantOrange,
        ApplicationStatus.waiting => AppTheme.vibrantPurple,
      };

  IconData get icon => switch (this) {
        ApplicationStatus.applied => Icons.send_rounded,
        ApplicationStatus.actionRequired => Icons.assignment_late_rounded,
        ApplicationStatus.interview => Icons.video_call_rounded,
        ApplicationStatus.waiting => Icons.hourglass_top_rounded,
      };
}

enum OpportunityCategory {
  job,
  hackathon,
  event,
  contest;

  String get label => switch (this) {
        OpportunityCategory.job => 'Job / Internship',
        OpportunityCategory.hackathon => 'Hackathon',
        OpportunityCategory.event => 'Tech Event / Workshop',
        OpportunityCategory.contest => 'Coding Contest',
      };

  String get shortLabel => switch (this) {
        OpportunityCategory.job => 'Job',
        OpportunityCategory.hackathon => 'Hackathon',
        OpportunityCategory.event => 'Event',
        OpportunityCategory.contest => 'Contest',
      };

  IconData get icon => switch (this) {
        OpportunityCategory.job => Icons.work_rounded,
        OpportunityCategory.hackathon => Icons.terminal_rounded,
        OpportunityCategory.event => Icons.event_note_rounded,
        OpportunityCategory.contest => Icons.emoji_events_rounded,
      };

  Color get color => switch (this) {
        OpportunityCategory.job => AppTheme.orange,
        OpportunityCategory.hackathon => const Color(0xFF8B5CF6),
        OpportunityCategory.event => const Color(0xFF10B981),
        OpportunityCategory.contest => const Color(0xFF3B82F6),
      };
}

class Application {
  final String id;
  final String company;
  final String role;
  final OpportunityCategory category;
  final String location;
  final String workMode;
  final String stipend;
  final String salary;
  final String deadline;
  final String interviewDate;
  final String interviewTime;
  final List<RequiredDocument> requiredDocuments;
  final String applicationLink;
  final String eligibility;
  final ApplicationStatus status;
  final String nextAction;
  final String source;
  final DateTime createdAt;
  final String notes;

  Application({
    required this.id,
    required this.company,
    required this.role,
    this.category = OpportunityCategory.job,
    this.location = '',
    this.workMode = '',
    this.stipend = '',
    this.salary = '',
    this.deadline = '',
    this.interviewDate = '',
    this.interviewTime = '',
    this.requiredDocuments = const [],
    this.applicationLink = '',
    this.eligibility = '',
    this.status = ApplicationStatus.applied,
    this.nextAction = '',
    this.source = '',
    required this.createdAt,
    this.notes = '',
  });

  Application copyWith({
    String? id,
    String? company,
    String? role,
    OpportunityCategory? category,
    String? location,
    String? workMode,
    String? stipend,
    String? salary,
    String? deadline,
    String? interviewDate,
    String? interviewTime,
    List<RequiredDocument>? requiredDocuments,
    String? applicationLink,
    String? eligibility,
    ApplicationStatus? status,
    String? nextAction,
    String? source,
    DateTime? createdAt,
    String? notes,
  }) {
    return Application(
      id: id ?? this.id,
      company: company ?? this.company,
      role: role ?? this.role,
      category: category ?? this.category,
      location: location ?? this.location,
      workMode: workMode ?? this.workMode,
      stipend: stipend ?? this.stipend,
      salary: salary ?? this.salary,
      deadline: deadline ?? this.deadline,
      interviewDate: interviewDate ?? this.interviewDate,
      interviewTime: interviewTime ?? this.interviewTime,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      applicationLink: applicationLink ?? this.applicationLink,
      eligibility: eligibility ?? this.eligibility,
      status: status ?? this.status,
      nextAction: nextAction ?? this.nextAction,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company': company,
      'role': role,
      'category': category.name,
      'location': location,
      'workMode': workMode,
      'stipend': stipend,
      'salary': salary,
      'deadline': deadline,
      'interviewDate': interviewDate,
      'interviewTime': interviewTime,
      'requiredDocuments': requiredDocuments.map((x) => x.toJson()).toList(),
      'applicationLink': applicationLink,
      'eligibility': eligibility,
      'status': status.name,
      'nextAction': nextAction,
      'source': source,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] as String,
      company: json['company'] as String,
      role: json['role'] as String,
      category: OpportunityCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () {
          // Smart heuristic fallback for legacy data
          final text = '${json['company'] ?? ''} ${json['role'] ?? ''}'.toLowerCase();
          if (text.contains('hackathon') || text.contains('hack')) return OpportunityCategory.hackathon;
          if (text.contains('summit') || text.contains('workshop') || text.contains('conference') || text.contains('meetup')) {
            return OpportunityCategory.event;
          }
          if (text.contains('contest') || text.contains('codeforces') || text.contains('icpc') || text.contains('leetcode')) {
            return OpportunityCategory.contest;
          }
          return OpportunityCategory.job;
        },
      ),
      location: json['location'] as String? ?? '',
      workMode: json['workMode'] as String? ?? '',
      stipend: json['stipend'] as String? ?? '',
      salary: json['salary'] as String? ?? '',
      deadline: json['deadline'] as String? ?? '',
      interviewDate: json['interviewDate'] as String? ?? '',
      interviewTime: json['interviewTime'] as String? ?? '',
      requiredDocuments: (json['requiredDocuments'] as List<dynamic>?)
              ?.map((x) => RequiredDocument.fromJson(x as Map<String, dynamic>))
              .toList() ??
          [],
      applicationLink: json['applicationLink'] as String? ?? '',
      eligibility: json['eligibility'] as String? ?? '',
      status: ApplicationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ApplicationStatus.applied,
      ),
      nextAction: json['nextAction'] as String? ?? '',
      source: json['source'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      notes: json['notes'] as String? ?? '',
    );
  }
}
