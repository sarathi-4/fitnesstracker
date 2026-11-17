import 'package:flutter/material.dart';
import '../animations/app_animations.dart';
import '../constants/app_colors.dart';
import '../../features/home/home_screen.dart';
import '../../features/maps/maps_screen.dart';
import '../../features/workout/workout_screen.dart';
import '../../features/streak/streak_screen.dart';
import '../../features/profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  static MainNavigationScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainNavigationScreenState>();
  }

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  // Exact 5 Tabs in Order: Home, Maps, Start, Streak, You
  final List<Widget> _screens = const [
    HomeScreen(),
    MapsScreen(),
    WorkoutScreen(),
    StreakScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void switchTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'label': 'Home', 'icon': Icons.home_rounded},
      {'label': 'Maps', 'icon': Icons.map_outlined},
      {'label': 'Start', 'icon': Icons.play_circle_fill_rounded},
      {'label': 'Streak', 'icon': Icons.local_fire_department_rounded},
      {'label': 'You', 'icon': Icons.account_circle_outlined},
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      // Fluid, premium page transition animation on tab switch
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0.04, 0.0),
            end: Offset.zero,
          ).animate(animation);
          final scale = Tween<double>(
            begin: 0.98,
            end: 1.0,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slide,
              child: ScaleTransition(scale: scale, child: child),
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 0.8,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final isSelected = _currentIndex == index;
                final item = navItems[index];

                return BouncingTap(
                  scaleFactor: 0.92,
                  onTap: () => switchTab(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated pill highlight when selected
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: isSelected
                              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 5)
                              : const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (index == 3
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFEFF6FF))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(
                                    color: (index == 3
                                        ? AppColors.accentGreen.withOpacity(0.3)
                                        : AppColors.primaryBlue.withOpacity(0.25)),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            size: 28, // Medium, prominent, ultra-sharp size
                            color: isSelected
                                ? (index == 3 ? const Color(0xFF16A34A) : AppColors.primaryBlue)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                            letterSpacing: -0.1,
                            color: isSelected
                                ? (index == 3 ? const Color(0xFF15803D) : AppColors.primaryBlue)
                                : const Color(0xFF475569),
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
      ),
    );
  }
}
