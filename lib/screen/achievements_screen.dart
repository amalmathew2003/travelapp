import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:travalapp/model/traval_session.dart';
import 'package:travalapp/theme/app_theme.dart';
import 'package:travalapp/utils/constants.dart';
import 'package:travalapp/widgets/glass_container.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('travel_sessions');
    final sessions = box
        .toMap()
        .entries
        .map((e) => TravelSession.fromMap(e.value))
        .toList();

    // Calculate total distance
    double totalDistance = 0;
    for (final s in sessions) {
      totalDistance += s.distance;
    }

    // Calculate total sessions count
    int totalSessions = sessions.length;

    // Calculate unique days
    final uniqueDays = sessions
        .map((s) =>
            DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet()
        .length;

    final milestones = AppConstants.achievementMilestones;
    final badges = AppConstants.achievementBadges;

    // Count unlocked
    int unlockedCount =
        milestones.where((m) => totalDistance >= m).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Text(
              'Achievements',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$unlockedCount of ${milestones.length} unlocked',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            // Progress overview card
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _overviewStat(
                        (totalDistance / 1000).toStringAsFixed(1),
                        'km traveled',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withAlpha((255 * 0.3).round()),
                      ),
                      _overviewStat(
                        '$totalSessions',
                        'sessions',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withAlpha((255 * 0.3).round()),
                      ),
                      _overviewStat(
                        '$uniqueDays',
                        'active days',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: milestones.isEmpty ? 0 : unlockedCount / milestones.length,
                      backgroundColor: Colors.white.withAlpha((255 * 0.2).round()),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    milestones.isEmpty ? '0% Complete' : '${(unlockedCount / milestones.length * 100).toStringAsFixed(0)}% Complete',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Badges',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // Badge grid
            ...milestones.map((milestone) {
              final badge = badges[milestone]!;
              final isUnlocked = totalDistance >= milestone;
              final progress = (totalDistance / milestone).clamp(0.0, 1.0);
              final distanceLabel = milestone >= 1000
                  ? '${(milestone / 1000).toStringAsFixed(milestone % 1000 == 0 ? 0 : 1)} km'
                  : '${milestone.toInt()} m';

              return _BadgeCard(
                emoji: badge['emoji']!,
                title: badge['title']!,
                distanceLabel: distanceLabel,
                isUnlocked: isUnlocked,
                progress: progress,
              );
            }),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _overviewStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String distanceLabel;
  final bool isUnlocked;
  final double progress;

  const _BadgeCard({
    required this.emoji,
    required this.title,
    required this.distanceLabel,
    required this.isUnlocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return GradientGlassCard(
      child: Row(
        children: [
          // Badge icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isUnlocked
                  ? AppColors.primary.withAlpha((255 * 0.2).round())
                  : AppColors.surfaceLight,
            ),
            child: Center(
              child: Text(
                isUnlocked ? emoji : '🔒',
                style: TextStyle(
                  fontSize: isUnlocked ? 28 : 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isUnlocked
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  distanceLabel,
                  style: TextStyle(
                    color: isUnlocked ? AppColors.accent : AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation(
                      isUnlocked ? AppColors.accentGreen : AppColors.primary,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status
          if (isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.accentGreen.withAlpha((255 * 0.15).round()),
              ),
              child: Text(
                '✓ Done',
                style: TextStyle(
                  color: AppColors.accentGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
