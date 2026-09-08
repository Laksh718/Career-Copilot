import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/theme.dart';
import 'home/home_screen.dart';
import 'onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 3200));
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
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing logo
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppTheme.primaryYellow.withValues(alpha: 0.3 + _glowController.value * 0.2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    size: 48,
                    color: AppTheme.primaryYellow,
                  ),
                );
              },
            )
                .animate()
                .scale(duration: 700.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 500.ms),
            const SizedBox(height: 36),
            // App name
            const Text(
              'Career Copilot',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryYellow,
                letterSpacing: -1.5,
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0, delay: 500.ms, duration: 600.ms),
            const SizedBox(height: 12),
            Text(
              'Your AI-Powered Career Assistant',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).textTheme.bodySmall?.color,
                letterSpacing: 0.5,
              ),
            )
                .animate()
                .fadeIn(delay: 900.ms, duration: 600.ms),
            const SizedBox(height: 48),
            // Loading indicator
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  AppTheme.primaryYellow.withValues(alpha: 0.5),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 1200.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
