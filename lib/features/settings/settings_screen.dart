import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';
import '../../core/widgets/jaihind_brand_logo.dart';
import '../onboarding/welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  String _selectedLanguage = 'English';
  String _selectedUnits = 'Kilometres';

  // Privacy & Security Toggles
  bool _isPrivateAccount = false;
  bool _showRouteOnMap = true;
  bool _shareToLeaderboard = true;
  bool _twoFactorAuth = false;

  // Notification Toggles
  bool _pushNotifications = true;
  bool _workoutReminders = true;
  bool _socialInteractions = true;
  bool _streakAlerts = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, _) {
        final user = UserService.instance;

        return Scaffold(
          backgroundColor: AppColors.backgroundWhite,
          body: SafeArea(
            child: Column(
              children: [
                // TOP HEADER (Back Button + JAIHIND Logo + Notification Bell)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    children: [
                      BouncingTap(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 24,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const JaihindBrandLogo(
                        fontSize: 22,
                        emblemHeight: 30,
                        showSubtitle: true,
                      ),
                      const Spacer(),
                      BouncingTap(
                        onTap: () => _showNotificationsSheet(context),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 26,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),

                // SCROLLABLE SETTINGS CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SETTINGS TITLE & SUBTITLE
                        const FadeSlideEntry(
                          delay: Duration.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Manage your app preferences & account',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // CARD 1: USER PROFILE HEADER (Tappable to Account Settings)
                        FadeSlideEntry(
                          delay: const Duration(milliseconds: 40),
                          child: _buildUserProfileCard(user),
                        ),

                        const SizedBox(height: 14),

                        // CARD 2: ACCOUNT SETTINGS, PRIVACY & NOTIFICATIONS
                        FadeSlideEntry(
                          delay: const Duration(milliseconds: 80),
                          child: _buildSettingsGroup([
                            _SettingTileData(
                              icon: Icons.person_outline_rounded,
                              title: 'Account Settings',
                              subtitle: 'Update your personal details',
                              onTap: () => _showAccountSettingsSheet(context, user),
                            ),
                            _SettingTileData(
                              icon: Icons.shield_outlined,
                              title: 'Privacy & Security',
                              subtitle: 'Manage your data and security',
                              onTap: () => _showPrivacySecuritySheet(context, user),
                            ),
                            _SettingTileData(
                              icon: Icons.notifications_none_rounded,
                              title: 'Notifications',
                              subtitle: 'Control your notifications',
                              onTap: () => _showNotificationsSheet(context),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 14),

                        // CARD 3: PREFERENCES (Appearance, Language, Units)
                        FadeSlideEntry(
                          delay: const Duration(milliseconds: 120),
                          child: _buildSettingsGroup([
                            _SettingTileData(
                              icon: Icons.palette_outlined,
                              title: 'Appearance',
                              subtitle: 'Switch between light and dark mode',
                              customTrailing: Switch(
                                value: _darkMode,
                                activeColor: AppColors.primaryOrange,
                                activeTrackColor: AppColors.primaryOrange.withOpacity(0.4),
                                onChanged: (val) {
                                  setState(() {
                                    _darkMode = val;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        val ? '🌙 Dark Mode enabled' : '☀️ Light Mode enabled',
                                      ),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ),
                            _SettingTileData(
                              icon: Icons.public_rounded,
                              title: 'Language',
                              subtitle: 'Choose your preferred language',
                              trailingText: _selectedLanguage,
                              onTap: () => _showLanguagePicker(),
                            ),
                            _SettingTileData(
                              icon: Icons.straighten_rounded,
                              title: 'Units',
                              subtitle: 'Select distance units',
                              trailingText: _selectedUnits,
                              onTap: () => _showUnitsPicker(),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 14),

                        // CARD 4: ABOUT & LEGAL
                        FadeSlideEntry(
                          delay: const Duration(milliseconds: 160),
                          child: _buildSettingsGroup([
                            _SettingTileData(
                              icon: Icons.info_outline_rounded,
                              title: 'About JAIHIND',
                              subtitle: 'App version, terms and more',
                              trailingText: 'v1.0.0',
                              onTap: () => _showAboutDialog(context),
                            ),
                            _SettingTileData(
                              icon: Icons.help_outline_rounded,
                              title: 'Help & Support',
                              subtitle: 'Get help or contact us',
                              onTap: () => _showHelpSupportSheet(context),
                            ),
                            _SettingTileData(
                              icon: Icons.description_outlined,
                              title: 'Terms & Conditions',
                              subtitle: 'Read our terms and conditions',
                              onTap: () => _showTermsDialog(context),
                            ),
                            _SettingTileData(
                              icon: Icons.verified_user_outlined,
                              title: 'Privacy Policy',
                              subtitle: 'Learn how we protect your data',
                              onTap: () => _showPrivacyPolicyDialog(context),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 20),

                        // LOG OUT BUTTON
                        FadeSlideEntry(
                          delay: const Duration(milliseconds: 200),
                          child: _buildLogOutButton(context),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // CARD 1: USER PROFILE PREVIEW (Tappable to Account Settings)
  Widget _buildUserProfileCard(UserService user) {
    return BouncingTap(
      onTap: () => _showAccountSettingsSheet(context, user),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0F0F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular Avatar with smart image resolver
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryBlue,
                  width: 2.2,
                ),
              ),
              child: _buildAvatarWidget(user, radius: 32),
            ),
            const SizedBox(width: 15),

            // User Name & Email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isNotEmpty ? user.name : 'JAIHIND Athlete',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email.isNotEmpty ? user.email : 'athlete@jaihind.com',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textGrey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textDark,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWidget(UserService user, {double radius = 32}) {
    final imagePath = user.profileImagePath;
    if (imagePath != null && imagePath.trim().isNotEmpty) {
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFFF0F7FF),
          backgroundImage: NetworkImage(imagePath),
        );
      }
      final file = File(imagePath);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFFF0F7FF),
          backgroundImage: FileImage(file),
        );
      }
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFF0F7FF),
      child: ClipOval(
        child: Image.asset(
          'assets/images/jaihind_logo_circle.png',
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
        ),
      ),
    );
  }

  // GROUPED SETTINGS CARD
  Widget _buildSettingsGroup(List<_SettingTileData> items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F4F8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;

          return Column(
            children: [
              BouncingTap(
                onTap: item.onTap ?? () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color: AppColors.primaryBlue,
                        size: 25,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.customTrailing != null)
                        item.customTrailing!
                      else ...[
                        if (item.trailingText != null)
                          Text(
                            item.trailingText!,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textDark,
                          size: 22,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(height: 1, thickness: 0.8, color: Color(0xFFF5F5F5), indent: 56),
            ],
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. ACCOUNT SETTINGS SHEET (Interactive update: Name, Username, Email, Password, Photo)
  // ---------------------------------------------------------------------------
  void _showAccountSettingsSheet(BuildContext context, UserService user) {
    final nameCtrl = TextEditingController(text: user.displayName.isNotEmpty ? user.displayName : user.name);
    final userCtrl = TextEditingController(text: user.username);
    final emailCtrl = TextEditingController(text: user.email);
    final passwordCtrl = TextEditingController(text: user.password);
    bool obscurePassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontSize: 15)),
                        ),
                        const Text(
                          'Account Settings',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final name = nameCtrl.text.trim();
                            final username = userCtrl.text.trim();
                            final email = emailCtrl.text.trim();
                            final password = passwordCtrl.text;

                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter your full name')),
                              );
                              return;
                            }

                            user.updateProfile(
                              name: name,
                              email: email.isNotEmpty ? email : user.email,
                              password: password.isNotEmpty ? password : user.password,
                              username: username.isNotEmpty ? username : user.username,
                            );
                            user.updateInstagramProfile(
                              displayName: name,
                              username: username.isNotEmpty ? username : user.username,
                              bio: user.bio,
                              website: user.website,
                            );

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account details updated successfully! ✨'),
                                backgroundColor: AppColors.accentGreen,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Centered Avatar with change photo action
                    Center(
                      child: Column(
                        children: [
                          _buildAvatarWidget(user, radius: 42),
                          const SizedBox(height: 8),
                          BouncingTap(
                            onTap: () => _showChangePhotoOptions(context, user),
                            child: const Text(
                              'Change Profile Photo',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Full Name Field
                    _buildSettingsInputField('Full Name', nameCtrl, icon: Icons.person_outline_rounded),
                    const SizedBox(height: 14),

                    // Username Field
                    _buildSettingsInputField('Username', userCtrl, icon: Icons.alternate_email_rounded),
                    const SizedBox(height: 14),

                    // Email Field
                    _buildSettingsInputField('Email Address', emailCtrl, icon: Icons.mail_outline_rounded),
                    const SizedBox(height: 14),

                    // Password Field with Toggle
                    _buildSettingsInputField(
                      'Password',
                      passwordCtrl,
                      icon: Icons.lock_outline_rounded,
                      obscureText: obscurePassword,
                      trailing: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setModalState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Member since badge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 18, color: AppColors.accentGreen),
                          const SizedBox(width: 8),
                          Text(
                            'Member Since: ${user.dateOfJoining}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Save Changes Button
                    BouncingTap(
                      onTap: () {
                        final name = nameCtrl.text.trim();
                        final username = userCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final password = passwordCtrl.text;

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter your full name')),
                          );
                          return;
                        }

                        user.updateProfile(
                          name: name,
                          email: email.isNotEmpty ? email : user.email,
                          password: password.isNotEmpty ? password : user.password,
                          username: username.isNotEmpty ? username : user.username,
                        );
                        user.updateInstagramProfile(
                          displayName: name,
                          username: username.isNotEmpty ? username : user.username,
                          bio: user.bio,
                          website: user.website,
                        );

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Account details updated successfully! ✨'),
                            backgroundColor: AppColors.accentGreen,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsInputField(
    String label,
    TextEditingController controller, {
    required IconData icon,
    bool obscureText = false,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppColors.primaryBlue),
            suffixIcon: trailing,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
          ),
        ),
      ],
    );
  }

  void _showChangePhotoOptions(BuildContext context, UserService user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Change Profile Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryBlue),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (picked != null) {
                    user.updateImage(picked.path);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFFFF7ED), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryOrange),
                ),
                title: const Text('Take with Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                  if (picked != null) {
                    user.updateImage(picked.path);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. PRIVACY & SECURITY SHEET
  // ---------------------------------------------------------------------------
  void _showPrivacySecuritySheet(BuildContext context, UserService user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Privacy & Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primaryOrange,
                title: const Text('Private Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Only approved athletes can follow and view your workout history', style: TextStyle(fontSize: 12.5)),
                value: _isPrivateAccount,
                onChanged: (val) {
                  setModalState(() => _isPrivateAccount = val);
                  setState(() => _isPrivateAccount = val);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primaryOrange,
                title: const Text('Share GPS Routes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Display your running map lines on completed workout posts', style: TextStyle(fontSize: 12.5)),
                value: _showRouteOnMap,
                onChanged: (val) {
                  setModalState(() => _showRouteOnMap = val);
                  setState(() => _showRouteOnMap = val);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primaryOrange,
                title: const Text('Club Leaderboard Sharing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Include your weekly kilometers in JAIHIND Club rankings', style: TextStyle(fontSize: 12.5)),
                value: _shareToLeaderboard,
                onChanged: (val) {
                  setModalState(() => _shareToLeaderboard = val);
                  setState(() => _shareToLeaderboard = val);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primaryOrange,
                title: const Text('Two-Factor Authentication (2FA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Require OTP verification when logging in from new devices', style: TextStyle(fontSize: 12.5)),
                value: _twoFactorAuth,
                onChanged: (val) {
                  setModalState(() => _twoFactorAuth = val);
                  setState(() => _twoFactorAuth = val);
                },
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: AppColors.textDark,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.password_rounded, size: 18, color: AppColors.primaryBlue),
                label: const Text('Change Account Password', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAccountSettingsSheet(context, user);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. NOTIFICATIONS SHEET
  // ---------------------------------------------------------------------------
  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primaryOrange,
                title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Allow notifications on your device', style: TextStyle(fontSize: 12.5)),
                value: _pushNotifications,
                onChanged: (val) {
                  setModalState(() => _pushNotifications = val);
                  setState(() => _pushNotifications = val);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primaryOrange,
                title: const Text('Workout Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Daily reminder at 06:30 AM to stay consistent', style: TextStyle(fontSize: 12.5)),
                value: _workoutReminders,
                onChanged: (val) {
                  setModalState(() => _workoutReminders = val);
                  setState(() => _workoutReminders = val);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primaryOrange,
                title: const Text('Social Likes & Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Notify when athletes like or cheer your run', style: TextStyle(fontSize: 12.5)),
                value: _socialInteractions,
                onChanged: (val) {
                  setModalState(() => _socialInteractions = val);
                  setState(() => _socialInteractions = val);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primaryOrange,
                title: const Text('Streak Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Evening reminder before your active streak expires', style: TextStyle(fontSize: 12.5)),
                value: _streakAlerts,
                onChanged: (val) {
                  setModalState(() => _streakAlerts = val);
                  setState(() => _streakAlerts = val);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. PREFERENCE PICKERS (Language & Units)
  // ---------------------------------------------------------------------------
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final languages = ['English', 'தமிழ் (Tamil)', 'Hindi', 'Telugu'];
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...languages.map((lang) => ListTile(
                    title: Text(lang, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: _selectedLanguage == lang ? const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen) : null,
                    onTap: () {
                      setState(() => _selectedLanguage = lang);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Language set to $lang'), duration: const Duration(seconds: 1)),
                      );
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showUnitsPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final units = ['Kilometres', 'Miles'];
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Distance Units', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...units.map((u) => ListTile(
                    title: Text(u, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: _selectedUnits == u ? const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen) : null,
                    onTap: () {
                      setState(() => _selectedUnits = u);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Distance units set to $u'), duration: const Duration(seconds: 1)),
                      );
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 5. ABOUT, HELP, TERMS & PRIVACY MODALS
  // ---------------------------------------------------------------------------
  void _showAboutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Image.asset('assets/images/jaihind_logo_circle.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            const Text('JAIHIND RUNNERS CLUB', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('Version 1.0.0 (Build 2026.11)', style: TextStyle(fontSize: 12.5, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text(
              'TRACK. TRAIN. ACHIEVE.\n\nTamil Nadu\'s premier athletic community and GPS running tracker. Designed with pride for athletes, marathon runners, and fitness enthusiasts across India. 🇮🇳',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.textDark),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Close'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Help & Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('We are here to assist your fitness journey.', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                child: const Icon(Icons.email_outlined, color: AppColors.primaryBlue),
              ),
              title: const Text('Email Support', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('support@jaihindrunners.com'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(const ClipboardData(text: 'support@jaihindrunners.com'));
                messenger.showSnackBar(
                  const SnackBar(content: Text('Support email copied to clipboard!')),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFF0FDF4), shape: BoxShape.circle),
                child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF16A34A)),
              ),
              title: const Text('WhatsApp Helpline', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('+91 98765 43210 (JAIHIND Desk)'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final uri = Uri.parse('https://wa.me/919876543210?text=Hello%20JAIHIND%20Support');
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {
                  await Clipboard.setData(const ClipboardData(text: '+919876543210'));
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Phone number copied to clipboard!')),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            const Text('Frequently Asked Questions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildFaqItem('How do I track my running streak?', 'Every day you record and save an outdoor run or workout, your streak increases by +1 on the calendar!'),
            _buildFaqItem('How is distance calculated?', 'We use high-precision GPS satellite location directly from your device hardware to measure real distance.'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(question, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(answer, style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey, height: 1.35)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Terms & Conditions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              const Text(
                '1. Acceptance of Terms\nBy creating an account or using JAIHIND Runners Club, you agree to these Terms.\n\n'
                '2. Health & Physical Activity\nRunning and athletic workouts involve physical exertion. Please ensure you are medically fit before undertaking intense distance running. JAIHIND is an athletic tracking tool and does not provide clinical medical advice.\n\n'
                '3. Respect & Community Conduct\nAthletes must treat fellow club members with respect. Harassment, spam, or misleading activity recordings are strictly prohibited.\n\n'
                '4. GPS Data Accuracy\nRoute accuracy depends on device sensors and clear line-of-sight to GPS satellites.',
                style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.textDark),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('I Understand'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Privacy Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              const Text(
                '1. Location & GPS Data\nJAIHIND collects precise location data only during active workout recording sessions to calculate pace, distance, and route maps. We do not track your location in the background when no workout is running.\n\n'
                '2. Personal Information\nYour name, username, and email are stored securely. We do not sell or trade your personal data with third-party advertising brokers.\n\n'
                '3. Security & Local Storage\nWorkout sessions and credentials are protected with industry-standard encryption protocols on device storage and secured cloud instances.',
                style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.textDark),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Agree & Close'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. LOG OUT CONFIRMATION DIALOG
  // ---------------------------------------------------------------------------
  Widget _buildLogOutButton(BuildContext context) {
    return BouncingTap(
      onTap: () => _confirmLogOut(context),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFEF4444),
            width: 1.6,
          ),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of JAIHIND?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          BouncingTap(
            onTap: () async {
              final navigator = Navigator.of(context);
              Navigator.pop(ctx);
              await AuthService.instance.signOut();
              navigator.pushAndRemoveUntil(
                AppRouteTransitions.slideHorizontal(const WelcomeScreen()),
                (route) => false,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTileData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingText;
  final Widget? customTrailing;
  final VoidCallback? onTap;

  _SettingTileData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingText,
    this.customTrailing,
    this.onTap,
  });
}
