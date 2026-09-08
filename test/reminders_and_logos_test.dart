import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:career_copilot/models/reminder.dart';
import 'package:career_copilot/models/application.dart';
import 'package:career_copilot/controllers/reminder_controller.dart';
import 'package:career_copilot/controllers/application_controller.dart';
import 'package:career_copilot/controllers/theme_controller.dart';
import 'package:career_copilot/repositories/application_repository.dart';
import 'package:career_copilot/widgets/company_logo.dart';
import 'package:career_copilot/widgets/bottom_navigation.dart';
import 'package:career_copilot/screens/reminders/reminders_screen.dart';
import 'package:career_copilot/services/notification_service.dart';

void main() {
  setUp(() {
    CompanyLogoWidget.debugDisableNetwork = true;
    BottomNavigation.disableAnimationsForTest = true;
    NotificationService.debugDisableForTest = true;
  });

  tearDown(() {
    CompanyLogoWidget.debugDisableNetwork = false;
    BottomNavigation.disableAnimationsForTest = false;
    NotificationService.debugDisableForTest = false;
  });

  group('CompanyLogoWidget Tests', () {
    testWidgets('Renders CompanyLogoWidget with monogram fallback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompanyLogoWidget(
              company: 'Amazon',
              category: OpportunityCategory.job,
              size: 48,
              showCategoryBadge: true,
            ),
          ),
        ),
      );

      // Monogram for Amazon is "AM"
      expect(find.text('AM'), findsWidgets);
    });

    testWidgets('Renders monogram correctly for multi-word companies', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompanyLogoWidget(
              company: 'Google Cloud Summit',
              category: OpportunityCategory.event,
              size: 48,
            ),
          ),
        ),
      );

      // Monogram for Google Cloud Summit is "GC"
      expect(find.text('GC'), findsWidgets);
    });
  });

  group('Reminder Model & ReminderController Tests', () {
    test('Reminder serialization and copyWith work as expected', () {
      final now = DateTime.now();
      final reminder = Reminder(
        id: 'test-1',
        title: 'Google Final Round',
        company: 'Google',
        dateTime: now,
        type: ReminderType.interviewAlarm,
        isEnabled: true,
        isSoundEnabled: true,
      );

      final json = reminder.toJson();
      expect(json['id'], 'test-1');
      expect(json['title'], 'Google Final Round');
      expect(json['type'], 'interviewAlarm');

      final reconstructed = Reminder.fromJson(json);
      expect(reconstructed.id, 'test-1');
      expect(reconstructed.title, 'Google Final Round');
      expect(reconstructed.type, ReminderType.interviewAlarm);
      expect(reconstructed.isEnabled, true);

      final updated = reconstructed.copyWith(isEnabled: false);
      expect(updated.isEnabled, false);
      expect(updated.title, 'Google Final Round');
    });

    test('ReminderController seeds, adds, toggles, updates, and deletes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = ReminderController(prefs);

      // Should have 4 initial seeded reminders
      expect(controller.reminders.length, 4);
      expect(controller.activeReminders.length, 4);

      final firstId = controller.reminders.first.id;

      // Toggle first
      await controller.toggleReminder(firstId);
      expect(controller.reminders.firstWhere((r) => r.id == firstId).isEnabled, false);
      expect(controller.activeReminders.length, 3);

      // Add a new reminder
      final newRem = Reminder(
        id: 'new-100',
        title: 'Mock Interview Prep',
        company: 'Microsoft',
        dateTime: DateTime.now().add(const Duration(hours: 5)),
        type: ReminderType.prepNotification,
      );
      await controller.addReminder(newRem);
      expect(controller.reminders.length, 5);

      // Update reminder
      final updated = newRem.copyWith(title: 'Updated Interview Prep');
      await controller.updateReminder(updated);
      expect(
        controller.reminders.firstWhere((r) => r.id == 'new-100').title,
        'Updated Interview Prep',
      );

      // Delete reminder
      await controller.deleteReminder('new-100');
      expect(controller.reminders.length, 4);
      expect(controller.reminders.any((r) => r.id == 'new-100'), false);
    });
  });

  group('BottomNavigation 7-Slot Layout Tests', () {
    testWidgets('BottomNavigation renders all 7 items without overflow', (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNavigation(
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Apps'), findsOneWidget);
      expect(find.text('Alarms'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Center Add button is present
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Tap on Alarms (tab 2)
      await tester.tap(find.text('Alarms'));
      expect(tappedIndex, 2);

      // Tap on Profile (tab 6)
      await tester.tap(find.text('Profile'));
      expect(tappedIndex, 6);

      // Tap on Add (+) (tab 3)
      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(tappedIndex, 3);
    });
  });

  group('RemindersScreen Widget Tests', () {
    testWidgets('RemindersScreen renders alarms and toggle switches', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = ApplicationRepository(prefs);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ApplicationController(repo)),
            ChangeNotifierProvider(create: (_) => ReminderController(prefs)),
            ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
          ],
          child: const MaterialApp(
            home: RemindersScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Reminders & Alarms'), findsOneWidget);
      expect(find.text('Set Alarm'), findsWidgets);
      expect(find.byType(Switch), findsWidgets);

      // Filter chips
      expect(find.text('All (4)'), findsOneWidget);
      expect(find.text('Alarms'), findsWidgets);
      expect(find.text('Deadlines'), findsWidgets);
    });
  });
}
