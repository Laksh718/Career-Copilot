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

    test('GeminiCareerAIService handles dynamic custom key, clearing, and persistence', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final gemini = GeminiCareerAIService(prefs: prefs);

      // Without environment flag or hardcoded secrets, starts offline by default
      expect(gemini.isConfigured, false);
      expect(gemini.apiKey, '');

      // User configures API key dynamically
      await gemini.setApiKey('AIzaSyTestKey123');
      expect(gemini.isConfigured, true);
      expect(gemini.apiKey, 'AIzaSyTestKey123');
      expect(gemini.isDefaultKey, false);

      // Explicitly clearing key reverts to offline
      await gemini.clearApiKey();
      expect(gemini.isConfigured, false);
      expect(gemini.apiKey, '');
      expect(gemini.isDefaultKey, false);

      // Re-instantiating with same prefs respects explicit user clear
      final reloadedGemini = GeminiCareerAIService(prefs: prefs);
      expect(reloadedGemini.isConfigured, false);
      expect(reloadedGemini.apiKey, '');
    });

    test('GeminiCareerAIService supports platform default key with override, restore, and clear', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final gemini = GeminiCareerAIService(
        prefs: prefs,
        platformDefaultKey: 'PlatformDefaultKeyTest456',
      );

      // Initializes with platform default key out of the box
      expect(gemini.isConfigured, true);
      expect(gemini.apiKey, 'PlatformDefaultKeyTest456');
      expect(gemini.hasEnvironmentKey, true);
      expect(gemini.isDefaultKey, true);

      // User overrides with custom key
      await gemini.setApiKey('CustomUserKey789');
      expect(gemini.apiKey, 'CustomUserKey789');
      expect(gemini.isDefaultKey, false);

      // User restores default key
      await gemini.restoreDefaultKey();
      expect(gemini.apiKey, 'PlatformDefaultKeyTest456');
      expect(gemini.isDefaultKey, true);

      // User clears key
      await gemini.clearApiKey();
      expect(gemini.isConfigured, false);
      expect(gemini.apiKey, '');
    });
  });

  group('ChatScreen Narrow Layout & Header Status', () {
    testWidgets('ChatScreen header fits without overflow and reflects key state', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final appRepo = ApplicationRepository(prefs);
      final gemini = GeminiCareerAIService(prefs: prefs);

      // Render under compact width (e.g. mobile 360 width or 184 constraint)
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final aiController = AIController(gemini);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ApplicationController(appRepo)),
            ChangeNotifierProvider.value(value: aiController),
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
      // Starts in offline AI mode
      expect(find.textContaining('Offline AI'), findsWidgets);

      // When user configures key, updates to Gemini Active
      await aiController.updateApiKey('AIzaSyTestKey123');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Gemini 2.5 Active'), findsWidgets);

      // When key is cleared, badge reverts to Offline AI
      await aiController.clearApiKey();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Offline AI'), findsWidgets);
    });
  });
}
