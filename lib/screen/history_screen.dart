import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:travalapp/model/traval_session.dart';
import 'package:travalapp/screen/distance_chart.dart';
import 'package:travalapp/theme/app_theme.dart';
import 'package:travalapp/widgets/glass_container.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Box box;
  late List<MapEntry<dynamic, dynamic>> visibleEntries;
  String filterActivity = 'all';

  @override
  void initState() {
    super.initState();
    box = Hive.box('travel_sessions');
    visibleEntries = box.toMap().entries.toList().reversed.toList();
  }

  // ─── WEEK HELPERS ──────────────────────────────
  bool isSameWeek(DateTime a, DateTime b) {
    final aStart = a.subtract(Duration(days: a.weekday - 1));
    final bStart = b.subtract(Duration(days: b.weekday - 1));
    return aStart.year == bStart.year &&
        aStart.month == bStart.month &&
        aStart.day == bStart.day;
  }

  bool isLastWeek(DateTime date) {
    final lastWeek = DateTime.now().subtract(const Duration(days: 7));
    return isSameWeek(date, lastWeek);
  }

  // ─── CONFIRM DELETE ────────────────────────────
  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Delete this trip?"),
            content: const Text(
              "This action cannot be undone unless you use Undo.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentRed,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ─── CLEAR ALL ─────────────────────────────────
  void _clearAllHistory() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clear all history?"),
        content: const Text("This will permanently delete all records."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
            ),
            onPressed: () {
              box.clear();
              setState(() => visibleEntries.clear());
              Navigator.pop(context);
            },
            child: const Text("Clear All"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter entries
    final filteredEntries = filterActivity == 'all'
        ? visibleEntries
        : visibleEntries.where((e) {
            final s = TravelSession.fromMap(e.value);
            return s.activityType == filterActivity;
          }).toList();

    final thisWeek = <MapEntry<dynamic, dynamic>>[];
    final lastWeek = <MapEntry<dynamic, dynamic>>[];
    final older = <MapEntry<dynamic, dynamic>>[];

    for (final e in filteredEntries) {
      final session = TravelSession.fromMap(e.value);
      if (isSameWeek(session.startTime, DateTime.now())) {
        thisWeek.add(e);
      } else if (isLastWeek(session.startTime)) {
        lastWeek.add(e);
      } else {
        older.add(e);
      }
    }

    // Summary stats
    double totalDist = 0;
    Duration totalDur = Duration.zero;
    for (final e in filteredEntries) {
      final s = TravelSession.fromMap(e.value);
      totalDist += s.distance;
      totalDur += s.duration;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'History',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.bar_chart_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () {
                      final sessions = visibleEntries
                          .map((e) => TravelSession.fromMap(e.value))
                          .toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DistanceChartScreen(sessions: sessions),
                        ),
                      );
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: AppColors.textSecondary),
                    onSelected: (v) {
                      if (v == 'clear') _clearAllHistory();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep_rounded,
                                color: AppColors.accentRed, size: 20),
                            const SizedBox(width: 8),
                            Text("Clear all history",
                                style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick summary
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  _quickStat(
                    '${(totalDist / 1000).toStringAsFixed(1)} km',
                    'Total',
                    AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _quickStat(
                    '${filteredEntries.length}',
                    'Trips',
                    AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  _quickStat(
                    _formatDuration(totalDur),
                    'Time',
                    AppColors.accentOrange,
                  ),
                ],
              ),
            ),

            // Activity filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('all', 'All', Icons.done_all_rounded),
                    _filterChip('walk', 'Walk', Icons.directions_walk),
                    _filterChip('run', 'Run', Icons.directions_run),
                    _filterChip('cycle', 'Cycle', Icons.pedal_bike),
                    _filterChip('drive', 'Drive', Icons.directions_car),
                  ],
                ),
              ),
            ),

            // List
            Expanded(
              child: filteredEntries.isEmpty
                  ? const _EmptyState()
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        if (thisWeek.isNotEmpty)
                          _WeekSection(
                            title: "This Week",
                            entries: thisWeek,
                            confirmDelete: _confirmDelete,
                            box: box,
                            visibleEntries: visibleEntries,
                            onUpdate: () => setState(() {}),
                          ),
                        if (lastWeek.isNotEmpty)
                          _WeekSection(
                            title: "Last Week",
                            entries: lastWeek,
                            confirmDelete: _confirmDelete,
                            box: box,
                            visibleEntries: visibleEntries,
                            onUpdate: () => setState(() {}),
                          ),
                        if (older.isNotEmpty)
                          _WeekSection(
                            title: "Older",
                            entries: older,
                            confirmDelete: _confirmDelete,
                            box: box,
                            visibleEntries: visibleEntries,
                            onUpdate: () => setState(() {}),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickStat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withAlpha((255 * 0.2).round()),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String key, String label, IconData icon) {
    final isActive = filterActivity == key;
    return GestureDetector(
      onTap: () => setState(() => filterActivity = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isActive ? AppColors.primary : AppColors.surfaceCard,
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : Colors.white.withAlpha((255 * 0.06).round()),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive ? Colors.white : AppColors.textMuted,
                size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textMuted,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }
}

class _WeekSection extends StatelessWidget {
  final String title;
  final List<MapEntry<dynamic, dynamic>> entries;
  final Future<bool> Function() confirmDelete;
  final Box box;
  final List<MapEntry<dynamic, dynamic>> visibleEntries;
  final VoidCallback onUpdate;

  const _WeekSection({
    required this.title,
    required this.entries,
    required this.confirmDelete,
    required this.box,
    required this.visibleEntries,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...entries.map((entry) {
          final session = TravelSession.fromMap(entry.value);
          final key = entry.key;
          final globalIndex = visibleEntries.indexWhere((e) => e.key == key);

          return Dismissible(
            key: ValueKey(key),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async => await confirmDelete(),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withAlpha((255 * 0.2).round()),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.delete_rounded, color: AppColors.accentRed),
            ),
            onDismissed: (_) {
              final deleted = Map.from(entry.value);
              visibleEntries.removeAt(globalIndex);
              box.delete(key);
              onUpdate();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Trip deleted"),
                  action: SnackBarAction(
                    label: "UNDO",
                    textColor: AppColors.accent,
                    onPressed: () {
                      box.put(key, deleted);
                      visibleEntries.insert(
                        globalIndex,
                        MapEntry(key, deleted),
                      );
                      onUpdate();
                    },
                  ),
                ),
              );
            },
            child: _HistoryCard(
              session: session,
              onDelete: () async {
                final ok = await confirmDelete();
                if (!ok) return;

                final deleted = Map.from(entry.value);
                visibleEntries.removeAt(globalIndex);
                box.delete(key);
                onUpdate();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Trip deleted"),
                      action: SnackBarAction(
                        label: "UNDO",
                        textColor: AppColors.accent,
                        onPressed: () {
                          box.put(key, deleted);
                          visibleEntries.insert(
                            globalIndex,
                            MapEntry(key, deleted),
                          );
                          onUpdate();
                        },
                      ),
                    ),
                  );
                }
              },
            ),
          );
        }),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final TravelSession session;
  final VoidCallback onDelete;

  const _HistoryCard({required this.session, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');

    IconData activityIcon;
    Color activityColor;
    switch (session.activityType) {
      case 'run':
        activityIcon = Icons.directions_run;
        activityColor = AppColors.accentOrange;
        break;
      case 'cycle':
        activityIcon = Icons.pedal_bike;
        activityColor = AppColors.accentGreen;
        break;
      case 'drive':
        activityIcon = Icons.directions_car;
        activityColor = AppColors.accent;
        break;
      default:
        activityIcon = Icons.directions_walk;
        activityColor = AppColors.primary;
    }

    return GradientGlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: activityColor.withAlpha((255 * 0.15).round()),
                ),
                child: Icon(activityIcon, color: activityColor, size: 24),
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
                        fontSize: 18,
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
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: AppColors.accentRed, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _miniStat(Icons.timer_rounded, session.formattedDuration, AppColors.accent),
              _miniStat(
                Icons.speed_rounded,
                '${(session.avgSpeed * 3.6).toStringAsFixed(1)} km/h',
                AppColors.accentOrange,
              ),
              _miniStat(
                Icons.local_fire_department_rounded,
                '${session.calories.toStringAsFixed(0)} kcal',
                AppColors.accentRed,
              ),
              _miniStat(
                Icons.access_time_rounded,
                '${timeFormat.format(session.startTime)} → ${timeFormat.format(session.endTime)}',
                AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String text, Color color) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.explore_off_rounded,
              size: 40,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No travel history yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking to build your history',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
