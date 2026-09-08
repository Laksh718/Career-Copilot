import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:career_copilot/controllers/application_controller.dart';
import 'package:career_copilot/controllers/ai_controller.dart';
import 'package:career_copilot/controllers/theme_controller.dart';
import 'package:career_copilot/controllers/reminder_controller.dart';
import 'package:career_copilot/repositories/application_repository.dart';
import 'package:career_copilot/services/mock_career_ai_service.dart';
import 'package:career_copilot/screens/chat/chat_screen.dart';
import 'package:career_copilot/screens/calendar/calendar_screen.dart';
import 'package:career_copilot/widgets/company_logo.dart';
import 'package:career_copilot/widgets/bottom_navigation.dart';

void main() {
  setUp(() {
    CompanyLogoWidget.debugDisableNetwork = true;
    BottomNavigation.disableAnimationsForTest = true;
  });

  tearDown(() {
    CompanyLogoWidget.debugDisableNetwork = false;
    BottomNavigation.disableAnimationsForTest = false;
  });

  testWidgets('ChatScreen renders structured welcome message', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = ApplicationRepository(prefs);
    final mockAi = MockCareerAIService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ApplicationController(repo)),
          ChangeNotifierProvider(create: (_) => ReminderController(prefs)),
          ChangeNotifierProvider(create: (_) => AIController(mockAi)),
          ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
        ],
        child: const MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Career Copilot'), findsOneWidget);
    expect(find.text('Copilot Coach'), findsOneWidget);
    expect(find.text('Tips & Guides'), findsOneWidget);
  });

  testWidgets('CalendarScreen builds with unified theme and header', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = ApplicationRepository(prefs);
    final mockAi = MockCareerAIService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ApplicationController(repo)),
          ChangeNotifierProvider(create: (_) => ReminderController(prefs)),
          ChangeNotifierProvider(create: (_) => AIController(mockAi)),
          ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
        ],
        child: const MaterialApp(
          home: CalendarScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Events'), findsAtLeastNWidgets(1));
    expect(find.text('Month View'), findsOneWidget);
    expect(find.text('2-Week View'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('ChatScreen parses and renders structured AI cards', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = ApplicationRepository(prefs);
    final mockAi = MockCareerAIService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ApplicationController(repo)),
          ChangeNotifierProvider(create: (_) => ReminderController(prefs)),
          ChangeNotifierProvider(create: (_) => AIController(mockAi)),
          ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
        ],
        child: const MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 350));

    // Tap suggestion chip: "Upcoming Interviews"
    await tester.tap(find.text('Upcoming Interviews'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 350));

    // Verify structured executive cards are rendered
    expect(find.text('EXECUTIVE SUMMARY', skipOffstage: false), findsOneWidget);
    expect(find.text('HIGHLIGHTS', skipOffstage: false), findsOneWidget);
    expect(find.text('ACTION PLAN', skipOffstage: false), findsOneWidget);
    expect(find.text('PRO TIP', skipOffstage: false), findsOneWidget);
  });

  testWidgets('ChatScreen renders Template Card with Copy button for email drafts', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = ApplicationRepository(prefs);
    final mockAi = MockCareerAIService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ApplicationController(repo)),
          ChangeNotifierProvider(create: (_) => ReminderController(prefs)),
          ChangeNotifierProvider(create: (_) => AIController(mockAi)),
          ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
        ],
        child: const MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 350));

    // Tap suggestion chip: "Draft Follow-up"
    await tester.tap(find.text('Draft Follow-up'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 350));

    // Verify Template card and Copy Template button
    expect(find.text('TEMPLATE', skipOffstage: false), findsOneWidget);
    expect(find.text('Copy Template', skipOffstage: false), findsOneWidget);
  });
}
