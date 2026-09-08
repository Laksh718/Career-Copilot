import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:career_copilot/controllers/application_controller.dart';
import 'package:career_copilot/controllers/theme_controller.dart';
import 'package:career_copilot/controllers/ai_controller.dart';
import 'package:career_copilot/services/mock_career_ai_service.dart';
import 'package:career_copilot/repositories/application_repository.dart';
import 'package:career_copilot/screens/profile/profile_screen.dart';

void main() {
  testWidgets('ProfileScreen renders with CustomScrollView slivers without crash',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = ApplicationRepository(prefs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ApplicationController(repo)),
          ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
          ChangeNotifierProvider(create: (_) => AIController(MockCareerAIService())),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.text('Laksh'), findsOneWidget);
    expect(find.text('AI Copilot Pro'), findsOneWidget);
  });
}
