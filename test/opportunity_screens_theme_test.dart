import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:career_copilot/controllers/application_controller.dart';
import 'package:career_copilot/controllers/ai_controller.dart';
import 'package:career_copilot/controllers/reminder_controller.dart';
import 'package:career_copilot/models/application.dart';
import 'package:career_copilot/services/mock_career_ai_service.dart';
import 'package:career_copilot/screens/add_opportunity/add_opportunity_screen.dart';
import 'package:career_copilot/screens/application_details/application_details_screen.dart';

import 'package:career_copilot/repositories/application_repository.dart';
import 'package:career_copilot/widgets/company_logo.dart';
import 'package:career_copilot/widgets/bottom_navigation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApplicationController applicationController;
  late AIController aiController;
  late ReminderController reminderController;

  setUp(() async {
    CompanyLogoWidget.debugDisableNetwork = true;
    BottomNavigation.disableAnimationsForTest = true;

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = ApplicationRepository(prefs);
    applicationController = ApplicationController(repo);
    aiController = AIController(MockCareerAIService());
    reminderController = ReminderController(prefs);
  });

  tearDown(() {
    CompanyLogoWidget.debugDisableNetwork = false;
    BottomNavigation.disableAnimationsForTest = false;
  });

  Widget buildTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ApplicationController>.value(value: applicationController),
        ChangeNotifierProvider<AIController>.value(value: aiController),
        ChangeNotifierProvider<ReminderController>.value(value: reminderController),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('AddOpportunityScreen Tests', () {
    testWidgets('renders header, segmented switcher, and AI Ingest by default', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(const AddOpportunityScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Add Opportunity'), findsOneWidget);
      expect(find.text('AI Smart Ingest'), findsOneWidget);
      expect(find.text('Manual Form'), findsOneWidget);
      expect(find.text('Auto-Add to Pipeline'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Paste Clipboard'), findsOneWidget);
    });

    testWidgets('switches to Manual Form and exposes category chips & form inputs', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(const AddOpportunityScreen()));
      await tester.pumpAndSettle();

      // Tap on 'Manual Form' tab
      await tester.tap(find.text('Manual Form'));
      await tester.pumpAndSettle();

      expect(find.text('Opportunity Category'), findsOneWidget);
      expect(find.text('Job / Internship'), findsOneWidget);
      expect(find.text('Hackathon'), findsOneWidget);
      expect(find.text('Coding Contest'), findsOneWidget);
      expect(find.text('Tech Event / Workshop'), findsOneWidget);
      expect(find.text('Save Opportunity to Pipeline'), findsOneWidget);
    });
  });

  group('ApplicationDetailsScreen Tests', () {
    final sampleApp = Application(
      id: 'test-app-1',
      company: 'Microsoft',
      role: 'Software Engineer Intern',
      category: OpportunityCategory.job,
      status: ApplicationStatus.applied,
      createdAt: DateTime.now(),
      location: 'Redmond, WA',
      workMode: 'Hybrid',
      stipend: '\$8,500/mo',
      interviewDate: 'Oct 15, 2026',
      interviewTime: '2:00 PM',
    );

    testWidgets('renders hero header, badges, connected stepper, and AI tools', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(ApplicationDetailsScreen(application: sampleApp)));
      await tester.pumpAndSettle();

      expect(find.text('Microsoft'), findsOneWidget);
      expect(find.text('Software Engineer Intern'), findsOneWidget);
      expect(find.text('JOB / INTERNSHIP'), findsOneWidget);
      expect(find.text('\$8,500/mo'), findsOneWidget);
      expect(find.text('Redmond, WA'), findsOneWidget);

      // Stepper stages
      expect(find.text('Applied'), findsNWidgets(2)); // Status chip + stepper label
      expect(find.text('Interview'), findsOneWidget);

      // AI Copilot
      expect(find.text('AI Copilot Tools'), findsOneWidget);
      expect(find.text('Interview Q&A'), findsOneWidget);
      expect(find.text('Follow-up Draft'), findsOneWidget);
    });

    testWidgets('tapping pipeline step updates application status', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      applicationController.addApplication(sampleApp);

      await tester.pumpWidget(buildTestWidget(ApplicationDetailsScreen(application: sampleApp)));
      await tester.pumpAndSettle();

      // Tap on 'Interview' in the stepper
      await tester.tap(find.text('Interview'));
      await tester.pumpAndSettle();

      final updated = applicationController.applications.firstWhere((a) => a.id == sampleApp.id);
      expect(updated.status, ApplicationStatus.interview);
    });
  });
}
