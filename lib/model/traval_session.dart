class TravelSession {
  final DateTime startTime;
  final DateTime endTime;
  final double distance; // in meters
  final double avgSpeed; // in m/s
  final double maxSpeed; // in m/s
  final double calories;
  final String activityType; // walk, run, cycle, drive
  final List<Map<String, double>> routePoints; // lat/lng pairs

  TravelSession({
    required this.startTime,
    required this.endTime,
    required this.distance,
    this.avgSpeed = 0.0,
    this.maxSpeed = 0.0,
    this.calories = 0.0,
    this.activityType = 'walk',
    this.routePoints = const [],
  });

  Duration get duration => endTime.difference(startTime);

  double get distanceKm => distance / 1000;

  String get formattedDuration {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  String get formattedPace {
    if (distance <= 0) return '--:--';
    final paceMinPerKm = (duration.inSeconds / 60) / distanceKm;
    final mins = paceMinPerKm.floor();
    final secs = ((paceMinPerKm - mins) * 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')} /km';
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'distance': distance,
      'avgSpeed': avgSpeed,
      'maxSpeed': maxSpeed,
      'calories': calories,
      'activityType': activityType,
      'routePoints': routePoints
          .map((p) => {'lat': p['lat'], 'lng': p['lng']})
          .toList(),
    };
  }

  factory TravelSession.fromMap(Map map) {
    final routeRaw = map['routePoints'];
    List<Map<String, double>> route = [];
    if (routeRaw is List) {
      route = routeRaw.map<Map<String, double>>((p) {
        return {
          'lat': (p['lat'] ?? 0.0).toDouble(),
          'lng': (p['lng'] ?? 0.0).toDouble(),
        };
      }).toList();
    }

    return TravelSession(
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      distance: (map['distance'] ?? 0.0).toDouble(),
      avgSpeed: (map['avgSpeed'] ?? 0.0).toDouble(),
      maxSpeed: (map['maxSpeed'] ?? 0.0).toDouble(),
      calories: (map['calories'] ?? 0.0).toDouble(),
      activityType: map['activityType'] ?? 'walk',
      routePoints: route,
    );
  }
}

/// Legacy backward‐compatible alias
typedef TravalSession = TravelSession;
