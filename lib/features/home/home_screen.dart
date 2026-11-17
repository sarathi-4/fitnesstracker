import 'package:flutter/material.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/navigation/main_navigation_screen.dart';
import '../../core/widgets/jaihind_brand_logo.dart';
import '../social/notifications_screen.dart';
import '../social/search_users_screen.dart';
import '../social/social_feed_screen.dart';
import '../workout/workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _hasUnreadNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP HEADER (With crisp vector logo & functional action buttons)
            _buildTopHeader(),

            // SCROLLABLE OVERVIEW DASHBOARD CONTENT
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. WELCOME BANNER (Entry animation 0)
                    FadeSlideEntry(
                      index: 0,
                      child: _buildWelcomeBanner(),
                    ),

                    const SizedBox(height: 14),

                    // 3. ABOUT JAIHIND CARD (Entry animation 1)
                    FadeSlideEntry(
                      index: 1,
                      child: _buildAboutCard(),
                    ),

                    const SizedBox(height: 18),

                    // 4. HOW IT'S USED SECTION (Entry animation 2)
                    FadeSlideEntry(
                      index: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(
                            title: "How It's Used",
                            subtitle: "Track almost any activity",
                          ),
                          const SizedBox(height: 12),
                          _buildHowItsUsedActivities(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 5. KEY BENEFITS SECTION (Entry animation 3)
                    FadeSlideEntry(
                      index: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(
                            title: "Key Benefits",
                            subtitle: "Get more from every move.",
                          ),
                          const SizedBox(height: 14),
                          _buildKeyBenefitsRow(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 6. JAIHIND ATHLETES NETWORK BANNER (Followers & Friends Feed)
                    FadeSlideEntry(
                      index: 4,
                      child: _buildCommunityConnectBanner(context),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 7. BOTTOM NAVIGATION BAR (Shown only if not hosted in MainNavigationScreen)
      bottomNavigationBar: MainNavigationScreen.of(context) == null
          ? _buildBottomNavigationBar()
          : null,
    );
  }

  // 1. TOP HEADER COMPONENT (Ultra-sharp vector brand logo + functional actions)
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
      ),
      child: Row(
        children: [
          // Official JAIHIND RUNNERS CLUB Circular Emblem + Typography Logo
          const JaihindBrandLogo(
            fontSize: 22,
            emblemHeight: 32,
            showSubtitle: true,
          ),
          const Spacer(),
          // Action 1: Search -> Athletes & Community Explorer
          _buildHeaderIcon(
            Icons.search,
            () {
              Navigator.push(
                context,
                AppRouteTransitions.slideHorizontal(const SearchUsersScreen()),
              );
            },
            tooltip: 'Search Athletes',
          ),
          const SizedBox(width: 14),
          // Action 2: Followers & Friends Feed (Community Feed)
          _buildHeaderIcon(
            Icons.dynamic_feed_rounded,
            () {
              Navigator.push(
                context,
                AppRouteTransitions.slideHorizontal(const SocialFeedScreen()),
              );
            },
            tooltip: 'Community Feed',
          ),
          const SizedBox(width: 14),
          // Action 3: Notification Bell with live unread indicator
          _buildNotificationBellIcon(),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap, {String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          color: Colors.transparent,
          child: Icon(
            icon,
            size: 26,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBellIcon() {
    return GestureDetector(
      onTap: () {
        setState(() => _hasUnreadNotifications = false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        color: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 26,
              color: AppColors.textDark,
            ),
            if (_hasUnreadNotifications)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }





  // 2. WELCOME BANNER COMPONENT
  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF0F7FF), // Soft Inpand Blue Tint
            Color(0xFFF0FDF4), // Soft Inpand Green Tint
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Runner illustration on the right
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 170,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Image.asset(
                'assets/images/welcome_runner.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),

          // Left Text & CTA Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.8,
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
                const SizedBox(height: 2),
                const Text(
                  'Track. Train. Achieve.',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const SizedBox(
                  width: 170,
                  child: Text(
                    'Log your activities, see your progress, and challenge yourself.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                BouncingTap(
                  onTap: () {
                    final nav = MainNavigationScreen.of(context);
                    if (nav != null) {
                      nav.switchTab(2); // Switch to Workout tab
                    } else {
                      Navigator.push(
                        context,
                        AppRouteTransitions.slideUp(const WorkoutScreen()),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Start Your Activity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. ABOUT JAIHIND CARD COMPONENT
  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Enhanced Larger App Logo Icon (68x68)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/jaihind_app_icon.png',
                width: 68,
                height: 68,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Heading and Professional 30-40 Words Description
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About JAIHIND',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'JAIHIND is your ultimate fitness companion to track runs, rides, walks, and workouts. Set ambitious goals, monitor your live progress, and achieve peak health with an empowering, all-in-one active training experience.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4 & 5. SECTION TITLE WITH TECH BLUE-GREEN PILL
  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4.5,
              height: 18,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(left: 13.5),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
            ),
          ),
        ),
      ],
    );
  }

  // 4. HOW IT'S USED ACTIVITY ICONS (Medium, high-contrast, prominent icons & bold dark text)
  Widget _buildHowItsUsedActivities() {
    final activities = [
      {'label': 'Run', 'icon': Icons.directions_run_rounded, 'color': AppColors.primaryBlue},
      {'label': 'Cycling', 'icon': Icons.directions_bike_rounded, 'color': AppColors.accentGreen},
      {'label': 'Walk', 'icon': Icons.directions_walk_rounded, 'color': AppColors.primaryBlue},
      {'label': 'Hike', 'icon': Icons.hiking_rounded, 'color': AppColors.accentGreen},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: activities.map((item) {
        return BouncingTap(
          onTap: () {
            final nav = MainNavigationScreen.of(context);
            if (nav != null) nav.switchTab(2);
          },
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (item['color'] as Color).withOpacity(0.35),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (item['color'] as Color).withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color,
                  size: 32, // Medium, prominent size
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['label'] as String,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black, // Dark & crystal clear
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 5. KEY BENEFITS ROW (4 Items with Prominent Icons & Clear Dark Typography)
  Widget _buildKeyBenefitsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildBenefitItem(
              icon: Icons.trending_up_rounded,
              iconColor: AppColors.primaryBlue,
              title: 'Track Progress',
              subtitle: 'See your\nimprovement',
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildBenefitItem(
              icon: Icons.emoji_events_rounded,
              iconColor: AppColors.accentGreen,
              title: 'Set Goals',
              subtitle: 'Push yourself\nfurther',
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildBenefitItem(
              icon: Icons.people_alt_rounded,
              iconColor: AppColors.primaryBlue,
              title: 'Join Community',
              subtitle: 'Be part of\nsomething bigger',
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildBenefitItem(
              icon: Icons.favorite_rounded,
              iconColor: AppColors.accentGreen,
              title: 'Stay Healthy',
              subtitle: 'Build a more\nactive you',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 30, // Medium prominent size
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.black, // Dark and clear
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155), // High-contrast slate grey
            height: 1.25,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 52,
      width: 1,
      color: const Color(0xFFE2E8F0),
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }





  // 9. JAIHIND ATHLETES NETWORK BANNER (Clean Light Theme Card)
  Widget _buildCommunityConnectBanner(BuildContext context) {
    return BouncingTap(
      onTap: () {
        Navigator.push(
          context,
          AppRouteTransitions.slideHorizontal(const SocialFeedScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Image.asset(
                'assets/images/jaihind_logo_circle.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JAIHIND ATHLETE NETWORK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Followers & Friends Feed',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textBlack,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'View Feed 📰',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 6. BOTTOM NAVIGATION BAR
  Widget _buildBottomNavigationBar() {
    final navItems = [
      {'label': 'Home', 'icon': Icons.home_rounded},
      {'label': 'Maps', 'icon': Icons.map_outlined},
      {'label': 'Start', 'icon': Icons.play_circle_fill_rounded},
      {'label': 'Streak', 'icon': Icons.local_fire_department_rounded},
      {'label': 'You', 'icon': Icons.account_circle_outlined},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final isSelected = _selectedIndex == index;
              final item = navItems[index];

              return InkWell(
                onTap: () {
                  if (index == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkoutScreen(),
                      ),
                    );
                  } else {
                    setState(() {
                      _selectedIndex = index;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Home has a highlighted orange indicator when active
                      if (index == 0 && isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            size: 26,
                            color: AppColors.primaryOrange,
                          ),
                        )
                      else
                        Icon(
                          item['icon'] as IconData,
                          size: 26,
                          color: isSelected ? AppColors.primaryOrange : AppColors.navGrey,
                        ),
                      const SizedBox(height: 3),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? AppColors.primaryOrange : AppColors.navGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
