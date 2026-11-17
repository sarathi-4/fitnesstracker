import 'package:flutter/material.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),

                        // A & B: Top JAIHIND Branding (Official Runners Club Circular Logo)
                        FadeSlideEntry(
                          index: 0,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.16),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/jaihind_logo_circle.png',
                              width: 150,
                              height: 150,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // C: Main Illustration (Running Athletes + Motion Swooshes)
                        Image.asset(
                          'assets/images/running_athletes.png',
                          width: double.infinity,
                          height: 215,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(height: 16),

                        // D: App Identity (Inpand Tech Dual Color Branding)
                        FadeSlideEntry(
                          index: 0,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 2.0,
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
                        ),
                        const SizedBox(height: 6),
                        const FadeSlideEntry(
                          index: 1,
                          child: Text(
                            'TRACK. TRAIN. ACHIEVE.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.6,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Tech Blue-Green accent line below tagline
                        Container(
                          width: 72,
                          height: 3.5,
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // E: Onboarding Indicators (1 Blue, 2 Grey)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8.5,
                              height: 8.5,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8.5,
                              height: 8.5,
                              decoration: const BoxDecoration(
                                color: AppColors.dotInactive,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8.5,
                              height: 8.5,
                              decoration: const BoxDecoration(
                                color: AppColors.dotInactive,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(flex: 2),

                        // F: Create Account Button (Navigates to Register Screen with Transition)
                        FadeSlideEntry(
                          index: 2,
                          child: _buildPrimaryButton(
                            title: 'CREATE AN ACCOUNT',
                            onPressed: () {
                              Navigator.push(
                                context,
                                AppRouteTransitions.slideHorizontal(const RegisterScreen()),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // G: Login Button (Navigates to Login Screen with Transition)
                        FadeSlideEntry(
                          index: 3,
                          child: _buildSecondaryButton(
                            title: 'LOGIN',
                            onPressed: () {
                              Navigator.push(
                                context,
                                AppRouteTransitions.slideHorizontal(const LoginScreen()),
                              );
                            },
                          ),
                        ),

                        const Spacer(flex: 1),

                        // H: Location Section
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
                          child: _buildLocationFooter(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // F. Create Account Button Component (With Tactile BouncingTap)
  Widget _buildPrimaryButton({
    required String title,
    required VoidCallback onPressed,
  }) {
    return BouncingTap(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const Positioned(
              right: 20,
              child: Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // G. Login Button Component (With Tactile BouncingTap & Tech Blue Border)
  Widget _buildSecondaryButton({
    required String title,
    required VoidCallback onPressed,
  }) {
    return BouncingTap(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.primaryBlue,
            width: 1.8,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  // H. Location Footer Component
  Widget _buildLocationFooter() {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
          letterSpacing: 0.5,
        ),
        children: [
          TextSpan(text: 'YOUR LOCATION IS INDIA 🇮🇳 • YOU CAN '),
          TextSpan(
            text: 'CHANGE IT HERE.',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryOrange,
              decoration: TextDecoration.underline,
              decorationThickness: 1.5,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
