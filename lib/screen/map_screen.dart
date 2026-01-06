import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:travalapp/model/traval_session.dart';
import 'package:travalapp/screen/history_screen.dart';
import 'package:travalapp/service/location_service.dart';
import '../utils/distance_calculator.dart';

// 🏆 ACHIEVEMENT PACKAGES
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

enum MapMode { normal, satellite, hybrid, dark }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? currentLatLng;
  LatLng? previousLatLng;

  bool isTracking = false;
  double totalDistance = 0.0;
  final List<LatLng> routePoints = [];

  DateTime? startTime;
  MapMode currentMode = MapMode.normal;

  // 🏆 ACHIEVEMENTS
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 🎯 Milestones in meters
  final List<double> achievementMilestones = [
    500, // 500 m
    1000, // 1 km
    2000, // 2 km
  ];

  final Set<double> unlockedMilestones = {};

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ---------------- MAP TILES ----------------
  List<Widget> _buildTileLayers() {
    switch (currentMode) {
      case MapMode.satellite:
        return [
          TileLayer(
            urlTemplate:
                "https://server.arcgisonline.com/ArcGIS/rest/services/"
                "World_Imagery/MapServer/tile/{z}/{y}/{x}",
          ),
        ];

      case MapMode.hybrid:
        return [
          TileLayer(
            urlTemplate:
                "https://server.arcgisonline.com/ArcGIS/rest/services/"
                "World_Imagery/MapServer/tile/{z}/{y}/{x}",
          ),
          TileLayer(
            urlTemplate:
                "https://server.arcgisonline.com/ArcGIS/rest/services/"
                "Reference/World_Transportation/MapServer/tile/{z}/{y}/{x}",
          ),
        ];

      case MapMode.dark:
        return [
          TileLayer(
            urlTemplate:
                "https://{s}.basemaps.cartocdn.com/dark_all/"
                "{z}/{x}/{y}{r}.png",
            subdomains: ['a', 'b', 'c'],
          ),
        ];

      default:
        return [
          TileLayer(
            urlTemplate:
                "https://server.arcgisonline.com/ArcGIS/rest/services/"
                "World_Street_Map/MapServer/tile/{z}/{y}/{x}",
          ),
        ];
    }
  }

  // ---------------- ACHIEVEMENT CHECK ----------------
  Future<void> _checkAchievements() async {
    for (final milestone in achievementMilestones) {
      if (totalDistance >= milestone &&
          !unlockedMilestones.contains(milestone)) {
        unlockedMilestones.add(milestone);

        _confettiController.play();

        await _audioPlayer.play(AssetSource('sounds/achievement.mp3'));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              "🏆 Achievement unlocked: ${(milestone / 1000).toStringAsFixed(2)} km",
            ),
          ),
        );

        break; // play ONE at a time
      }
    }
  }

  // ---------------- TRACKING ----------------
  Future<void> startTracking() async {
    final ok = await LocationService.requestPermission();
    if (!ok) return;

    setState(() {
      isTracking = true;
      totalDistance = 0;
      routePoints.clear();
      startTime = DateTime.now();
      previousLatLng = null;
      unlockedMilestones.clear(); // 🔁 RESET
    });

    LocationService.getLiveLocation().listen((Position pos) {
      if (!isTracking) return;

      final newPoint = LatLng(pos.latitude, pos.longitude);

      if (previousLatLng != null) {
        final jitter = DistanceCalculators.calculate(
          previousLatLng!.latitude,
          previousLatLng!.longitude,
          newPoint.latitude,
          newPoint.longitude,
        );
        if (jitter < 5) return;
      }

      setState(() {
        currentLatLng = newPoint;

        if (previousLatLng != null) {
          totalDistance += DistanceCalculators.calculate(
            previousLatLng!.latitude,
            previousLatLng!.longitude,
            newPoint.latitude,
            newPoint.longitude,
          );
        }

        previousLatLng = newPoint;
        routePoints.add(newPoint);
      });

      _checkAchievements(); // 🏆 MULTI-LEVEL CHECK
    });
  }
Future<void> stopTracking() async {
  setState(() => isTracking = false);

  // 🛑 STOP BACKGROUND SERVICE HERE
  FlutterBackgroundService().invoke('stopService');

  if (startTime == null) return;

  final session = TravalSession(
    startTime: startTime!,
    endTime: DateTime.now(),
    distance: totalDistance,
  );

  Hive.box('travel_sessions').add(session.toMap());
}


  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Travel Tracker",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          PopupMenuButton<MapMode>(
            icon: const Icon(Icons.layers, color: Colors.black),
            onSelected: (mode) => setState(() => currentMode = mode),
            itemBuilder: (_) => const [
              PopupMenuItem(value: MapMode.normal, child: Text("Normal")),
              PopupMenuItem(value: MapMode.satellite, child: Text("Satellite")),
              PopupMenuItem(value: MapMode.hybrid, child: Text("Hybrid")),
              PopupMenuItem(value: MapMode.dark, child: Text("Dark")),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.music_note, color: Colors.black),
          //   onPressed: () async {
          //     await _audioPlayer.play(AssetSource('sounds/achievement.mp3'));
          //   },
          // ),
        ],
      ),
      body: currentLatLng == null
          ? const Center(
              child: Text(
                "Press START to begin",
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: currentLatLng!,
                    initialZoom: 16,
                    minZoom: 3,
                    maxZoom: 18,
                  ),
                  children: [
                    ..._buildTileLayers(),

                    if (routePoints.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            strokeWidth: 4,
                            color: Colors.blueAccent,
                          ),
                        ],
                      ),

                    MarkerLayer(
                      markers: [
                        Marker(
                          point: currentLatLng!,
                          width: 60,
                          height: 80,
                          child: Column(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.45),
                                      blurRadius: 10,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.man_2_sharp,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // 🎉 CONFETTI
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.orange,
                      Colors.purple,
                      Colors.red,
                    ],
                  ),
                ),

                Positioned(
                  top: 20,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Distance Traveled",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${(totalDistance / 1000).toStringAsFixed(2)} km",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isTracking ? Colors.red : Colors.green,
        onPressed: isTracking ? stopTracking : startTracking,
        icon: Icon(isTracking ? Icons.stop : Icons.play_arrow),
        label: Text(isTracking ? "STOP" : "START"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
