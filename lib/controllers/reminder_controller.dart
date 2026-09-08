import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart';
import '../services/notification_service.dart';

class ReminderController extends ChangeNotifier {
  static const String _storageKey = 'career_copilot_reminders';
  static const String _notifEnabledKey = 'career_copilot_notifications_enabled';
  final SharedPreferences _prefs;
  final NotificationService _notificationService = NotificationService();

  List<Reminder> _reminders = [];
  bool _notificationsEnabled = true;
  bool _isLoading = false;

  ReminderController(this._prefs) {
    _notificationsEnabled = _prefs.getBool(_notifEnabledKey) ?? true;
    _loadReminders();
  }

  List<Reminder> get reminders => List.unmodifiable(_reminders);
  List<Reminder> get activeReminders => _reminders.where((r) => r.isEnabled).toList();
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoading => _isLoading;

  int _notificationId(String reminderId) {
    return reminderId.hashCode.abs() % 1000000;
  }

  Future<bool> requestAndEnableNotifications() async {
    final granted = await _notificationService.requestPermission();
    _notificationsEnabled = true;
    await _prefs.setBool(_notifEnabledKey, true);
    
    // Schedule all active reminders
    for (final r in activeReminders) {
      _schedule(r);
    }

    // Trigger instant verification notification
    await _notificationService.showInstantNotification(
      id: 999,
      title: 'Career Copilot Notifications Active',
      body: 'Alarms and reminders are configured to notify you for upcoming deadlines.',
    );

    notifyListeners();
    return granted;
  }

  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    await _prefs.setBool(_notifEnabledKey, enabled);

    if (enabled) {
      await _notificationService.requestPermission();
      for (final r in activeReminders) {
        _schedule(r);
      }
    } else {
      for (final r in _reminders) {
        await _notificationService.cancelNotification(_notificationId(r.id));
      }
    }

    notifyListeners();
  }

  Future<void> testAlarmNotification() async {
    await _notificationService.showInstantNotification(
      id: 888,
      title: 'Career Copilot Test Alarm',
      body: 'Your alarm and notification tone is configured and sounding properly.',
    );
  }

  void _schedule(Reminder reminder) {
    if (!_notificationsEnabled || !reminder.isEnabled) return;
    _notificationService.scheduleNotification(
      id: _notificationId(reminder.id),
      title: reminder.title,
      body: '${reminder.company != null && reminder.company!.isNotEmpty ? "${reminder.company}: " : ""}${reminder.type.label}',
      scheduledDate: reminder.dateTime,
    );
  }

  void _loadReminders() {
    _isLoading = true;
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
        _reminders = list
            .map((item) => Reminder.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error loading reminders: $e');
        _reminders = _getInitialReminders();
        _save();
      }
    } else {
      _reminders = _getInitialReminders();
      _save();
    }
    _reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    _isLoading = false;
    notifyListeners();
  }

  List<Reminder> _getInitialReminders() {
    final now = DateTime.now();
    return [
      Reminder(
        id: 'rem-1',
        title: 'Amazon SDE Technical Interview Alarm',
        company: 'Amazon',
        dateTime: DateTime(now.year, now.month, now.day + 1, 9, 30),
        type: ReminderType.interviewAlarm,
        isEnabled: true,
        isSoundEnabled: true,
        applicationId: 'sample-app-amazon',
      ),
      Reminder(
        id: 'rem-2',
        title: 'ETHGlobal Hackathon Code Freeze & Submission',
        company: 'ETHGlobal',
        dateTime: DateTime(now.year, 11, 20, 23, 59),
        type: ReminderType.deadlineAlert,
        isEnabled: true,
        isSoundEnabled: true,
        applicationId: 'sample-hack-eth',
      ),
      Reminder(
        id: 'rem-3',
        title: 'Google Cloud Summit Keynote Alert',
        company: 'Google',
        dateTime: DateTime(now.year, 10, 15, 10, 0),
        type: ReminderType.prepNotification,
        isEnabled: true,
        isSoundEnabled: false,
        applicationId: 'sample-event-google',
      ),
      Reminder(
        id: 'rem-4',
        title: 'Daily Data Structures & System Design Sprint',
        company: 'LeetCode',
        dateTime: DateTime(now.year, now.month, now.day, 20, 0),
        type: ReminderType.custom,
        isEnabled: true,
        isSoundEnabled: true,
      ),
    ];
  }

  Future<void> _save() async {
    final list = _reminders.map((r) => r.toJson()).toList();
    await _prefs.setString(_storageKey, jsonEncode(list));
  }

  Future<void> addReminder(Reminder reminder) async {
    _reminders.add(reminder);
    _reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    _schedule(reminder);
    notifyListeners();
    await _save();
  }

  Future<void> updateReminder(Reminder updated) async {
    final index = _reminders.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _reminders[index] = updated;
      _reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      if (updated.isEnabled) {
        _schedule(updated);
      } else {
        await _notificationService.cancelNotification(_notificationId(updated.id));
      }
      notifyListeners();
      await _save();
    }
  }

  Future<void> toggleReminder(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final current = _reminders[index];
      final toggled = current.copyWith(isEnabled: !current.isEnabled);
      _reminders[index] = toggled;
      if (toggled.isEnabled) {
        _schedule(toggled);
      } else {
        await _notificationService.cancelNotification(_notificationId(toggled.id));
      }
      notifyListeners();
      await _save();
    }
  }

  Future<void> deleteReminder(String id) async {
    await _notificationService.cancelNotification(_notificationId(id));
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
    await _save();
  }
}
