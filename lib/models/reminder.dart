import 'package:flutter/material.dart';
import '../app/theme.dart';

enum ReminderType {
  interviewAlarm,
  deadlineAlert,
  prepNotification,
  custom;

  String get label => switch (this) {
        ReminderType.interviewAlarm => 'Interview Alarm',
        ReminderType.deadlineAlert => 'Deadline Alert',
        ReminderType.prepNotification => 'Prep Notification',
        ReminderType.custom => 'Reminder',
      };

  IconData get icon => switch (this) {
        ReminderType.interviewAlarm => Icons.alarm_rounded,
        ReminderType.deadlineAlert => Icons.hourglass_top_rounded,
        ReminderType.prepNotification => Icons.timer_outlined,
        ReminderType.custom => Icons.notifications_active_rounded,
      };

  Color get color => switch (this) {
        ReminderType.interviewAlarm => AppTheme.orange,
        ReminderType.deadlineAlert => const Color(0xFFEF4444),
        ReminderType.prepNotification => const Color(0xFF8B5CF6),
        ReminderType.custom => const Color(0xFF10B981),
      };
}

class Reminder {
  final String id;
  final String title;
  final String? company;
  final DateTime dateTime;
  final ReminderType type;
  final bool isEnabled;
  final bool isSoundEnabled;
  final String? applicationId;

  const Reminder({
    required this.id,
    required this.title,
    this.company,
    required this.dateTime,
    required this.type,
    this.isEnabled = true,
    this.isSoundEnabled = true,
    this.applicationId,
  });

  Reminder copyWith({
    String? id,
    String? title,
    String? company,
    DateTime? dateTime,
    ReminderType? type,
    bool? isEnabled,
    bool? isSoundEnabled,
    String? applicationId,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      applicationId: applicationId ?? this.applicationId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'dateTime': dateTime.toIso8601String(),
      'type': type.name,
      'isEnabled': isEnabled,
      'isSoundEnabled': isSoundEnabled,
      'applicationId': applicationId,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String?,
      dateTime: DateTime.parse(json['dateTime'] as String),
      type: ReminderType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ReminderType.custom,
      ),
      isEnabled: json['isEnabled'] as bool? ?? true,
      isSoundEnabled: json['isSoundEnabled'] as bool? ?? true,
      applicationId: json['applicationId'] as String?,
    );
  }
}
