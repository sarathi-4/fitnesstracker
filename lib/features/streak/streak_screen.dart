import 'package:flutter/material.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/user_service.dart';
import '../../core/widgets/jaihind_brand_logo.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  late DateTime _viewedMonth;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> _monthAbbrs = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewedMonth = DateTime(now.year, now.month, 1);
  }

  String _formatLiveDateTime() {
    final now = DateTime.now();
    final month = _monthAbbrs[now.month - 1];
    final day = now.day;
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$month $day • $hour:$minute $ampm';
  }

  void _previousMonth() {
    setState(() {
      _viewedMonth = DateTime(_viewedMonth.year, _viewedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _viewedMonth = DateTime(_viewedMonth.year, _viewedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserService.instance,
      builder: (context, _) {
        final user = UserService.instance;
        final activeStreak = user.activeStreakDays;
        final bestStreak = user.bestStreakDays;
        final consistency = user.getMonthConsistency(_viewedMonth.year, _viewedMonth.month);
        final completedDays = user.getCompletedDaysForMonth(_viewedMonth.year, _viewedMonth.month);

        return Scaffold(
          backgroundColor: AppColors.backgroundWhite,
          body: SafeArea(
            child: Column(
              children: [
                // TOP HEADER: JAIHIND Brand Logo (tap to Home) + Live Date & Time pill
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    children: [
                      const JaihindBrandLogo(
                        fontSize: 22,
                        emblemHeight: 30,
                        showSubtitle: true,
                      ),
                      const Spacer(),
                      // Live Date & Time pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4EC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFDEC9), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _formatLiveDateTime(),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // SCROLLABLE STREAK CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SCREEN TITLE & SUBTITLE
                        const FadeSlideEntry(
                          index: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Running Streak',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Track daily running days & habit consistency.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // CARD 1: STREAK SCORECARD HERO
                        FadeSlideEntry(
                          index: 1,
                          child: _buildStreakHeroCard(activeStreak, bestStreak, consistency),
                        ),

                        const SizedBox(height: 16),

                        // CARD 2: MONTH CALENDAR TRACKER (Dynamically highlighted on daily completion)
                        FadeSlideEntry(
                          index: 2,
                          child: _buildCalendarTrackerCard(completedDays, user),
                        ),

                        const SizedBox(height: 18),

                        // CARD 3: STREAK MILESTONES & REWARDS (Fills screen with engaging badges)
                        FadeSlideEntry(
                          index: 3,
                          child: _buildStreakMilestonesCard(activeStreak),
                        ),

                        const SizedBox(height: 18),

                        // CARD 4: DAILY RUNNING MOTIVATION TIP
                        FadeSlideEntry(
                          index: 4,
                          child: _buildDailyRunnerMotivationCard(),
                        ),

                        const SizedBox(height: 28),
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

  // HERO STREAK CARD
  Widget _buildStreakHeroCard(int activeStreak, int bestStreak, int consistency) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF0FDF4), // Soft Tech Green
            Color(0xFFF0F7FF), // Soft Tech Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Large Glowing Flame Icon with Pulse Animation
              PulseGlow(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGreen.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.accentGreen,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Streak Count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$activeStreak',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accentGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'DAYS STREAK',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      activeStreak > 0
                          ? 'Outstanding discipline! Keep going!'
                          : 'Complete a workout today to start your streak!',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1F2937),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // 3 Metric Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricStat('🔥 $activeStreak Days', 'Active Streak'),
              Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
              _buildMetricStat('🏆 $bestStreak Days', 'Best Streak'),
              Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
              _buildMetricStat('🎯 $consistency%', 'Consistency'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }

  // CALENDAR CARD WITH HIGHLIGHTED RUNNING DAYS
  Widget _buildCalendarTrackerCard(Set<int> completedDays, UserService user) {
    final year = _viewedMonth.year;
    final month = _viewedMonth.month;
    final monthTitle = '${_monthNames[month - 1]} $year';
    final now = DateTime.now();
    final isCurrentMonth = (now.year == year && now.month == month);
    final today = now.day;

    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday; // 1 = Monday ... 7 = Sunday
    final firstDayOffset = firstWeekday % 7; // Sunday = 0 ... Saturday = 6

    // Previous month info
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final prevDaysCount = DateUtils.getDaysInMonth(prevYear, prevMonth);

    // Build grid rows
    final List<Widget> weekRows = [];
    List<Widget> currentWeek = [];

    // 1. Trailing days of previous month
    for (int i = 0; i < firstDayOffset; i++) {
      final dayNum = prevDaysCount - firstDayOffset + 1 + i;
      currentWeek.add(_buildCalendarDayCell(
        dayStr: '$dayNum',
        isPastMonth: true,
        isRunningDay: false,
        isToday: false,
        onTap: null,
      ));
    }

    // 2. Days of current viewed month
    for (int day = 1; day <= daysInMonth; day++) {
      final isRunningDay = completedDays.contains(day);
      final isDayToday = isCurrentMonth && (day == today);

      currentWeek.add(_buildCalendarDayCell(
        dayStr: '$day',
        isPastMonth: false,
        isRunningDay: isRunningDay,
        isToday: isDayToday,
        onTap: () {
          final targetDate = DateTime(year, month, day);
          user.toggleStreakDate(targetDate);
          final updated = user.hasWorkoutOnDate(targetDate);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                updated
                    ? '🔥 Workout logged for ${_monthNames[month - 1]} $day! Streak updated!'
                    : 'Workout log removed for ${_monthNames[month - 1]} $day',
              ),
              backgroundColor: AppColors.primaryOrange,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ));

      if (currentWeek.length == 7) {
        weekRows.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.from(currentWeek),
          ),
        ));
        currentWeek.clear();
      }
    }

    // 3. Leading days of next month to fill out the last row
    if (currentWeek.isNotEmpty) {
      int nextDay = 1;
      while (currentWeek.length < 7) {
        currentWeek.add(_buildCalendarDayCell(
          dayStr: '$nextDay',
          isPastMonth: true,
          isRunningDay: false,
          isToday: false,
          onTap: null,
        ));
        nextDay++;
      }
      weekRows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.from(currentWeek),
        ),
      ));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Header with Left / Right Navigation
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 24,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 10),
              Text(
                monthTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.chevron_left_rounded, size: 26, color: AppColors.textDark),
                onPressed: _previousMonth,
              ),
              const SizedBox(width: 12),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.chevron_right_rounded, size: 26, color: AppColors.textDark),
                onPressed: _nextMonth,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Days of Week Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CalendarDayTitle('Sun'),
              _CalendarDayTitle('Mon'),
              _CalendarDayTitle('Tue'),
              _CalendarDayTitle('Wed'),
              _CalendarDayTitle('Thu'),
              _CalendarDayTitle('Fri'),
              _CalendarDayTitle('Sat'),
            ],
          ),

          const SizedBox(height: 10),

          // Dynamic Calendar Grid
          ...weekRows,

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(AppColors.primaryBlue, 'Running Day (Streak)'),
              const SizedBox(width: 18),
              _buildLegendItem(Colors.grey.shade400, 'Rest Day'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarDayCell({
    required String dayStr,
    required bool isPastMonth,
    required bool isRunningDay,
    required bool isToday,
    required VoidCallback? onTap,
  }) {
    Widget cell;

    if (isRunningDay && !isPastMonth) {
      // HIGHLIGHTED RUNNING DAY (Dual Gradient + Flame)
      cell = Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              dayStr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Positioned(
              top: 2,
              right: 4,
              child: Text(
                '🔥',
                style: TextStyle(fontSize: 9),
              ),
            ),
          ],
        ),
      );
    } else {
      // Rest / Normal day
      cell = Container(
        width: 38,
        height: 38,
        decoration: isToday && !isPastMonth
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryBlue, width: 2),
              )
            : null,
        child: Center(
          child: Text(
            dayStr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPastMonth ? Colors.black26 : AppColors.textDark,
            ),
          ),
        ),
      );
    }

    if (onTap != null && !isPastMonth) {
      return BouncingTap(
        onTap: onTap,
        child: cell,
      );
    }
    return cell;
  }

  // 3. STREAK MILESTONES & BADGES
  Widget _buildStreakMilestonesCard(int activeStreak) {
    final milestones = [
      {'title': '3 Days', 'subtitle': 'Bronze Flame', 'icon': '🥉', 'unlocked': activeStreak >= 3},
      {'title': '7 Days', 'subtitle': 'Silver Stride', 'icon': '🥈', 'unlocked': activeStreak >= 7},
      {'title': '14 Days', 'subtitle': 'Gold Pacer', 'icon': '🥇', 'unlocked': activeStreak >= 14},
      {'title': '30 Days', 'subtitle': 'Club Legend', 'icon': '👑', 'unlocked': activeStreak >= 30},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🏆', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Streak Milestones & Badges',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Unlock badges as your consecutive daily running habit builds.',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: milestones.map((m) {
              final isUnlocked = m['unlocked'] as bool;
              return Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isUnlocked ? const Color(0xFFFFF7ED) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isUnlocked ? AppColors.primaryOrange : const Color(0xFFE2E8F0),
                        width: isUnlocked ? 2 : 1,
                      ),
                      boxShadow: isUnlocked
                          ? [
                              BoxShadow(
                                color: AppColors.primaryOrange.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        m['icon'] as String,
                        style: TextStyle(fontSize: isUnlocked ? 24 : 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    m['title'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isUnlocked ? Colors.black : const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    m['subtitle'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isUnlocked ? AppColors.primaryOrange : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 4. DAILY RUNNER MOTIVATION TIP
  Widget _buildDailyRunnerMotivationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_rounded, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coach Tip: Consistency Over Distance',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Running 20 minutes every day trains aerobic capacity and habit formation better than a single long run once a week.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDayTitle extends StatelessWidget {
  final String label;
  const _CalendarDayTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}
