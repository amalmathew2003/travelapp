import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:travalapp/model/traval_session.dart';
import 'package:travalapp/theme/app_theme.dart';
import 'package:travalapp/widgets/glass_container.dart';

class DistanceChartScreen extends StatelessWidget {
  final List<TravelSession> sessions;

  const DistanceChartScreen({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> dailyTotals = {};
    final Map<String, double> dailyCalories = {};
    final Map<String, int> dailyCounts = {};

    for (final s in sessions) {
      final day = DateFormat('dd MMM').format(s.startTime);
      dailyTotals[day] = (dailyTotals[day] ?? 0) + s.distance / 1000;
      dailyCalories[day] = (dailyCalories[day] ?? 0) + s.calories;
      dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
    }

    final entries = dailyTotals.entries.toList();
    final totalKm = entries.fold<double>(0, (sum, e) => sum + e.value);
    final totalCalories =
        dailyCalories.values.fold<double>(0, (sum, e) => sum + e);
    final avgPerSession =
        sessions.isNotEmpty ? totalKm / sessions.length : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Analytics"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Summary cards row
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  'Total',
                  '${totalKm.toStringAsFixed(1)} km',
                  Icons.straighten_rounded,
                  AppColors.primaryGradient,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  'Calories',
                  totalCalories.toStringAsFixed(0),
                  Icons.local_fire_department_rounded,
                  AppColors.warmGradient,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  'Avg/Trip',
                  '${avgPerSession.toStringAsFixed(1)} km',
                  Icons.analytics_rounded,
                  AppColors.accentGradient,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Chart card
          GradientGlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Distance',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Distance covered per day (km)',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  child: entries.isEmpty
                      ? Center(
                          child: Text(
                            'No data to display',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: entries
                                    .map((e) => e.value)
                                    .reduce((a, b) => a > b ? a : b) +
                                2,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipPadding: const EdgeInsets.all(10),
                                tooltipBorderRadius: BorderRadius.circular(12),
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    "${entries[group.x].key}\n",
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            "${rod.toY.toStringAsFixed(2)} km",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 2,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.white.withAlpha((255 * 0.05).round()),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= entries.length) {
                                      return const SizedBox();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        entries[value.toInt()].key,
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            barGroups: List.generate(entries.length, (i) {
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: entries[i].value,
                                    width: 22,
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.accent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                          duration:
                              const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Calories chart
          GradientGlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calories Burned',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Calories burnt per day',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 180,
                  child: dailyCalories.isEmpty
                      ? Center(
                          child: Text(
                            'No data to display',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: dailyCalories.values.isEmpty
                                ? 100
                                : dailyCalories.values
                                        .reduce((a, b) => a > b ? a : b) +
                                    50,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color:
                                    Colors.white.withAlpha((255 * 0.05).round()),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final calEntries =
                                        dailyCalories.entries.toList();
                                    if (value.toInt() >= calEntries.length) {
                                      return const SizedBox();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        calEntries[value.toInt()].key,
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            barGroups: List.generate(
                                dailyCalories.entries.length, (i) {
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: dailyCalories.entries
                                        .elementAt(i)
                                        .value,
                                    width: 22,
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.accentOrange,
                                        AppColors.accentRed,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                          duration:
                              const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _summaryCard(
      String label, String value, IconData icon, LinearGradient gradient) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withAlpha((255 * 0.3).round()),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
