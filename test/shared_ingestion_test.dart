import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:career_copilot/controllers/application_controller.dart';
import 'package:career_copilot/controllers/reminder_controller.dart';
import 'package:career_copilot/controllers/ai_controller.dart';
import 'package:career_copilot/repositories/application_repository.dart';
import 'package:career_copilot/services/mock_career_ai_service.dart';
import 'package:career_copilot/services/notification_service.dart';
import 'package:career_copilot/services/shared_ingestion_service.dart';
import 'package:career_copilot/screens/application_details/application_details_screen.dart';
import 'package:career_copilot/screens/splash_screen.dart';
import 'package:career_copilot/widgets/company_logo.dart';
import 'package:career_copilot/widgets/bottom_navigation.dart';

void main() {
  setUp(() {
    CompanyLogoWidget.debugDisableNetwork = true;
    BottomNavigation.disableAnimationsForTest = true;
    NotificationService.debugDisableForTest = true;
    SplashScreen.cancelNavigation = false;
  });

  tearDown(() {
    CompanyLogoWidget.debugDisableNetwork = false;
    BottomNavigation.disableAnimationsForTest = false;
    NotificationService.debugDisableForTest = false;
    SplashScreen.cancelNavigation = false;
  });

  testWidgets('SharedIngestionService auto-adds application and directly opens ApplicationDetailsScreen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = ApplicationRepository(prefs);
    final appCtrl = ApplicationController(repo);
    final reminderCtrl = ReminderController(prefs);
    final mockAi = MockCareerAIService();
    final aiCtrl = AIController(mockAi);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appCtrl),
          ChangeNotifierProvider.value(value: reminderCtrl),
          ChangeNotifierProvider.value(value: aiCtrl),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await SharedIngestionService().processAndAutoAdd(
                      context,
                      'Google Interview scheduled tomorrow at 2 PM. Stipend: \$9500.',
                      sourceName: 'Shared Test Email',
                    );
                  },
                  child: const Text('Trigger Auto Add'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();

    // Tap button to simulate shared message arrival
    await tester.tap(find.text('Trigger Auto Add'));
    await tester.pump(); // starts ingestion dialog
    await tester.pump(const Duration(seconds: 3)); // completes analysis & opens details screen directly
    await tester.pumpAndSettle();

    // Verify application was automatically added to controller
    expect(appCtrl.applications.any((a) => a.company == 'Google'), isTrue);

    // Verify splash navigation was canceled
    expect(SplashScreen.cancelNavigation, isTrue);

    // Verify ApplicationDetailsScreen is directly opened without intermediate modal
    expect(find.byType(ApplicationDetailsScreen), findsOneWidget);
    expect(find.text('Google'), findsWidgets);
    expect(find.textContaining('Auto-ingested Google'), findsWidgets);
  });
}
