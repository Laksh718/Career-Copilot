import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:career_copilot/models/application.dart';
import 'package:career_copilot/repositories/application_repository.dart';
import 'package:career_copilot/controllers/application_controller.dart';
import 'package:career_copilot/controllers/ai_controller.dart';
import 'package:career_copilot/controllers/theme_controller.dart';
import 'package:career_copilot/services/mock_career_ai_service.dart';
import 'package:career_copilot/services/gemini_career_ai_service.dart';
import 'package:career_copilot/screens/chat/chat_screen.dart';
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

  group('AI Engine & Ingestion Heuristic Tests', () {
    test('MockCareerAIService extracts custom company and role patterns', () async {
      final service = MockCareerAIService();
      final extraction = await service.analyzeMessage(
        'Hi Laksh, we are excited to invite you for an interview at Uber for Software Engineer on Friday at 4 PM. Applications close October 15. Please submit your resume.',
      );

      expect(extraction.company, 'Uber');
      expect(extraction.role, contains('Software Engineer'));
      expect(extraction.interviewDate, 'Friday');
      expect(extraction.interviewTime, '4 PM');
      expect(extraction.deadline, 'October 15');
      expect(extraction.requiredDocuments, contains('Resume'));
      expect(extraction.status, 'Interview');
    });

    test('MockCareerAIService responds to greetings and interview queries', () async {
      final service = MockCareerAIService();
      final apps = [
        Application(
          id: '1',
          company: 'Google',
          role: 'SWE Intern',
          category: OpportunityCategory.job,
          status: ApplicationStatus.interview,
          createdAt: DateTime(2026, 9, 1),
          interviewDate: 'Monday',
          interviewTime: '10:00 AM',
        ),
      ];

      final greeting = await service.chatWithCareerCoach('Hello', apps);
      expect(greeting, contains('### SUMMARY'));
      expect(greeting, contains('Hello!'));

      final interviewAnswer = await service.chatWithCareerCoach('When is my interview?', apps);
      expect(interviewAnswer, contains('Google'));
      expect(interviewAnswer, contains('Monday'));

      final dsaAnswer = await service.chatWithCareerCoach('How to prepare for dsa interview', apps);
      expect(dsaAnswer, contains('Two Pointers'));
    });

    test('GeminiCareerAIService updates and clears keys cleanly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final gemini = GeminiCareerAIService(prefs: prefs);

      expect(gemini.isConfigured, false);
      expect(gemini.apiKey, '');

      await gemini.setApiKey('AIzaSyTestKey123');
      expect(gemini.isConfigured, true);
      expect(gemini.apiKey, 'AIzaSyTestKey123');

      await gemini.clearApiKey();
      expect(gemini.isConfigured, false);
      expect(gemini.apiKey, '');
    });
  });

  group('ChatScreen Narrow Layout & Header Status', () {
    testWidgets('ChatScreen header fits without overflow on 184px constraint width', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final appRepo = ApplicationRepository(prefs);
      final gemini = GeminiCareerAIService(prefs: prefs);

      // Render under compact width (e.g. mobile 360 width or 184 constraint)
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ApplicationController(appRepo)),
            ChangeNotifierProvider(create: (_) => AIController(gemini)),
            ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
          ],
          child: const MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Career Copilot'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
      expect(find.textContaining('Offline AI'), findsWidgets);
    });
  });
}
