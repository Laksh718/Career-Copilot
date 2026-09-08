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

// Holds intents that arrive before the navigator/home is ready (during splash)
final List<String> _pendingIntents = [];
bool _navigatorReady = false;

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
      // Stream: app already running in background — safe to handle immediately
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

      // Cold-start: app launched via share intent — queue until navigator is ready
      ReceiveSharingIntent.instance.getInitialMedia().then((value) {
        if (value.isNotEmpty) {
          for (var file in value) {
            if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
              if (_navigatorReady) {
                _handleSharedText(file.path);
              } else {
                _pendingIntents.add(file.path);
              }
              break;
            }
          }
        }
      });

      // Flush pending intents after splash finishes (1600ms — slightly after 1400ms splash)
      Future.delayed(const Duration(milliseconds: 1650), () {
        _navigatorReady = true;
        for (final text in _pendingIntents) {
          _handleSharedText(text);
        }
        _pendingIntents.clear();
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
