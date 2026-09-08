import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'app/app.dart';
import 'repositories/application_repository.dart';
import 'services/gemini_career_ai_service.dart';
import 'services/notification_service.dart';
import 'controllers/application_controller.dart';
import 'controllers/ai_controller.dart';
import 'controllers/theme_controller.dart';

import 'controllers/reminder_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  final appRepository = ApplicationRepository(prefs);
  final aiService = GeminiCareerAIService(prefs: prefs);

  await NotificationService().init();

  String? initialSharedText;
  if (!kIsWeb) {
    try {
      final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
      for (final file in initialMedia) {
        if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
          initialSharedText = file.path;
          break;
        }
      }
    } catch (e) {
      debugPrint('Error retrieving initial media: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApplicationController(appRepository)),
        ChangeNotifierProvider(create: (_) => ReminderController(prefs)),
        ChangeNotifierProvider(create: (_) => AIController(aiService)),
        ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
      ],
      child: CareerCopilotApp(initialSharedText: initialSharedText),
    ),
  );
}
