import 'package:geolocator/geolocator.dart';

class DistanceCalculators {
  static double calculate(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Calculate calories burned based on distance, activity type and duration.
  /// Returns approximate calories.
  static double estimateCalories({
    required double distanceMeters,
    required String activityType,
    required Duration duration,
    double weightKg = 70.0,
  }) {
    // MET values for different activities
    double met;
    switch (activityType) {
      case 'run':
        met = 9.8;
        break;
      case 'cycle':
        met = 7.5;
        break;
      case 'drive':
        met = 1.5;
        break;
      case 'walk':
      default:
        met = 3.8;
        break;
    }

    final hours = duration.inSeconds / 3600.0;
    return met * weightKg * hours;
  }
}
