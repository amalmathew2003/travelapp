import 'dart:async';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // Create notification channel for Android 8+
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'travel_tracker_channel', // id
    'Travel Tracker Service', // title
    description: 'This channel is used for tracking your journey in the background.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'travel_tracker_channel',
      initialNotificationTitle: 'Travel Tracker Running',
      initialNotificationContent: 'Ready to track your journey.',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  try {
    bool backgroundServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!backgroundServiceEnabled) return;

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      service.invoke(
        'location_update',
        {
          'lat': position.latitude,
          'lng': position.longitude,
          'speed': position.speed,
          'alt': position.altitude,
          'time': DateTime.now().toIso8601String(),
        },
      );

      if (service is AndroidServiceInstance) {
        // Update notification
        flutterLocalNotificationsPlugin.show(
          id: 888,
          title: 'Live Tracking',
          body: 'Speed: ${(position.speed * 3.6).toStringAsFixed(1)} km/h',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'travel_tracker_channel',
              'Travel Tracker Service',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );
      }
    }, onError: (e) {
      debugPrint("Background location error: $e");
    });
  } catch (e) {
    debugPrint("Background location failed to start: $e");
  }
}
