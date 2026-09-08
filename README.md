<div align="center">

# 🗺️ TRAVEL TRACKER

### ⚡ Every step, ride, and mile — tracked, mapped, celebrated. ⚡

[![Flutter](https://img.shields.io/badge/Flutter-Cross--Platform-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Hive](https://img.shields.io/badge/Database-Hive-FFCF00?style=for-the-badge&logo=databricks&logoColor=black)](#)
[![Maps](https://img.shields.io/badge/Maps-OpenStreetMap-7EBC6F?style=for-the-badge&logo=openstreetmap&logoColor=white)](#)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84?style=for-the-badge&logo=android&logoColor=white)](#)

**A real-time fitness & travel tracking app for Walking, Running, Cycling, and Driving — with live GPS maps, calorie estimates, and gamified achievements.**

### 📥 [**Download APK**](https://github.com/amalmathew2003/travelapp/releases/latest)

[![Download](https://img.shields.io/badge/Download-APK-success?style=for-the-badge&logo=android&logoColor=white)](https://github.com/amalmathew2003/travelapp/releases/latest)
[![Latest Release](https://img.shields.io/github/v/release/amalmathew2003/travelapp?style=for-the-badge&label=Latest&color=blue)](https://github.com/amalmathew2003/travelapp/releases/latest)

```
  📍 TRACK   ───▶   🗺️ MAP THE ROUTE   ───▶   📊 ANALYZE   ───▶   🏆 UNLOCK BADGES
```

</div>

<br>

## 🎯 What It Does

> Fitness apps shouldn't drain your battery or your data plan.

**Travel Tracker** records your distance, speed, time, and calorie burn in real time using GPS — with **lazy map tile rendering** that only loads map data when you're actually tracking, keeping battery and data usage low. Tracking keeps running seamlessly in the background, even with the screen off.

<br>

## ✨ Features

<table>
<tr>
<td width="50%">

### 📍 Real-Time Trip Tracking
Live distance, elapsed time, current/max speed, and estimated calorie burn — powered by `geolocator` GPS streaming.

</td>
<td width="50%">

### 🗺️ Lazy Map Rendering
Map tiles (OpenStreetMap / CartoDB / Esri via `flutter_map`) only load during active tracking or preview — saving battery and network data.

</td>
</tr>
<tr>
<td width="50%">

### 🌙 Background Location Service
A persistent foreground service (`flutter_background_service`) keeps recording your route even when the app is minimized or the screen is locked.

</td>
<td width="50%">

### 📊 Visual Analytics
Smooth, animated distance breakdowns and trends via interactive `fl_chart` graphs in the analytics tab.

</td>
</tr>
<tr>
<td width="50%">

### 🏆 Gamified Achievements
Unlock milestone badges (1km → 100km) with **confetti explosions** and celebratory sound effects.

</td>
<td width="50%">

### 📤 Data Export & Privacy
All trip history stays **on-device** in a local Hive database, with CSV/JSON export whenever you want your data out.

</td>
</tr>
</table>

<br>

## 🧱 Stack

<div align="center">

| Category | Package(s) |
|:---:|:---:|
| 📍 Location & GPS | `geolocator`, `flutter_background_service`, `flutter_background_service_android` |
| 🗺️ Maps | `flutter_map`, `latlong2` |
| 🗄️ Storage | `hive`, `hive_flutter`, `path_provider` |
| 📊 Charts & Gamification | `fl_chart`, `confetti`, `audioplayers` |
| 🔔 Notifications & Utils | `flutter_local_notifications`, `intl`, `cupertino_icons` |
| 🎨 Branding | `flutter_launcher_icons` |

**Map Providers:** OpenStreetMap · CartoDB · Esri

</div>

<br>

## 📂 Structure

```
travalapp/
├── assets/
│   ├── icon/app_logo.png              🎨 3D glossy gradient app icon
│   ├── splash/appsplach.gif           🌌 splash screen animation
│   └── sounds/                        🔊 achievement sound assets
├── lib/
│   ├── main.dart                      ⚡ entry point, Hive init, theme listener
│   ├── model/
│   │   └── traval_session.dart        📦 activity, distance, calories, GPS route model
│   ├── screen/
│   │   ├── home_screen.dart           🏠 dashboard & bottom nav
│   │   ├── map_screen.dart            📍 track screen — idle & live map view
│   │   ├── history_screen.dart        📜 trip logs, search/filter, CSV/JSON export
│   │   ├── achievements_screen.dart   🏆 badges, levels, confetti
│   │   ├── settings_screen.dart       ⚙️ theme, profile, tracking config
│   │   ├── distance_chart.dart        📊 interactive distance graphs
│   │   └── splach_screen.dart         🌌 animated splash intro
│   ├── service/
│   │   ├── background_location_service.dart  🔄 background GPS + notification daemon
│   │   └── location_service.dart              📍 permission request helper
│   ├── theme/
│   │   └── app_theme.dart             🌗 glassmorphism tokens, dark/light schemes
│   ├── utils/
│   │   ├── constants.dart             🏁 achievement milestones & defaults
│   │   └── distance_calculator.dart   🧮 Haversine distance & calorie math
│   └── widgets/
│       ├── glass_container.dart       🪟 glassmorphic blur cards
│       └── stat_card.dart             🎴 gradient metric cards
└── pubspec.yaml
```

<br>

## 🚀 Run It

### Option 1 — Install the APK directly
1. Go to [**Releases**](https://github.com/amalmathew2003/travelapp/releases/latest)
2. Download `app-release.apk`
3. Install it on your Android device (enable "Install from unknown sources" if prompted)

### Option 2 — Build from source
```bash
git clone https://github.com/amalmathew2003/travelapp.git
cd travelapp
flutter pub get
flutter run
```

<br>

## ⚙️ How It Works

**1. Startup** — Hive initializes three local boxes (`travel_sessions`, `archived_travel_sessions`, `user_settings`), then the animated splash screen transitions into the dashboard.

**2. Dashboard** — Aggregate stats (total distance, calories, trip count, streak days) plus recent trip cards, across a 5-tab bottom nav: *Dashboard · Track · History · Awards · Settings*.

**3. Tracking** — Idle state suspends map tiles to save resources. Tap **Start Tracking** → GPS permission is verified → a background service launches with a persistent notification → live polyline, distance, and calorie tracking begins.

**4. Stop & Save** — Tap **Stop Tracking** → the background service ends → the completed session is saved to Hive.

**5. History & Analytics** — Browse, search, export, or archive past trips; view distance trends in animated charts.

**6. Achievements** — Cumulative distance is checked against milestones (1, 5, 10, 25, 50, 100 km), triggering confetti + sound on unlock.

<br>

## 📍 Great For

| 🚶 Walking | 🏃 Running | 🚴 Cycling | 🚗 Driving |
|:---:|:---:|:---:|:---:|
| Casual distance tracking | Pace & calorie tracking | Route mapping | Trip logging |

<br>

---

<div align="center">

### 👤 Amal Mathew
**Flutter Developer** · Thrissur, Kerala

[![GitHub](https://img.shields.io/badge/GitHub-amalmathew2003-181717?style=for-the-badge&logo=github)](https://github.com/amalmathew2003)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/amal-mathew-1-)
[![Portfolio](https://img.shields.io/badge/Portfolio-Visit-000000?style=for-the-badge&logo=vercel&logoColor=white)](https://amalmathew2003.github.io/newportfolio/)

<sub>⭐ If you like this project, consider giving it a star!</sub>

</div>
