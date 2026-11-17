import 'package:flutter/material.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/navigation/main_navigation_screen.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/jaihind_brand_logo.dart';
import 'email_verification_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  // Granular error state for prompt cases
  String? _errorMessage;
  bool _isUnregistered = false;
  bool _isUnverified = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    // Prevent duplicate submissions
    if (_isLoading) return;

    setState(() {
      _errorMessage = null;
      _isUnregistered = false;
      _isUnverified = false;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final result = await AuthService.instance.login(
      email: email,
      password: password,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      // Case 1: Registered user + correct password + verified email
      Navigator.pushAndRemoveUntil(
        context,
        AppRouteTransitions.scaleFade(const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? 'Login failed. Please try again.';
        _isUnregistered = result.isUnregistered;
        _isUnverified = result.isUnverified;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: FadeSlideEntry(
              delay: Duration.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  BouncingTap(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textBlack,
                        size: 22,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Center JAIHIND Logo (Official Club Emblem)
                  const Center(
                    child: JaihindBrandLogo(
                      fontSize: 26,
                      emblemHeight: 38,
                      showSubtitle: true,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Title & Subtitle
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to continue your training & track progress.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // PROMPT CASE ERROR CARD
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _isUnverified
                            ? const Color(0xFFFFFBEB) // Warning yellow/amber
                            : const Color(0xFFFEF2F2), // Red error
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isUnverified
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFFFCA5A5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _isUnverified
                                    ? Icons.mark_email_unread_rounded
                                    : Icons.error_outline_rounded,
                                color: _isUnverified ? const Color(0xFFD97706) : Colors.redAccent,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: _isUnverified
                                        ? const Color(0xFF92400E)
                                        : const Color(0xFF991B1B),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Case 2: Unregistered user action
                          if (_isUnregistered) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    AppRouteTransitions.slideHorizontal(const RegisterScreen()),
                                  );
                                },
                                icon: const Icon(Icons.person_add_rounded, size: 16),
                                label: const Text(
                                  'Sign Up Now',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primaryBlue,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                              ),
                            ),
                          ],

                          // Case 4: Unverified email action
                          if (_isUnverified) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      AppRouteTransitions.slideHorizontal(
                                        EmailVerificationScreen(
                                          email: _emailController.text.trim(),
                                          justRegistered: false,
                                        ),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFB45309),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  child: const Text(
                                    'Verify Email Now',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 1. EMAIL FIELD
                  _buildFieldLabel('Email Address'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                    style: const TextStyle(fontSize: 14),
                    decoration: _buildInputDecoration(
                      hint: 'Enter your email address',
                      prefixIcon: Icons.email_outlined,
                    ),
                    validator: AppValidators.validateEmail,
                  ),

                  const SizedBox(height: 18),

                  // 2. PASSWORD FIELD
                  _buildFieldLabel('Password'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    enabled: !_isLoading,
                    style: const TextStyle(fontSize: 14),
                    decoration: _buildInputDecoration(
                      hint: 'Enter your password',
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textGrey,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // 3. REMEMBER ME & 4. FORGOT PASSWORD
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: AppColors.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: _isLoading
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _rememberMe = val ?? true;
                                      });
                                    },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Remember me',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      BouncingTap(
                        onTap: () {
                          Navigator.push(
                            context,
                            AppRouteTransitions.slideHorizontal(
                              ForgotPasswordScreen(
                                initialEmail: _emailController.text.trim(),
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // 5. LOGIN BUTTON
                  BouncingTap(
                    onTap: _isLoading ? null : _submitLogin,
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
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'LOGIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 6. DON'T HAVE AN ACCOUNT? SIGN UP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                      BouncingTap(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            AppRouteTransitions.slideHorizontal(const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textBlack,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: AppColors.primaryBlue, size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
      ),
    );
  }
}
