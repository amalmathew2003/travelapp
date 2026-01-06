import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:travalapp/model/traval_session.dart';
import 'package:travalapp/screen/distance_chart.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Box box;
  late List<MapEntry<dynamic, dynamic>> visibleEntries;

  @override
  void initState() {
    super.initState();
    box = Hive.box('travel_sessions');
    visibleEntries = box.toMap().entries.toList().reversed.toList();
  }

  // ---------------- WEEK HELPERS ----------------
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

  // ---------------- CONFIRM DELETE ----------------
  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Delete history?"),
            content: const Text(
              "This action cannot be undone unless you use Undo.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ---------------- CLEAR ALL ----------------
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
            onPressed: () {
              box.clear();
              setState(() {
                visibleEntries.clear();
              });
              Navigator.pop(context);
            },
            child: const Text("Clear"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = visibleEntries;

    final thisWeek = <MapEntry<dynamic, dynamic>>[];
    final lastWeek = <MapEntry<dynamic, dynamic>>[];
    final older = <MapEntry<dynamic, dynamic>>[];

    for (final e in allEntries) {
      final session = TravalSession.fromMap(e.value);
      if (isSameWeek(session.startTime, DateTime.now())) {
        thisWeek.add(e);
      } else if (isLastWeek(session.startTime)) {
        lastWeek.add(e);
      } else {
        older.add(e);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Travel History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              final sessions = allEntries
                  .map((e) => TravalSession.fromMap(e.value))
                  .toList();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DistanceChartScreen(sessions: sessions),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'clear') _clearAllHistory();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear', child: Text("Clear all history")),
            ],
          ),
        ],
      ),
      body: allEntries.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
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
              ],
            ),
    );
  }
}

/// ---------------- WEEK SECTION ----------------
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
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        ...entries.asMap().entries.map((mapEntry) {
          final entry = mapEntry.value;
          final session = TravalSession.fromMap(entry.value);
          final key = entry.key;

          final globalIndex = visibleEntries.indexWhere((e) => e.key == key);

          return Dismissible(
            key: ValueKey(key),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async => await confirmDelete(),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              final deleted = Map.from(entry.value);

              visibleEntries.removeAt(globalIndex);
              box.delete(key);
              onUpdate();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("History deleted"),
                  action: SnackBarAction(
                    label: "UNDO",
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

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("History deleted"),
                    action: SnackBarAction(
                      label: "UNDO",
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
            ),
          );
        }),

        const SizedBox(height: 24),
      ],
    );
  }
}

/// ---------------- HISTORY CARD ----------------
class _HistoryCard extends StatelessWidget {
  final TravalSession session;
  final VoidCallback onDelete;

  const _HistoryCard({required this.session, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.route, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${(session.distance / 1000).toStringAsFixed(2)} km",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateFormat.format(session.startTime),
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  "${timeFormat.format(session.startTime)} → ${timeFormat.format(session.endTime)}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// ---------------- EMPTY STATE ----------------
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No travel history yet",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
