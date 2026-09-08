import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home/home_screen.dart';
import 'onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    final destination = seenOnboarding ? const HomeScreen() : const OnboardingScreen();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sleek luxury dark canvas for the white-based logo
      backgroundColor: const Color(0xFF080B11),
      body: Stack(
        children: [
          // Ambient warm golden radial glow centered behind logo
          Center(
            child: Container(
              width: 440,
              height: 440,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x28FF8A00),
                    Color(0x12FF5252),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 800.ms),

          // Main Logo centered & enlarged
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/app_logo.png',
                  width: 320,
                  height: 220,
                  fit: BoxFit.contain,
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.82, 0.82),
                      end: const Offset(1.0, 1.0),
                      duration: 650.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 450.ms),
              ],
            ),
          ),

          // Bottom brand mark
          Positioned(
            bottom: 44,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8A00).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'AI-POWERED CAREER INTELLIGENCE',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0x88FFFFFF),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.8,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
          ),
        ],
      ),
    );
  }
}
