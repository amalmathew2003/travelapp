import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:travalapp/screen/splach_screen.dart';
import 'package:travalapp/theme/app_theme.dart';
import 'package:travalapp/service/background_location_service.dart' as bg;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Open boxes before UI
  await Hive.openBox('travel_sessions');
  await Hive.openBox('archived_travel_sessions');
  final settingsBox = await Hive.openBox('user_settings');

  // Set initial theme mode
  final isDarkMode = settingsBox.get('isDarkMode', defaultValue: true);
  AppColors.setMode(isDarkMode ? AppThemeMode.dark : AppThemeMode.light);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: AppColors.isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: AppColors.isDark ? Brightness.light : Brightness.dark,
    ),
  );

  // Initialize background service (not started auto, just config)
  await bg.initializeService();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('user_settings').listenable(keys: ['isDarkMode']),
      builder: (context, box, widget) {
        final isDarkMode = box.get('isDarkMode', defaultValue: true);
        AppColors.setMode(isDarkMode ? AppThemeMode.dark : AppThemeMode.light);

        return MaterialApp(
          title: 'Travel Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}
