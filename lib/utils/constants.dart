class AppConstants {
  // Achievement milestones in meters
  static const List<double> achievementMilestones = [
    500, // 500m
    1000, // 1 km
    2000, // 2 km
    5000, // 5 km
    10000, // 10 km
    21097, // Half Marathon
    42195, // Full Marathon
    50000, // 50 km Ultra
    100000, // 100 km
  ];

  // Activity types
  static const List<Map<String, dynamic>> activityTypes = [
    {'key': 'walk', 'label': 'Walk', 'icon': 'directions_walk'},
    {'key': 'run', 'label': 'Run', 'icon': 'directions_run'},
    {'key': 'cycle', 'label': 'Cycle', 'icon': 'pedal_bike'},
    {'key': 'drive', 'label': 'Drive', 'icon': 'directions_car'},
  ];

  /// Badge titles for each milestone.
  /// Key is distance in meters as String to avoid const-map double key issues.
  static final Map<double, Map<String, String>> achievementBadges = {
    500: {'title': 'First Steps', 'emoji': '👶'},
    1000: {'title': '1K Explorer', 'emoji': '🚶'},
    2000: {'title': '2K Wanderer', 'emoji': '🧭'},
    5000: {'title': '5K Adventurer', 'emoji': '🏃'},
    10000: {'title': '10K Champion', 'emoji': '🥇'},
    21097: {'title': 'Half Marathon Hero', 'emoji': '🏅'},
    42195: {'title': 'Marathoner', 'emoji': '🏆'},
    50000: {'title': 'Ultra Runner', 'emoji': '⚡'},
    100000: {'title': 'Century Legend', 'emoji': '👑'},
  };
}
