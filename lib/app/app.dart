import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import '../screens/splash_screen.dart';
import '../services/shared_ingestion_service.dart';
import '../controllers/theme_controller.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class CareerCopilotApp extends StatefulWidget {
  const CareerCopilotApp({super.key});

  @override
  State<CareerCopilotApp> createState() => _CareerCopilotAppState();
}

class _CareerCopilotAppState extends State<CareerCopilotApp> {
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _setupIntentListener();
    }
  }

  void _setupIntentListener() {
    try {
      // For sharing or opening urls/text coming from outside the app while the app is in the memory
      _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
        if (value.isNotEmpty) {
          for (var file in value) {
            if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
               _handleSharedText(file.path);
               break;
            }
          }
        }
      }, onError: (err) {
        debugPrint("getIntentDataStream error: $err");
      });

      // For sharing or opening urls/text coming from outside the app while the app is closed
      ReceiveSharingIntent.instance.getInitialMedia().then((value) {
        if (value.isNotEmpty) {
          for (var file in value) {
            if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
               _handleSharedText(file.path);
               break;
            }
          }
        }
      });
    } catch (e) {
      debugPrint("ReceiveSharingIntent init error: $e");
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleSharedText(String text) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    try {
      await SharedIngestionService().processAndAutoAdd(
        context,
        text,
        sourceName: 'Shared Mail / WhatsApp',
      );
      ReceiveSharingIntent.instance.reset();
    } catch (e) {
      debugPrint('Error handling shared intent: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Career Copilot',
          debugShowCheckedModeBanner: false,
          themeMode: themeController.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}
