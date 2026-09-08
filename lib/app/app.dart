import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import '../screens/home/home_screen.dart';
import '../screens/splash_screen.dart';
import '../services/shared_ingestion_service.dart';
import '../controllers/theme_controller.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class CareerCopilotApp extends StatefulWidget {
  final String? initialSharedText;

  const CareerCopilotApp({super.key, this.initialSharedText});

  @override
  State<CareerCopilotApp> createState() => _CareerCopilotAppState();
}

class _CareerCopilotAppState extends State<CareerCopilotApp> {
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.initialSharedText != null && widget.initialSharedText!.trim().isNotEmpty) {
      SplashScreen.cancelNavigation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSharedText(widget.initialSharedText!, fromColdStart: true);
      });
    }

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
              _handleSharedText(file.path, fromColdStart: false);
              break;
            }
          }
        }
      }, onError: (err) {
        debugPrint("getIntentDataStream error: $err");
      });

      // Cold-start fallback if not passed directly to main
      if (widget.initialSharedText == null) {
        ReceiveSharingIntent.instance.getInitialMedia().then((value) {
          if (value.isNotEmpty) {
            for (var file in value) {
              if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
                _handleSharedText(file.path, fromColdStart: true);
                break;
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint("ReceiveSharingIntent init error: $e");
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleSharedText(String text, {bool fromColdStart = false}) async {
    SplashScreen.cancelNavigation = true;
    final nav = navigatorKey.currentState;
    final context = navigatorKey.currentContext;
    if (context == null) return;

    try {
      if (fromColdStart) {
        // Ensure HomeScreen is root if launched via share intent (so back button lands on Home)
        nav?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
      final activeContext = navigatorKey.currentContext ?? context;
      await SharedIngestionService().processAndAutoAdd(
        activeContext,
        text,
        sourceName: 'Shared Message',
        replaceRoute: false,
      );
      if (!kIsWeb) {
        ReceiveSharingIntent.instance.reset();
      }
    } catch (e) {
      debugPrint('Error handling shared intent: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasInitialShare = widget.initialSharedText != null && widget.initialSharedText!.trim().isNotEmpty;

    return Consumer<ThemeController>(
      builder: (context, themeController, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Career Copilot',
          debugShowCheckedModeBanner: false,
          themeMode: themeController.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: hasInitialShare ? const HomeScreen() : const SplashScreen(),
        );
      },
    );
  }
}
