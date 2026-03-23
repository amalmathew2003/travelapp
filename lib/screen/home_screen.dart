import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:travalapp/model/traval_session.dart';
import 'package:travalapp/theme/app_theme.dart';
import 'package:travalapp/widgets/glass_container.dart';
import 'package:travalapp/widgets/stat_card.dart';
import 'map_screen.dart';
import 'history_screen.dart';
import 'achievements_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isFullScreen = false;

  void _toggleFullScreen(bool isFull) {
    setState(() {
      _isFullScreen = isFull;
    });
  }

  // Build screens fresh each time so data refreshes
  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardTab();
      case 1:
        return MapScreen(onFullScreenToggle: _toggleFullScreen);
      case 2:
        return const HistoryScreen();
      case 3:
        return const AchievementsScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const DashboardTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(_currentIndex),
      bottomNavigationBar: _isFullScreen ? null : Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: Colors.white.withAlpha((255 * 0.06).round()),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
                _buildNavItem(1, Icons.map_rounded, 'Track'),
                _buildNavItem(2, Icons.history_rounded, 'History'),
                _buildNavItem(3, Icons.emoji_events_rounded, 'Awards'),
                _buildNavItem(4, Icons.settings_rounded, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isActive
              ? AppColors.primary.withAlpha((255 * 0.15).round())
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textMuted,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// DASHBOARD TAB
// ═══════════════════════════════════════════════════
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('travel_sessions');
    final settingsBox = Hive.box('user_settings');
    final allEntries = box.toMap().entries.toList().reversed.toList();

    final sessions =
        allEntries.map((e) => TravelSession.fromMap(e.value)).toList();

    // Read profile name from Hive
    final userName = settingsBox.get('userName', defaultValue: 'Traveler');

    // Calculate totals
    double totalDistance = 0;
    double totalCalories = 0;
    Duration totalDuration = Duration.zero;
    int totalSessions = sessions.length;

    for (final s in sessions) {
      totalDistance += s.distance;
      totalCalories += s.calories;
      totalDuration += s.duration;
    }

    // This week sessions
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekSessions = sessions.where((s) {
      return s.startTime.isAfter(
          DateTime(weekStart.year, weekStart.month, weekStart.day));
    }).toList();

    double weekDistance = 0;
    for (final s in thisWeekSessions) {
      weekDistance += s.distance;
    }

    // Streak calculation
    int streak = 0;
    if (sessions.isNotEmpty) {
      final sortedDates = sessions
          .map((s) => DateTime(
              s.startTime.year, s.startTime.month, s.startTime.day))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      if (sortedDates.isNotEmpty &&
          (sortedDates.first == today || sortedDates.first == yesterday)) {
        streak = 1;
        for (int i = 1; i < sortedDates.length; i++) {
          if (sortedDates[i] ==
              sortedDates[i - 1].subtract(const Duration(days: 1))) {
            streak++;
          } else {
            break;
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Greeting with actual user name
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hi, $userName 👋',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '$streak day${streak != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Weekly summary hero card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha((255 * 0.3).round()),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'This Week',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((255 * 0.2).round()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${thisWeekSessions.length} trips',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${(weekDistance / 1000).toStringAsFixed(2)} km',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'distance covered this week',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Total Distance',
                    value:
                        '${(totalDistance / 1000).toStringAsFixed(1)} km',
                    icon: Icons.straighten_rounded,
                    gradient: AppColors.primaryGradient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Calories',
                    value: '${totalCalories.toStringAsFixed(0)} kcal',
                    icon: Icons.local_fire_department_rounded,
                    gradient: AppColors.warmGradient,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Total Sessions',
                    value: '$totalSessions',
                    icon: Icons.route_rounded,
                    gradient: AppColors.accentGradient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Total Time',
                    value: _formatDuration(totalDuration),
                    icon: Icons.timer_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE040FB), Color(0xFF7C4DFF)],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent activity
            Text(
              'Recent Activity',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            if (sessions.isEmpty)
              GradientGlassCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.explore_off_rounded,
                      color: AppColors.textMuted,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No trips yet',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start tracking to see your activity here',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...sessions
                  .take(5)
                  .map((session) =>
                      _RecentActivityCard(session: session)),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }
}

class _RecentActivityCard extends StatelessWidget {
  final TravelSession session;

  const _RecentActivityCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');

    IconData activityIcon;
    switch (session.activityType) {
      case 'run':
        activityIcon = Icons.directions_run;
        break;
      case 'cycle':
        activityIcon = Icons.pedal_bike;
        break;
      case 'drive':
        activityIcon = Icons.directions_car;
        break;
      default:
        activityIcon = Icons.directions_walk;
    }

    return GradientGlassCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: AppColors.primaryGradient,
            ),
            child: Icon(activityIcon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.distanceKm.toStringAsFixed(2)} km',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(session.startTime),
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                session.formattedDuration,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${timeFormat.format(session.startTime)} → ${timeFormat.format(session.endTime)}',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
