import 'package:geolocator/geolocator.dart';

class DistanceCalculators {
  static double calculate(double lat1, double lon1, double lat2, double lot2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lot2);
  }
}
