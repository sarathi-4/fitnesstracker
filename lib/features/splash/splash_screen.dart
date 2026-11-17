import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/navigation/main_navigation_screen.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';
import '../auth/email_verification_screen.dart';
import '../onboarding/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Check Firebase authentication state & navigate
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Wait for splash animation minimum time
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    await AuthService.instance.ensureInitialized();
    final user = AuthService.instance.currentUser;
    final isSessionActive = UserService.instance.isLoggedIn;

    Widget nextScreen;
    if (isSessionActive || (user != null && user.emailVerified)) {
      // User has already signed up or logged in -> open app directly!
      nextScreen = const MainNavigationScreen();
    } else if (user != null && !user.emailVerified) {
      nextScreen = EmailVerificationScreen(
        email: user.email,
        justRegistered: false,
      );
    } else {
      nextScreen = const WelcomeScreen();
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      AppRouteTransitions.scaleFade(nextScreen),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // BIG OFFICIAL JAIHIND RUNNERS CLUB LOGO
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.16),
                        blurRadius: 36,
                        spreadRadius: 4,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/jaihind_logo_circle.png',
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // BRAND TYPOGRAPHY: JAI (Blue) HIND (Green)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  );
                },
                child: Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 2.2,
                        ),
                        children: [
                          TextSpan(
                            text: 'JAI',
                            style: TextStyle(color: AppColors.primaryBlue),
                          ),
                          TextSpan(
                            text: 'HIND',
                            style: TextStyle(color: AppColors.accentGreen),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'RUNNERS CLUB',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.5,
                        color: Color(0xFF061A33),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: 50,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // BOTTOM TAGLINE: TRACK • TRAIN • ACHIEVE
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    'TRACK  •  TRAIN  •  ACHIEVE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
