import 'dart:async' show Timer;

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

void backgroundServiceStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: "Travel Tracker",
      content: "Tracking distance in background",
    );
  }

  Timer.periodic(const Duration(seconds: 5), (timer) async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    service.invoke(
      'location_update',
      {
        'lat': position.latitude,
        'lng': position.longitude,
      },
    );
  });

  // ✅ Stop listener
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}
