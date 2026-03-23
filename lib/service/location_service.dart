import 'package:geolocator/geolocator.dart';

class LocationService {
  /// 🔐 Permission handling with background support
  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    // For background work on Android 10+, special request is often needed
    // However, for most foreground-service use cases, Fine Location is enough
    // as long as the service is started while in foreground.
    
    return true;
  }

  /// 📍 Optimized live location stream
  static Stream<Position> getLiveLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5, // Ignore jitter
      ),
    );
  }
}
