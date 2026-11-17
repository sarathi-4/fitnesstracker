import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/navigation/main_navigation_screen.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/jaihind_brand_logo.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? email;
  final bool justRegistered;

  const EmailVerificationScreen({
    super.key,
    this.email,
    this.justRegistered = false,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  Timer? _periodicCheckTimer;
  String? _statusMessage;
  bool _isSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    // Auto check periodically every 4 seconds in background
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkVerificationQuietly();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _periodicCheckTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldownSeconds = 0);
      } else {
        if (mounted) setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _checkVerificationQuietly() async {
    final verified = await AuthService.instance.isEmailVerified();
    if (verified && mounted) {
      _periodicCheckTimer?.cancel();
      Navigator.pushAndRemoveUntil(
        context,
        AppRouteTransitions.scaleFade(const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _checkVerificationManual() async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });

    final verified = await AuthService.instance.isEmailVerified();
    if (!mounted) return;

    if (verified) {
      _periodicCheckTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified successfully! Welcome to JAIHIND.'),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        AppRouteTransitions.scaleFade(const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _isChecking = false;
        _isSuccessMessage = false;
        _statusMessage =
            'Email is not verified yet. Please check your inbox and click the verification link.';
      });
    }
  }

  Future<void> _resendEmail() async {
    if (_isResending || _cooldownSeconds > 0) return;

    setState(() {
      _isResending = true;
      _statusMessage = null;
    });

    final result = await AuthService.instance.resendVerificationEmail();

    if (!mounted) return;

    setState(() {
      _isResending = false;
      if (result.success) {
        _isSuccessMessage = true;
        _statusMessage = 'Verification email resent! Please check your inbox & spam folder.';
        _startCooldown();
      } else {
        _isSuccessMessage = false;
        _statusMessage = result.errorMessage ?? 'Failed to resend verification email.';
      }
    });
  }

  Future<void> _handleBackToLogin() async {
    _periodicCheckTimer?.cancel();
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      AppRouteTransitions.slideHorizontal(const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayEmail = widget.email ?? AuthService.instance.currentUser?.email ?? 'your email';

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: FadeSlideEntry(
            delay: Duration.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                // Center JAIHIND Logo
                const Center(
                  child: JaihindBrandLogo(
                    fontSize: 26,
                    emblemHeight: 40,
                    showSubtitle: true,
                  ),
                ),

                const SizedBox(height: 36),

                // Email illustration icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_email_unread_rounded,
                      color: AppColors.primaryBlue,
                      size: 50,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Title
                const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: AppColors.textBlack,
                  ),
                ),

                const SizedBox(height: 10),

                // Description
                if (widget.justRegistered)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Account created successfully. Please verify your email.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentGreen,
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Please verify your email before logging in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'We sent a verification link to:\n$displayEmail',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Status message banner
                if (_statusMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isSuccessMessage ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isSuccessMessage ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSuccessMessage ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          color: _isSuccessMessage ? const Color(0xFF16A34A) : Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: _isSuccessMessage
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF991B1B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // CHECK VERIFICATION STATUS BUTTON
                BouncingTap(
                  onTap: _isChecking ? null : _checkVerificationManual,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isChecking
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'I HAVE VERIFIED MY EMAIL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // RESEND EMAIL BUTTON
                OutlinedButton(
                  onPressed: (_isResending || _cooldownSeconds > 0) ? null : _resendEmail,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isResending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                          ),
                        )
                      : Text(
                          _cooldownSeconds > 0
                              ? 'Resend Email ($_cooldownSeconds s)'
                              : 'Resend Verification Email',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),

                const SizedBox(height: 28),

                // BACK TO LOGIN LINK
                BouncingTap(
                  onTap: _handleBackToLogin,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.textGrey),
                        SizedBox(width: 6),
                        Text(
                          'Back to Login',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
