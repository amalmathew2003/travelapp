import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:travalapp/model/traval_session.dart';
import 'package:travalapp/service/location_service.dart';
import 'package:travalapp/theme/app_theme.dart';
import 'package:travalapp/utils/constants.dart';
import '../utils/distance_calculator.dart';

import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

enum MapMode { normal, satellite, hybrid, dark }

class MapScreen extends StatefulWidget {
  final ValueChanged<bool>? onFullScreenToggle;
  const MapScreen({super.key, this.onFullScreenToggle});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  LatLng? currentLatLng;
  LatLng? previousLatLng;

  bool isTracking = false;
  bool isMapReady = false;
  bool isFullScreen = false;
  double totalDistance = 0.0;
  final List<LatLng> routePoints = [];

  DateTime? startTime;
  MapMode currentMode = MapMode.dark;
  String selectedActivity = 'walk';

  // Live stats
  double currentSpeed = 0.0; // m/s
  double maxSpeed = 0.0;
  double calories = 0.0;
  Timer? _timerUpdater;
  Duration elapsed = Duration.zero;

  // Stream subscriptions
  StreamSubscription? _serviceLocSub;

  // Achievements
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<double> unlockedMilestones = {};

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _listenToBackgroundService();
    _checkInitialLocation();
  }

  Future<void> _checkInitialLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          currentLatLng = LatLng(pos.latitude, pos.longitude);
        });
        _centerOnLocation();
      }
    } catch (_) {}
  }

  Future<void> _centerOnLocation() async {
    if (isMapReady) {
      if (currentLatLng != null) {
        _mapController.move(currentLatLng!, _mapController.camera.zoom);
      } else {
        // Try getting it again if null
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          if (mounted) {
            setState(() {
              currentLatLng = LatLng(pos.latitude, pos.longitude);
            });
            _mapController.move(currentLatLng!, _mapController.camera.zoom);
          }
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _serviceLocSub?.cancel();
    _confettiController.dispose();
    _audioPlayer.dispose();
    _pulseController.dispose();
    _timerUpdater?.cancel();
    super.dispose();
  }

  void _listenToBackgroundService() {
    _serviceLocSub = FlutterBackgroundService().on('location_update').listen((data) {
      if (!isTracking || data == null || !mounted) return;

      final double lat = data['lat'];
      final double lng = data['lng'];
      final double speed = data['speed'] ?? 0.0;
      final newPoint = LatLng(lat, lng);

      if (previousLatLng != null) {
        final dist = DistanceCalculators.calculate(
          previousLatLng!.latitude,
          previousLatLng!.longitude,
          newPoint.latitude,
          newPoint.longitude,
        );
        if (dist < 3) return; // Jitter filter
        
        setState(() {
          totalDistance += dist;
          currentLatLng = newPoint;
          currentSpeed = speed;
          if (speed > maxSpeed) maxSpeed = speed;
          routePoints.add(newPoint);

          if (startTime != null) {
            calories = DistanceCalculators.estimateCalories(
              distanceMeters: totalDistance,
              activityType: selectedActivity,
              duration: DateTime.now().difference(startTime!),
            );
          }
        });

        previousLatLng = newPoint;
        if (isMapReady && mounted) {
          try {
            _mapController.move(newPoint, _mapController.camera.zoom);
          } catch (_) {}
        }
        _checkAchievements();
      } else {
        setState(() {
          currentLatLng = newPoint;
          previousLatLng = newPoint;
          routePoints.add(newPoint);
        });
      }
    });
  }

  // Achievement Check helper ... 
  Future<void> _checkAchievements() async {
    for (final milestone in AppConstants.achievementMilestones) {
      if (totalDistance >= milestone && !unlockedMilestones.contains(milestone)) {
        unlockedMilestones.add(milestone);
        _confettiController.play();
        try { await _audioPlayer.play(AssetSource('sounds/achievement.mp3')); } catch (_) {}
      }
    }
  }

  Future<void> startTracking() async {
    final ok = await LocationService.requestPermission();
    if (!ok) return;

    final service = FlutterBackgroundService();
    try {
      if (!(await service.isRunning())) {
        await service.startService();
      }
    } catch (_) {}

    setState(() {
      isTracking = true;
      totalDistance = 0;
      routePoints.clear();
      startTime = DateTime.now();
      previousLatLng = null;
      unlockedMilestones.clear();
      currentSpeed = 0;
      maxSpeed = 0;
      calories = 0;
      elapsed = Duration.zero;
    });

    _timerUpdater = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isTracking && mounted) {
        setState(() => elapsed = DateTime.now().difference(startTime!));
      }
    });
  }

  Future<void> stopTracking() async {
    _timerUpdater?.cancel();
    setState(() => isTracking = false);

    FlutterBackgroundService().invoke('stopService');

    if (startTime == null) return;
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime!);
    final avgSpeed = duration.inSeconds > 0 ? totalDistance / duration.inSeconds : 0.0;

    final session = TravelSession(
      startTime: startTime!,
      endTime: endTime,
      distance: totalDistance,
      avgSpeed: avgSpeed,
      maxSpeed: maxSpeed,
      calories: calories,
      activityType: selectedActivity,
      routePoints: routePoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    );

    await Hive.box('travel_sessions').add(session.toMap());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip saved! ${(totalDistance / 1000).toStringAsFixed(2)} km')),
      );
    }
  }

  List<Widget> _buildTileLayers() {
    switch (currentMode) {
      case MapMode.satellite: return [TileLayer(urlTemplate: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}")];
      case MapMode.hybrid: return [TileLayer(urlTemplate: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"), TileLayer(urlTemplate: "https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Transportation/MapServer/tile/{z}/{y}/{x}")];
      case MapMode.dark: return [TileLayer(urlTemplate: "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png", subdomains: const ['a', 'b', 'c'])];
      default: return [TileLayer(urlTemplate: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}")];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (!isFullScreen)
              Header(
                onActivityChanged: (val) => setState(() => selectedActivity = val),
                selectedActivity: selectedActivity,
                onModeChanged: (val) => setState(() => currentMode = val),
                isTracking: isTracking,
              ),
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(isFullScreen ? 0 : 24)),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: currentLatLng ?? const LatLng(0, 0),
                        initialZoom: 16,
                        onMapReady: () => setState(() => isMapReady = true),
                      ),
                      children: [
                        ..._buildTileLayers(),
                        if (routePoints.length > 1) PolylineLayer(polylines: [Polyline(points: routePoints, strokeWidth: 5, color: AppColors.primary)]),
                        if (currentLatLng != null) MarkerLayer(markers: [
                          Marker(
                            point: currentLatLng!,
                            width: 40,
                            height: 40,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (_, child) => Transform.scale(scale: isTracking ? _pulseAnimation.value : 1.0, child: child),
                              child: Container(
                                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary, border: const Border.fromBorderSide(BorderSide(color: Colors.white, width: 3))),
                                child: const Icon(Icons.my_location, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  Align(alignment: Alignment.topCenter, child: ConfettiWidget(confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive)),
                  
                  // Map Controls (Fullscreen + Center)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'fullscreen_btn',
                          backgroundColor: isFullScreen
                              ? AppColors.surfaceCard.withAlpha((255 * 0.8).round())
                              : AppColors.surfaceCard,
                          onPressed: () {
                            setState(() {
                              isFullScreen = !isFullScreen;
                            });
                            if (widget.onFullScreenToggle != null) {
                              widget.onFullScreenToggle!(isFullScreen);
                            }
                          },
                          child: Icon(
                            isFullScreen
                                ? Icons.fullscreen_exit_rounded
                                : Icons.fullscreen_rounded,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'center_btn',
                          backgroundColor: AppColors.surfaceCard,
                          onPressed: _centerOnLocation,
                          child: Icon(
                            Icons.my_location_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!isFullScreen)
              BottomPanel(
                isTracking: isTracking,
                totalDistance: totalDistance,
                elapsed: elapsed,
                currentSpeed: currentSpeed,
                calories: calories,
                onToggle: () => isTracking ? stopTracking() : startTracking(),
              ),
          ],
        ),
      ),
    );
  }
}

// ───── HELPER WIDGETS ────────────────────────────────────────────────────────
class Header extends StatelessWidget {
  final String selectedActivity;
  final ValueChanged<String> onActivityChanged;
  final ValueChanged<MapMode> onModeChanged;
  final bool isTracking;

  const Header({super.key, required this.selectedActivity, required this.onActivityChanged, required this.onModeChanged, required this.isTracking});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text('Track', style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1))),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                _activityIcon('walk', Icons.directions_walk),
                _activityIcon('run', Icons.directions_run),
                _activityIcon('cycle', Icons.pedal_bike),
                _activityIcon('drive', Icons.directions_car),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<MapMode>(
            icon: Icon(Icons.layers_rounded, color: AppColors.textSecondary),
            onSelected: onModeChanged,
            itemBuilder: (_) => [
              const PopupMenuItem(value: MapMode.normal, child: Text("Normal")),
              const PopupMenuItem(value: MapMode.satellite, child: Text("Satellite")),
              const PopupMenuItem(value: MapMode.hybrid, child: Text("Hybrid")),
              const PopupMenuItem(value: MapMode.dark, child: Text("Dark")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityIcon(String key, IconData icon) {
    final isActive = selectedActivity == key;
    return GestureDetector(
      onTap: isTracking ? null : () => onActivityChanged(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: isActive ? AppColors.primary : Colors.transparent),
        child: Icon(icon, color: isActive ? Colors.white : AppColors.textMuted, size: 18),
      ),
    );
  }
}

class BottomPanel extends StatelessWidget {
  final bool isTracking;
  final double totalDistance;
  final Duration elapsed;
  final double currentSpeed;
  final double calories;
  final VoidCallback onToggle;

  const BottomPanel({super.key, required this.isTracking, required this.totalDistance, required this.elapsed, required this.currentSpeed, required this.calories, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        children: [
          Row(
            children: [
              _stat(Icons.straighten_rounded, (totalDistance / 1000).toStringAsFixed(2), 'km', AppColors.primary),
              _stat(Icons.timer_rounded, _formatElapsed(), 'time', AppColors.accent),
              _stat(Icons.speed_rounded, (currentSpeed * 3.6).toStringAsFixed(1), 'km/h', AppColors.accentOrange),
              _stat(Icons.local_fire_department_rounded, calories.toStringAsFixed(0), 'kcal', AppColors.accentRed),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onToggle,
              style: ElevatedButton.styleFrom(
                backgroundColor: isTracking ? AppColors.accentRed : AppColors.accentGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(isTracking ? 'STOP TRACKING' : 'START TRACKING', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String unit, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(unit, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  String _formatElapsed() {
    final m = elapsed.inMinutes.remainder(60);
    final s = elapsed.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
