class TravalSession {
  final DateTime startTime;
  final DateTime endTime;
  final double distance;

  TravalSession({
    required this.startTime,
    required this.endTime,
    required this.distance,
  });

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'distance': distance, // always save
    };
  }

  factory TravalSession.fromMap(Map map) {
    return TravalSession(
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      distance: (map['distance'] ?? 0.0).toDouble(), 
    );
  }
}
