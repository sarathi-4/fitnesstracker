import 'package:flutter/material.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/navigation/main_navigation_screen.dart';
import 'active_workout_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // Workout tab is selected by default (index 2)
  int _selectedIndex = 2;

  // Selected workout mode card (0: Running, 1: Walking, 2: Cycling, 3: Gym)
  int? _selectedWorkoutIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // 1. SCREEN TITLE & SUBTITLE + JAIHIND CLUB BADGE (Animated Entry)
            FadeSlideEntry(
              index: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workout Modes',
                            style: TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Encourage your workout, running goals,\nand improves your move.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textGrey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    BouncingTap(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                        MainNavigationScreen.of(context)?.switchTab(0);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/jaihind_logo_circle.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 2. 2x2 FULL-SCREEN FIT WORKOUT MODES GRID (Dynamic Responsive Height)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 14.0;
                    final totalHeight = constraints.maxHeight;
                    // Dynamically calculate exact card dimensions so the 4 cards completely fill the screen
                    final cardHeight = ((totalHeight - spacing) / 2).clamp(130.0, 260.0);

                    final modes = [
                      {
                        'image': 'assets/images/mode_running.png',
                        'title': 'Running',
                        'color': AppColors.primaryBlue,
                      },
                      {
                        'image': 'assets/images/mode_walking.png',
                        'title': 'Walking',
                        'color': AppColors.accentGreen,
                      },
                      {
                        'image': 'assets/images/mode_cycling.png',
                        'title': 'Cycling',
                        'color': AppColors.accentGreen,
                      },
                      {
                        'image': 'assets/images/mode_hike.png',
                        'title': 'Hike',
                        'color': AppColors.primaryBlue,
                      },
                    ];

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(), // Fills screen perfectly with zero awkward scrolling
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                        mainAxisExtent: cardHeight,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        return FadeSlideEntry(
                          index: index + 1,
                          child: _buildWorkoutCard(
                            index: index,
                            imagePath: modes[index]['image'] as String,
                            title: modes[index]['title'] as String,
                            themeColor: modes[index]['color'] as Color,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 6),

            // 3. "START NEW SESSION" ACTION BUTTON (With Tactile BouncingTap)
            FadeSlideEntry(
              index: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 14.0),
                child: _buildStartSessionButton(),
              ),
            ),
          ],
        ),
      ),
      // 4. BOTTOM NAVIGATION BAR (Shown only if not hosted in MainNavigationScreen)
      bottomNavigationBar: MainNavigationScreen.of(context) == null
          ? _buildBottomNavigationBar()
          : null,
    );
  }

  // WORKOUT MODE CARD COMPONENT (Fits full illustration with zero crop & brand colors)
  Widget _buildWorkoutCard({
    required int index,
    required String imagePath,
    required String title,
    required Color themeColor,
  }) {
    final isSelected = _selectedWorkoutIndex == index;

    return BouncingTap(
      onTap: () {
        setState(() {
          _selectedWorkoutIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? themeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2.4 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? themeColor.withOpacity(0.22)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mode Graphic - Fits completely inside with generous breathing room (NEVER cropped!)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 2.0),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain, // Fits entire illustration without any cut-off!
                    width: double.infinity,
                  ),
                ),
              ),

              // Mode Label
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? themeColor : Colors.black,
                    letterSpacing: -0.2,
                  ),
                ),
              ),

              // Thin Horizontal Divider
              const Divider(
                height: 1,
                thickness: 0.8,
                color: Color(0xFFF1F5F9),
                indent: 14,
                endIndent: 14,
              ),

              // Right Chevron (tap to start mode directly)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0, bottom: 6.0, top: 4.0),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: isSelected ? themeColor : const Color(0xFF94A3B8),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // START NEW SESSION BUTTON COMPONENT (With Inpand Tech Dual Gradient)
  Widget _buildStartSessionButton() {
    final modeNames = ['Running', 'Walking', 'Cycling', 'Hike'];
    final selectedMode = _selectedWorkoutIndex != null
        ? modeNames[_selectedWorkoutIndex!]
        : 'Workout';

    return BouncingTap(
      onTap: () {
        Navigator.push(
          context,
          AppRouteTransitions.slideUp(ActiveWorkoutScreen(initialMode: selectedMode)),
        );
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.38),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
              SizedBox(width: 8),
              Text(
                'Start New Session',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FIXED BOTTOM NAVIGATION BAR
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
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            size: 26,
                            color: AppColors.primaryBlue,
                          ),
                        )
                      else
                        Icon(
                          item['icon'] as IconData,
                          size: 26,
                          color: AppColors.navGrey,
                        ),
                      const SizedBox(height: 3),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.primaryBlue : AppColors.navGrey,
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
