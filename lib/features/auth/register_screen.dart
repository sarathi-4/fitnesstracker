import 'package:flutter/material.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/navigation/main_navigation_screen.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/jaihind_brand_logo.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _serverErrorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    // Prevent duplicate submissions
    if (_isLoading) return;

    setState(() => _serverErrorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final fullName = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final result = await AuthService.instance.signUp(
      fullName: fullName,
      username: username,
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() => _isLoading = false);

      // Instantly update local profile state with entered username & name
      UserService.instance.updateProfile(
        name: fullName,
        email: email,
        password: '••••••••',
        username: username,
      );
      UserService.instance.updateInstagramProfile(
        displayName: fullName,
        username: username,
        bio: '',
        website: '',
      );

      if (result.isLocalFallback || result.user == null) {
        Navigator.pushAndRemoveUntil(
          context,
          AppRouteTransitions.scaleFade(const MainNavigationScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to JAIHIND, $fullName! 🎉 Account created.'),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Navigate to Email Verification Screen per specification:
      // "Display: 'Account created successfully. Please verify your email.'
      // Do not allow unverified users to enter the Home screen."
      Navigator.pushReplacement(
        context,
        AppRouteTransitions.slideHorizontal(
          EmailVerificationScreen(
            email: email,
            justRegistered: true,
          ),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _serverErrorMessage = result.errorMessage ?? 'Registration failed. Please try again.';
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

                  const SizedBox(height: 12),

                  // Center JAIHIND Logo (Official Club Emblem)
                  const Center(
                    child: JaihindBrandLogo(
                      fontSize: 26,
                      emblemHeight: 38,
                      showSubtitle: true,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title & Subtitle
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Join JAIHIND & start tracking your fitness journey.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Server Error Message Banner
                  if (_serverErrorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _serverErrorMessage!,
                              style: const TextStyle(
                                color: Color(0xFF991B1B),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 1. FULL NAME FIELD
                  _buildFieldLabel('Full Name'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                    style: const TextStyle(fontSize: 14),
                    decoration: _buildInputDecoration(
                      hint: 'Enter your full name',
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    validator: AppValidators.validateFullName,
                  ),

                  const SizedBox(height: 14),

                  // 2. USERNAME FIELD
                  _buildFieldLabel('Username'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                    style: const TextStyle(fontSize: 14),
                    decoration: _buildInputDecoration(
                      hint: 'e.g. runner_01',
                      prefixIcon: Icons.alternate_email_rounded,
                    ),
                    validator: AppValidators.validateUsername,
                  ),

                  const SizedBox(height: 14),

                  // 3. EMAIL FIELD
                  _buildFieldLabel('Email Address'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                    style: const TextStyle(fontSize: 14),
                    decoration: _buildInputDecoration(
                      hint: 'example@gmail.com',
                      prefixIcon: Icons.email_outlined,
                    ),
                    validator: AppValidators.validateEmail,
                  ),

                  const SizedBox(height: 14),

                  // 4. PASSWORD FIELD
                  _buildFieldLabel('Password'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                    style: const TextStyle(fontSize: 14),
                    decoration: _buildInputDecoration(
                      hint: 'e.g. Example@123',
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
                    validator: AppValidators.validatePassword,
                  ),

                  const SizedBox(height: 14),

                  // 5. CONFIRM PASSWORD FIELD
                  _buildFieldLabel('Confirm Password'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    enabled: !_isLoading,
                    style: const TextStyle(fontSize: 14),
                    decoration: _buildInputDecoration(
                      hint: 'Re-enter your password',
                      prefixIcon: Icons.lock_reset_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textGrey,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (val) => AppValidators.validateConfirmPassword(
                      _passwordController.text,
                      val,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 6. CREATE ACCOUNT BUTTON
                  BouncingTap(
                    onTap: _isLoading ? null : _submitRegister,
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
                                'CREATE ACCOUNT',
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

                  const SizedBox(height: 20),

                  // 7. ALREADY HAVE AN ACCOUNT? LOGIN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                      BouncingTap(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            AppRouteTransitions.slideHorizontal(const LoginScreen()),
                          );
                        },
                        child: const Text(
                          'Login',
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
